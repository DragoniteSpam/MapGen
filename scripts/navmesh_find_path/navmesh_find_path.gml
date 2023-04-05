/// @description navmesh_find_path(navMesh, x0, y0, z0, x1, y1, z1, exact)
/// @param navMesh
/// @param x0
/// @param y0
/// @param z0
/// @param x1
/// @param y1
/// @param z1
/// @param exact
function navmesh_find_path(navMesh, x0, y0, z0, x1, y1, z1, exact) {
	/*
		An implementation of the A* algorithm
		Returns an array containing the 3D positions of all the pathpoints, including the start and end positions.
	
		The start and end positions will be clamped to their respective nearest triangles.
		This assumes that the player can move in a straight line from the starting point to the first node, 
		as well as in a straight line from the final node to the destination.
	
		Returns: Array if successful, -1 if not
	
		Script created by TheSnidr
		www.TheSnidr.com
	*/
	var startTime = get_timer();
	var nodeList = navMesh[eNavMesh.NodeList];

	//////////////////////////////////////////////////////////////////////////////////////////////
	//Clear necessary data structures
	ds_priority_clear(global.NavMeshOpenSet);
	ds_map_clear(global.NavMeshClosedSet);

	//////////////////////////////////////////////////////////////////////////////////////////////
	//Find starting and destination quads.
	var startQuad	= navmesh__find_nearest_quad(navMesh, x0, y0, z0);
	var endQuad		= navmesh__find_nearest_quad(navMesh, x1, y1, z1);
	if (!is_array(startQuad) || !is_array(endQuad))
	{
		show_debug_message("navmesh_find_path: Could not find start or end point. Returning -1.");
		return -1;
	}

	//////////////////////////////////////////////////////////////////////////////////////////////
	//Clamp the start and end coordinates to their respective triangles
	x0 = startQuad[4];
	y0 = startQuad[5];
	z0 = startQuad[6];
	x1 = endQuad[4];
	y1 = endQuad[5];
	z1 = endQuad[6];

	//////////////////////////////////////////////////////////////////////////////////////////////
	//Check if the start and end triangles contain the same corner points. If they do, we can move in a straight line from start to finish.
	var i, j;
	for (i = 0; i < 4; i ++){
		for (j = 0; j < 4; j ++){
			if (startQuad[i] == endQuad[j]){break;} //Check if this node exists in both the start and end point
		}
		if (j == 4){break;} //If the node does not exist in both sets, break the loop early
	}
	if (i == 4){
		show_debug_message("navmesh_find_path: Start and end points are in the same convex shape (triangle or quad), and we can move in a straight line.");
		return [x0, y0, z0, x1, y1, z1];}

	//////////////////////////////////////////////////////////////////////////////////////////////
	//Add the gscore and fscore of the nodes in the starting quad
	var node, fScore;
	var heuristic = 0;
	for (i = 0; i < 4; i++)
	{
		node = startQuad[i];
		node[@ eNavNode.CameFrom] = undefined;
		node[@ eNavNode.Gscore] = point_distance_3d(node[0], node[1], node[2], x0, y0, z0);
        // micro-optimization by drago
		//heuristic = sqr(x1 - node[0]) + sqr(y1 - node[1]) + sqr(z1 - node[2]);
		//fScore = (exact ? sqrt(heuristic) : heuristic);
        fScore = exact
            ? point_distance_3d(x1 - node[0], y1 - node[1], z1 - node[2], 0, 0, 0)
            : (sqr(x1 - node[0]) + sqr(y1 - node[1]) + sqr(z1 - node[2]));
		ds_priority_add(global.NavMeshOpenSet, node[eNavNode.ID], fScore);
	}

	//////////////////////////////////////////////////////////////////////////////////////////////
	//Start looping through all reachable points
	var current, nbArray, dtArray, nbNum, gscore, tent_gscore, not_in_open_set, ID, nbID;
	while (!ds_priority_empty(global.NavMeshOpenSet))
	{
		//Find the node in the open set with the lowest f-score value
		ID = ds_priority_delete_min(global.NavMeshOpenSet);
		current = nodeList[| ID];
		if (current == endQuad[0] || current == endQuad[1] || current == endQuad[2] || current == endQuad[3]){break;}
		global.NavMeshClosedSet[? ID] = true;
	
		//Loop through the neighbours of the node
		gscore  = current[eNavNode.Gscore];
		nbArray = current[eNavNode.NbArray];
		dtArray = current[eNavNode.DtArray];
		nbNum = array_length(nbArray);
		for (i = 0; i < nbNum; i ++)
		{
			node = nbArray[i];
			nbID = node[eNavNode.ID];
		
			//Continue the loop if the node is in the closed set
			if !is_undefined(global.NavMeshClosedSet[? nbID]){continue;}
		
			//Check whether or not this is a better path
			tent_gscore = gscore + dtArray[i];
			not_in_open_set = is_undefined(ds_priority_find_priority(global.NavMeshOpenSet, nbID));
			if !not_in_open_set and tent_gscore >= node[eNavNode.Gscore]{continue;} //This is not a better path
		
			//This path is the best until now. Record it!
			node[@ eNavNode.CameFrom] = current;
			node[@ eNavNode.Gscore] = tent_gscore;
            // micro-optimization by drago
			//heuristic = sqr(x1 - node[0]) + sqr(y1 - node[1]) + sqr(z1 - node[2]);
			//fScore = tent_gscore + (exact ? sqrt(heuristic) : heuristic);
            fScore = tent_gscore + (exact
                ? point_distance_3d(x1 - node[0], y1 - node[1], z1 - node[2], 0, 0, 0)
                : (sqr(x1 - node[0]) + sqr(y1 - node[1]) + sqr(z1 - node[2])));
			if not_in_open_set
			{
				ds_priority_add(global.NavMeshOpenSet, nbID, fScore);
			}
			else
			{
				ds_priority_change_priority(global.NavMeshOpenSet, nbID, fScore);
			}
		}
	}

	//////////////////////////////////////////////////////////////////////////////////////////////
	//If the last node is not in the end triangle, we couldn't find any valid paths
	if (current != endQuad[0] && current != endQuad[1] && current != endQuad[2] && current != endQuad[3])
	{
		show_debug_message("navmesh_find_path: Could not find any valid paths, returning -1.");
		return -1;
	}

	//////////////////////////////////////////////////////////////////////////////////////////////
	//Read all the path points from the ds_map backwards
	var backwardspath = ds_list_create();
	while !is_undefined(current)
	{
		ds_list_add(backwardspath, current);
		current = current[eNavNode.CameFrom];
	}
	var num = ds_list_size(backwardspath);

	//////////////////////////////////////////////////////////////////////////////////////////////
	//Initialize the path point array
	var size = num * 3 + 6;
	var path = array_create(size, 0);
	path[0] = x0;
	path[1] = y0;
	path[2] = z0;
	for (var i = 0; i < num; i ++)
	{
		node = backwardspath[| num-i-1];
		path[i * 3 + 3] = node[0];
		path[i * 3 + 4] = node[1];
		path[i * 3 + 5] = node[2];
	}
	path[size - 3] = x1;
	path[size - 2] = y1;
	path[size - 1] = z1;

	//////////////////////////////////////////////////////////////////////////////////////////////
	//Clean up
	ds_list_destroy(backwardspath);

	//show_debug_message("navmesh_find_path: Found shortest path in " + string(get_timer() - startTime) + " microseconds.");
	return path;


}
