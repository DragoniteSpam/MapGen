/// @description navmesh_mbuff_trim_attributes(vBuff, bytesPerVert)
/// @param mbuff
/// @param bytesPerVert
function navmesh__mbuff_trim_attributes(mBuff, bytesPerVert) {
	/*
		Removes all attributes except position, and generates a normal.
	
		Script created by TheSnidr, 2019
	*/
	var bytesPerTri = bytesPerVert * 3;
	if !is_array(mBuff){mBuff = [mBuff];}

	var returnBuff = buffer_create(1, buffer_grow, 1);
	var modelNum = array_length(mBuff);
	var newBuffSize = 0;

	var px1, py1, pz1, px2, py2, pz2, px3, py3, pz3, nx, ny, nz, l;
	for (var m = 0; m < modelNum; m ++)
	{
		var buffSize = buffer_get_size(mBuff[m]);
		newBuffSize += buffSize * 4 * 6 / bytesPerVert;
	
		for (var i = 0; i < buffSize; i += bytesPerTri)
		{
			buffer_seek(mBuff[m], buffer_seek_start, i);
			px1 = buffer_read(mBuff[m], buffer_f32);
			py1 = buffer_read(mBuff[m], buffer_f32);
			pz1 = buffer_read(mBuff[m], buffer_f32);
	
			buffer_seek(mBuff[m], buffer_seek_start, i + bytesPerVert);
			px2 = buffer_read(mBuff[m], buffer_f32);
			py2 = buffer_read(mBuff[m], buffer_f32);
			pz2 = buffer_read(mBuff[m], buffer_f32);
	
			buffer_seek(mBuff[m], buffer_seek_start, i + 2 * bytesPerVert);
			px3 = buffer_read(mBuff[m], buffer_f32);
			py3 = buffer_read(mBuff[m], buffer_f32);
			pz3 = buffer_read(mBuff[m], buffer_f32);
	
			nx = (py2 - py1) * (pz3 - pz1) - (pz2 - pz1) * (py3 - py1);
			ny = (pz2 - pz1) * (px3 - px1) - (px2 - px1) * (pz3 - pz1);
			nz = (px2 - px1) * (py3 - py1) - (py2 - py1) * (px3 - px1);
			l = point_distance_3d(0, 0, 0, nx, ny, nz);
			if (l == 0){continue;}
			nx /= l;
			ny /= l;
			nz /= l;
	
			buffer_write(returnBuff, buffer_f32, px1);
			buffer_write(returnBuff, buffer_f32, py1);
			buffer_write(returnBuff, buffer_f32, pz1);
			buffer_write(returnBuff, buffer_f32, nx);
			buffer_write(returnBuff, buffer_f32, ny);
			buffer_write(returnBuff, buffer_f32, nz);
	
			buffer_write(returnBuff, buffer_f32, px2);
			buffer_write(returnBuff, buffer_f32, py2);
			buffer_write(returnBuff, buffer_f32, pz2);
			buffer_write(returnBuff, buffer_f32, nx);
			buffer_write(returnBuff, buffer_f32, ny);
			buffer_write(returnBuff, buffer_f32, nz);
	
			buffer_write(returnBuff, buffer_f32, px3);
			buffer_write(returnBuff, buffer_f32, py3);
			buffer_write(returnBuff, buffer_f32, pz3);
			buffer_write(returnBuff, buffer_f32, nx);
			buffer_write(returnBuff, buffer_f32, ny);
			buffer_write(returnBuff, buffer_f32, nz);
		}
	}
	buffer_resize(returnBuff, buffer_tell(returnBuff));
	return returnBuff;
}