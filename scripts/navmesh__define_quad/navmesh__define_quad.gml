/// @description navmesh_define_quad(p1, p2, p3, p4, nx, ny, nz);
/// @param node1
/// @param node2
/// @param node3
/// @param node4
/// @param nx
/// @param ny
/// @param nz
function navmesh__define_quad(p1, p2, p3, p4, nx, ny, nz) {
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
		
	//Then add all four vertices and the normal to the quad grid
	h = i div bytesPerTri;
	quadGrid[# 0, h] = p1;
	quadGrid[# 1, h] = p2;
	quadGrid[# 2, h] = p3;
	quadGrid[# 3, h] = p3;
	quadGrid[# 4, h] = [nx, ny, nz];
}