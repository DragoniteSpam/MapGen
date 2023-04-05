/// @description navmesh_node_add_neighbour(p1, p2);
/// @param node1
/// @param node2
function navmesh__node_add_neighbour(p1, p2) {
	/*
		Connects two nodes to each other. If the nodes are already connected, this instruction is ignored.
	
		Script created by TheSnidr, 2019
	*/
	var p1Nb = p1[eNavNode.NbArray];
	var p1Dt = p1[eNavNode.DtArray];
		
	var p2Nb = p2[eNavNode.NbArray];
	var p2Dt = p2[eNavNode.DtArray];

	//First check p1 if p2 is already registered as a neighbour. Since neighbours are always added in pairs, we can exit the script if it is.
	var p1NbNum = array_length(p1Nb);
	for (var i = 0; i < p1NbNum; i ++)
	{
		if p1Nb[i] == p2
		{
			exit;
		}
	}
	/*
	//Add p2 to p1's neighbour list
	p1Nb[@ p1NbNum] = p2;
	p1Dt[@ p1NbNum] = dist;

	//Add p1 to p2's neighbour list
	p2Nb[@ p2NbNum] = p1;
	p2Dt[@ p2NbNum] = dist;*/
		
	var dist = point_distance_3d(p1[eNavNode.X], p1[eNavNode.Y], p1[eNavNode.Z], p2[eNavNode.X], p2[eNavNode.Y], p2[eNavNode.Z]);

	//The YoYo Compiler doesn't like dynamic arrays :( So instead of resizing the arrays, we can create new ones with the size we need, and copy the info over
	p1[@ eNavNode.NbArray] = array_create(p1NbNum + 1, p2);
	p1[@ eNavNode.DtArray] = array_create(p1NbNum + 1, dist);
	array_copy(p1[eNavNode.NbArray], 0, p1Nb, 0, p1NbNum);
	array_copy(p1[eNavNode.DtArray], 0, p1Dt, 0, p1NbNum);

	var p2NbNum = array_length(p2Nb);
	p2[@ eNavNode.NbArray] = array_create(p2NbNum + 1, p1);
	p2[@ eNavNode.DtArray] = array_create(p2NbNum + 1, dist);
	array_copy(p2[eNavNode.NbArray], 0, p2Nb, 0, p2NbNum);
	array_copy(p2[eNavNode.DtArray], 0, p2Dt, 0, p2NbNum);
}
