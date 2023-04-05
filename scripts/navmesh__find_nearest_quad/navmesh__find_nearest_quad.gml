/// @description navmesh_find_nearest_quad(navMesh, x, y, z)
/// @param navMesh
/// @param x
/// @param y
/// @param z
function navmesh__find_nearest_quad(navMesh, px, py, pz) {
	/*
		Finds the four vertices of the nearest quad.
		Returns an array of the following format:
		[node1, node2, node3, node4, newX, newY, newZ]
		where newX, newY, newZ is a new 3D position that is clamped within the triangle defined by the first three ndoes.
	
		Script created by TheSnidr, 2019
	*/
	var quadArray = -1;
	var quadGrid = navMesh[eNavMesh.QuadGrid];
	var spatialHash = navMesh[eNavMesh.SpatialHash];
	if !ds_map_empty(spatialHash)
	{
		var rSize = navMesh[eNavMesh.SpHRegSize];
		var bbox = navMesh[eNavMesh.SpHbbox];
		px = clamp(px, bbox[0], bbox[3]);
		py = clamp(py, bbox[1], bbox[4]);
		pz = clamp(pz, bbox[2], bbox[5]);
		var xx = floor(px / rSize);
		var yy = floor(py / rSize);
		var zz = floor(pz / rSize);
		var key = string("{0},{1},{2}", xx, yy, zz);
		var r = 1;
		quadArray = spatialHash[? key];
	
		//Spend a little effort to find the nearest region
		if is_undefined(quadArray)
		{
			for (var dr = 1; dr < 5; dr ++)
			{
				for (var dx = -dr; dx < dr;  dx ++)
				{
					for (var dy = -dr; dy < dr; dy ++)
					{
						//Positive x
						key = string("{0}-{1}-{2}", xx + dr, yy + dx, zz + dy);
						quadArray = spatialHash[? key];
						if !is_undefined(quadArray){break;}
					
						//Negative x
						key = string("{0}-{1}-{2}", xx - dr, yy + dx, zz + dy);
						quadArray = spatialHash[? key];
						if !is_undefined(quadArray){break;}
					
						//Positive y
                        key = string("{0}-{1}-{2}", xx + dx, yy + dr, zz + dy);
						quadArray = spatialHash[? key];
						if !is_undefined(quadArray){break;}
					
						//Negative y
						key = string("{0}-{1}-{2}", xx + dx, yy - dr, zz + dy);
						quadArray = spatialHash[? key];
						if !is_undefined(quadArray){break;}
					
						//Positive z
                        key = string("{0}-{1}-{2}", xx + dx, yy + dy, zz + dr);
						quadArray = spatialHash[? key];
						if !is_undefined(quadArray){break;}
					
						//Negative z
						key = string("{0}-{1}-{2}", xx + dx, yy + dy, zz - dr);
						quadArray = spatialHash[? key];
						if !is_undefined(quadArray){break;}
					}
					if dy < r{break;}
				}
				if dx < r{break;}
			}
		}
		if is_undefined(quadArray){return -1;}
	}

	var isRegion = is_array(quadArray);
	var quadNum = isRegion ? array_length(quadArray) : ds_grid_height(quadGrid);
	var nearestQuad = -1;
	var minDist = 9999999;
	var tx = array_create(3, 0);
	var ty = array_create(3, 0);
	var tz = array_create(3, 0);
	var q, p1, p2, p3, p4, n, j, jj, t0, t1, t2, u0, u1, u2, dp, dist, tentX, tentY, tentZ;
	for (var i = 0; i < quadNum; i ++)
	{
		q = isRegion ? quadArray[i] : i;
		////////////////////////////////////////////////////////////////////////////////////////////////////
		//Find the vertices of the quad
		p1 = quadGrid[# 0, q];
		p2 = quadGrid[# 1, q];
		p3 = quadGrid[# 2, q];
		p4 = quadGrid[# 3, q];
		n  = quadGrid[# 4, q];
	
		tx[0] = p1[0];
		ty[0] = p1[1];
		tz[0] = p1[2];
	
		tx[1] = p2[0];
		ty[1] = p2[1];
		tz[1] = p2[2];
	
		tx[2] = p3[0];
		ty[2] = p3[1];
		tz[2] = p3[2];
	
		////////////////////////////////////////////////////////////////////////////////////////////////////
		//Check distance to plane defined by triangle
        var d = dot_product_3d(px - tx[0], py - ty[0], pz - tz[0], n[0], n[1], n[2]);
		tentX = px - n[0] * d;
		tentY = py - n[1] * d;
		tentZ = pz - n[2] * d;
		dist = abs(d);
	
		////////////////////////////////////////////////////////////////////////////////////////////////////
		//Check each edge of the triangle. If the player is outside the edge, check the distance to the edge
		for (j = 0; j < 3; j ++)
		{
			jj = (j + 1) mod 3;
			t0 = px - tx[j];
			t1 = py - ty[j];
			t2 = pz - tz[j];
			u0 = tx[jj] - tx[j];
			u1 = ty[jj] - ty[j];
			u2 = tz[jj] - tz[j];
            if (dot_product_3d(t2 * u1 - t1 * u2, t0 * u2 - t2 * u0, t1 * u0 - t0 * u1, n[0], n[1], n[2]) < 0)
			{
				dp = clamp((u0 * t0 + u1 * t1 + u2 * t2) / (sqr(u0) + sqr(u1) + sqr(u2)), 0, 1);
				tentX = tx[j] + u0 * dp;
				tentY = ty[j] + u1 * dp;
				tentZ = tz[j] + u2 * dp;
				dist = max(abs(tentX-px), abs(tentY-py), abs(tentZ-pz));
				break;
			}
		}
	
		////////////////////////////////////////////////////////////////////////////////////////////////////
		//Check if this triangle is the closest one so far
		if (dist < minDist)
		{
			minDist = dist;
			if !is_array(nearestQuad){nearestQuad = array_create(7, 0);}
			nearestQuad[0] = p1;
			nearestQuad[1] = p2;
			nearestQuad[2] = p3;
			nearestQuad[3] = p4;
			nearestQuad[4] = tentX;
			nearestQuad[5] = tentY;
			nearestQuad[6] = tentZ;
		}
	}

	return nearestQuad;
}