/// @description navmesh_destroy(navMesh)
/// @param navMesh
function navmesh_destroy(navMesh) {
	/*
		Destroys the given navmesh
	
		Script created by TheSnidr, 2019
	*/
	ds_list_destroy(navMesh[eNavMesh.NodeList]);
	ds_map_destroy(navMesh[eNavMesh.SpatialHash]);


}
