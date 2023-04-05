/// @description navmesh_create()
function navmesh_create() {
	/*
		Create an empty navmesh
	
		Script created by TheSnidr, 2019
	*/
	var navMesh = array_create(eNavMesh.Num);
	navMesh[eNavMesh.NodeList] = ds_list_create();
	navMesh[eNavMesh.QuadGrid] = ds_grid_create(5, 0);
	navMesh[eNavMesh.SpatialHash] = ds_map_create();

	return navMesh;
}