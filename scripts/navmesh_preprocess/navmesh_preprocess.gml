/// @description navmesh_preprocess(navMesh, bleedOver)
/// @param navMesh
/// @param bleedOver
function navmesh_preprocess(navMesh, bleedOver) {
	/*
		Processes the given navmesh to speed up pathfinding.
		Subdivides the navmesh into smaller sections to speed up the process of finding the nearest triangle
		Identifies a fourth vertex for each triangle.
	
		It's recommended to use this once after you're done creating the navmesh.
	
		Script created by TheSnidr, 2019
	*/
	navmesh__subdivide(navMesh, bleedOver);
	navmesh__identify_quads(navMesh);
}