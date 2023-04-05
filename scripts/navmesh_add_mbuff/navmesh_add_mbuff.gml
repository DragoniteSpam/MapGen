/// @description navmesh_create_from_mbuff(navmesh, mbuff, bytesPerVert)
/// @param navmesh
/// @param mbuff
/// @param bytesPerVert
function navmesh_add_mbuff(navMesh, mbuff, sourceBytesPerVert) {
	/*
		Add all the vertices of a given model buffer to the navmesh.
		Only pr_trianglelist is supported!
	
		Script created by TheSnidr, 2019
	*/
	var bytesPerVert = NavMeshBytesPerVert;
	var mBuff = navmesh__mbuff_trim_attributes(mbuff, sourceBytesPerVert);
	var bytesPerTri = 3 * bytesPerVert;

	var buffSize = buffer_get_size(mBuff);

	var nodeMap = ds_map_create();
	var quadGrid = navMesh[eNavMesh.QuadGrid];
	ds_grid_resize(quadGrid, 5, buffSize div bytesPerTri);

	buffer_seek(mBuff, buffer_seek_start, 0);

	var px, py, pz, key, p1, p2, p3, node, nx, ny, nz, h;
	for (var i = 0; i < buffSize; i += bytesPerVert)
	{
		buffer_seek(mBuff, buffer_seek_start, i);
		px = buffer_read(mBuff, buffer_f32);
		py = buffer_read(mBuff, buffer_f32);
		pz = buffer_read(mBuff, buffer_f32);
	
		//Index the vertices so that a single point is only added once. 
		//Coinciding vertices are considered as the same path point
		key = string("{0},{1},{2}",px, py, pz);
	
		node = nodeMap[? key];
		if (is_undefined(node))
		{
			node = navmesh__add_node(navMesh, px, py, pz);
			nodeMap[? key] = node;
		}
	
		//If this is the last point in a triplet, add it to its own and to its neighbours' neighbour array
		var ii = (i div bytesPerVert) mod 3;
		if (ii == 0){p1 = node;}
		if (ii == 1){p2 = node;}
		if (ii == 2)
		{
			p3 = node;
		
			nx = buffer_read(mBuff, buffer_f32);
			ny = buffer_read(mBuff, buffer_f32);
			nz = buffer_read(mBuff, buffer_f32);
		
			//Add neighbours
			navmesh__node_add_neighbour(p1, p2);
			navmesh__node_add_neighbour(p1, p3);
			navmesh__node_add_neighbour(p2, p3);
		
			//Then add all three vertices and the triangle normal to the quad grid
			h = i div bytesPerTri;
			quadGrid[# 0, h] = p1;
			quadGrid[# 1, h] = p2;
			quadGrid[# 2, h] = p3;
			quadGrid[# 3, h] = p3;
			quadGrid[# 4, h] = [nx, ny, nz];
		}
	}

	ds_map_destroy(nodeMap);
	buffer_delete(mBuff);

	return navMesh;
}