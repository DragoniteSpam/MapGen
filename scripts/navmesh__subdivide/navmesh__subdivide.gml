/// @description navmesh_subdivide(navMesh, bleedOver)
/// @param navMesh
/// @param bleedOver
function navmesh__subdivide(navMesh, bleedOver) {
	/*
		Subdivides the navmesh so that finding the nearest triangle at runtime is easier.
		BleedOver is the radius at which triangles will bleed over from one region to another. This is useful for 
		reducing the risk of not finding the nearest triangle. Should typically be as large as the radius of the largest unit that will use the navmesh.
	
		Script created by TheSnidr, 2019
	*/
	var quadGrid = navMesh[eNavMesh.QuadGrid];
	var spatialHash = ds_map_create();
	navMesh[@ eNavMesh.SpatialHash] = spatialHash;

	//Loop through the triangle list and find the average size of the triangles in the navmesh
	var num = ds_grid_height(quadGrid);
	var p1, p2, p3, p4;
	var H = 9999999;
	var Min = [H, H, H];
	var Max = [-H, -H, -H];
	var avgSize = 0;
	var minx, miny, minz, maxx, maxy, maxz;
	for (var i = 0; i < num; i ++)
	{
		p1 = quadGrid[# 0, i];
		p2 = quadGrid[# 1, i];
		p3 = quadGrid[# 2, i];
	
		minx = min(p1[eNavNode.X], p2[eNavNode.X], p3[eNavNode.X]);
		miny = min(p1[eNavNode.Y], p2[eNavNode.Y], p3[eNavNode.Y]);
		minz = min(p1[eNavNode.Z], p2[eNavNode.Z], p3[eNavNode.Z]);
		maxx = max(p1[eNavNode.X], p2[eNavNode.X], p3[eNavNode.X]);
		maxy = max(p1[eNavNode.Y], p2[eNavNode.Y], p3[eNavNode.Y]);
		maxz = max(p1[eNavNode.Z], p2[eNavNode.Z], p3[eNavNode.Z]);
	
		Min[0] = min(Min[0], minx);
		Min[1] = min(Min[1], miny);
		Min[2] = min(Min[2], minz);
		Max[0] = max(Max[0], maxx);
		Max[1] = max(Max[1], maxy);
		Max[2] = max(Max[2], maxz);
	
		avgSize += max(maxx - minx, maxy - miny, maxz - minz);
	}
	avgSize /= num;
	navMesh[@ eNavMesh.SpHbbox] = [Min[0], Min[1], Min[2], Max[0], Max[1], Max[2]];

	//Create spatial hash using twice the average tri size as region size
	var rSize, hSize, tri, startX, startY, startZ, endX, endY, endZ, xx, yy, zz, _x, _y, _z, key, n, arrayLength, newArray, array;
	rSize = 1.5 * avgSize;
	hSize = rSize * .5;
	navMesh[@ eNavMesh.SpHRegSize] = rSize;
	tri = array_create(12);
	for (i = 0; i < num; i ++)
	{
		p1 = quadGrid[# 0, i];
		p2 = quadGrid[# 1, i];
		p3 = quadGrid[# 2, i];
		p4 = quadGrid[# 3, i];
		n =  quadGrid[# 4, i];
		tri[0] = p1[eNavNode.X];
		tri[1] = p1[eNavNode.Y];
		tri[2] = p1[eNavNode.Z];
		tri[3] = p2[eNavNode.X];
		tri[4] = p2[eNavNode.Y];
		tri[5] = p2[eNavNode.Z];
		tri[6] = p3[eNavNode.X];
		tri[7] = p3[eNavNode.Y];
		tri[8] = p3[eNavNode.Z];
		tri[9]  = n[0];
		tri[10] = n[1];
		tri[11] = n[2];
	
		startX = floor((min(tri[0], tri[3], tri[6]) - bleedOver) / rSize);
		startY = floor((min(tri[1], tri[4], tri[7]) - bleedOver) / rSize);
		startZ = floor((min(tri[2], tri[5], tri[8]) - bleedOver) / rSize);
		endX = ceil((max(tri[0], tri[3], tri[6]) + bleedOver) / rSize);
		endY = ceil((max(tri[1], tri[4], tri[7]) + bleedOver) / rSize);
		endZ = ceil((max(tri[2], tri[5], tri[8]) + bleedOver) / rSize);
		for (xx = startX; xx <= endX; xx ++)
		{
			_x = (xx + .5) * rSize;
			for (yy = startY; yy <= endY; yy ++)
			{
				_y = (yy + .5) * rSize;
				for (zz = startZ; zz <= endZ; zz ++)
				{
					_z = (zz + .5) * rSize;
					key = string("{0},{1},{2}", xx, yy, zz);
					array = spatialHash[? key];
				
					if (is_undefined(array))
					{
						spatialHash[? key] = [i];
					}
					else
					{
						arrayLength = array_length(array);
						newArray = array_create(arrayLength + 1);
						array_copy(newArray, 0, array, 0, arrayLength);
						newArray[arrayLength] = i;
						spatialHash[? key] = newArray;
					}
				}
			}
		}
	}
}