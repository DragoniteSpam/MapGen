/// @description navmesh_identify_triangles(navMesh)
/// @param navMesh
function navmesh__identify_triangles(navMesh) {
	/*
		Identifies triangles in the navmesh.
		If you've imported a model buffer, this process has already been done automatically.
		This is a fairly slow script.
		It loops through the nodes of the grid and identifies triangles wherever it can find them.
	
		Script created by TheSnidr, 2019
	*/
	var nodeList = navMesh[eNavMesh.NodeList];
	var quadGrid = navMesh[eNavMesh.QuadGrid];
	var num = ds_list_size(nodeList);

	var tempQuadList = ds_list_create();

	//Loop through all nodes of the navmesh
	var closedSet = ds_map_create();
	var node, nbArray, nbNum, nb1, nbnbArray, nbnbNum, nb2, h
	for (var i = 0; i < num; i ++)
	{
		node = nodeList[| i];
		closedSet[? i] = true;
	
		nbArray = node[eNavNode.NbArray];
		nbNum = array_length(nbArray);
		for (var j = 0; j < nbNum; j ++)
		{
			//For each neighbour index, check all the other neighbour indices
			nb1 = nbArray[j];
			if !is_undefined(closedSet[? nb1[eNavNode.ID]]){continue;}
			nbnbArray = nb1[eNavNode.NbArray];
			nbnbNum = array_length(nbnbArray);
			for (var k = j+1; k < nbNum; k ++)
			{
				nb2 = nbArray[k];
				if !is_undefined(closedSet[? nb2[eNavNode.ID]]){continue;}
			
				//Now that we have two neighbour indices, we need to check each one of the neighbours and see if they also have the other as their neighbour
				for (var l = 0; l < nbnbNum; l ++)
				{
					if nbnbArray[l] == nb2{break;}
				}
				if l < nbnbNum
				{
					//This is a triangle, and we can write it to the quad grid
					h = ds_grid_height(quadGrid);
					ds_grid_resize(quadGrid, 5, h+1);
					//show_message("Identified tri " + string(i) + ", " + string(nb1[eNavNode.ID]) + ", " + string(nb2[eNavNode.ID]));
					ds_list_add(tempQuadList, node, nb1, nb2, nb2, [0, 0, 1]);
					quadGrid[# 0, h] = node;
					quadGrid[# 1, h] = nb1;
					quadGrid[# 2, h] = nb2;
					quadGrid[# 3, h] = nb2;
					quadGrid[# 4, h] = [0, 0, 1];
				}
			}
		}
	}

	num = ds_list_size(tempQuadList);
	ds_grid_resize(quadGrid, 5, num div 5);
	for (var i = 0; i < num; i ++)
	{
		quadGrid[# i mod 5, i div 5] = tempQuadList[| i];
	}


	ds_list_destroy(tempQuadList);
	ds_map_destroy(closedSet);
}