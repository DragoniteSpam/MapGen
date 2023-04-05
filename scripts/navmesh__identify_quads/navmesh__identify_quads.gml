/// @description navmesh_identify_quads(navMesh)
/// @param navMesh
function navmesh__identify_quads(navMesh) {
	/*
		Identifies quads in the navmesh.
		This is useful since the player can move freely inside a quad without having to do any pathfinding.
		Ïf this script has not been used, the navmesh will only consist of triangles.
	
		Script created by TheSnidr, 2019
	*/
	var quadGrid = navMesh[eNavMesh.QuadGrid];
	var num = ds_grid_height(quadGrid);

	//Loop through all triangles of the navmesh
	var i, j, k, n, maxDist, d, p1, p2, p3, n1, n2, n3, n4, nbArray1, nbArray2, nbNum1, nbNum2;;
	for (i = 0; i < num; i ++)
	{
		p1 = quadGrid[# 0, i];
		p2 = quadGrid[# 1, i];
		p3 = quadGrid[# 2, i];
		n =  quadGrid[# 4, i];
	
		//Find the longest line in the triangle
		maxDist = point_distance_3d(p1[0], p1[1], p1[2], p2[0], p2[1], p2[2]);
		n1 = p1;
		n2 = p2;
		n3 = p3;
	
		d = point_distance_3d(p1[0], p1[1], p1[2], p3[0], p3[1], p3[2]);
		if d > maxDist
		{
			maxDist = d;
			n1 = p1;
			n2 = p3;
			n3 = p2;
		}
	
		d = point_distance_3d(p2[0], p2[1], p2[2], p3[0], p3[1], p3[2]);
		if d > maxDist
		{
			maxDist = d;
			n1 = p2;
			n2 = p3;
			n3 = p1;
		}
	
		//We have found the longest line of the triangle. Now we need to find the third point in the other triangle these two points share, if there is one
		nbArray1 = n1[eNavNode.NbArray];
		nbNum1 = array_length(nbArray1);
		nbArray2 = n2[eNavNode.NbArray];
		nbNum2 = array_length(nbArray2);
		for (j = 0; j < nbNum1; j ++)
		{
			for (k = 0; k < nbNum2; k ++)
			{
				//If the points have a common neighbour, and this is not the already known neighbour, add it to the triangle list
				if (nbArray1[j] == nbArray2[k])
				{
					if (nbArray1[j] == n3){continue;}
					n4 = nbArray1[j];
					if abs(dot_product_3d_normalized(n4[0] - n1[0], n4[1] - n1[1], n4[2] - n1[2], n[0], n[1], n[2])) < .2
					{
						quadGrid[# 3, i] = n4;
						navmesh__node_add_neighbour(n3, n4);
						break;
					}
				}
			}
			if (k < nbNum2){break;}
		}
	}
}