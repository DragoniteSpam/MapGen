/// @description navmesh_connect_nearby_nodes(navMesh, maxDist)
/// @param navMesh
/// @param maxDist
function navmesh__connect_nearby_nodes(navMesh, maxDist) {
	/*
		Conects nodes that are close to each other.
		This script is slow and should preferably not be used at runtime.
	
		Script created by TheSnidr, 2019
	*/
	var nodeList = navMesh[eNavMesh.NodeList];
	var num = ds_list_size(nodeList);

	//Loop through all nodes of the navmesh
	var node1, node2, dist;
	for (var i = 0; i < num; i ++)
	{
		node1 = nodeList[| i];
	
		for (var j = i+1; j < num; j ++)
		{
			node2 = nodeList[| j];
			dist = point_distance_3d(node1[0], node1[1], node1[2], node2[0], node2[1], node2[2]);
			if dist <= maxDist
			{
				navmesh__node_add_neighbour(node1, node2);
			}
		}
	}
}