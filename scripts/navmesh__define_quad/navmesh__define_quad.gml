/// @description navmesh_define_quad(navmesh, p1, p2, p3, p4, nx, ny, nz);
/// @param navmesh
/// @param node1
/// @param node2
/// @param node3
/// @param node4
/// @param nx
/// @param ny
/// @param nz
function navmesh__define_quad(navmesh, p1, p2, p3, p4, nx, ny, nz) {
	/*
		Defines a quad from the given four points.
		If you only need a triangle, make the fourth node the same as the third.
	
		Script created by TheSnidr, 2019
	*/
	//Add each point to its neighbours' neighbour list
	navmesh__node_add_neighbour(p1, p2);
	navmesh__node_add_neighbour(p1, p3);
	navmesh__node_add_neighbour(p1, p4);
	navmesh__node_add_neighbour(p2, p3);
	navmesh__node_add_neighbour(p2, p4);
	navmesh__node_add_neighbour(p3, p4);
    
    var quadGrid = navmesh[eNavMesh.QuadGrid];
	var n = ds_grid_height(quadGrid);
    
    ds_grid_resize(quadGrid, 5, n + 1);
    
	//Then add all four vertices and the normal to the quad grid
	quadGrid[# 0, n] = p1;
	quadGrid[# 1, n] = p2;
	quadGrid[# 2, n] = p3;
	quadGrid[# 3, n] = p3;
	quadGrid[# 4, n] = [nx, ny, nz];
}