/// @description navmesh_add_node(navMesh, x, y, z)
/// @param navMesh
/// @param x
/// @param y
/// @param z
function navmesh__add_node(navMesh, px, py, pz) {
	/*
		Adds a node to the given navmesh
	
		Script created by TheSnidr, 2019
	*/
	var pointList = navMesh[eNavMesh.NodeList];

	var node = array_create(eNavNode.Num);
	node[eNavNode.X] = px;
	node[eNavNode.Y] = py;
	node[eNavNode.Z] = pz;
	node[eNavNode.ID] = ds_list_size(pointList);
	node[eNavNode.NbArray] = [];
	node[eNavNode.DtArray] = [];

	ds_list_add(pointList, node);

	return node;
}