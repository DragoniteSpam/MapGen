/*
	Initializes Snidrs navigation mesh system
	
	Script created by TheSnidr, 2019
*/
//Macros
#macro NavMeshBytesPerVert 24

//Data structures
global.NavMeshOpenSet = ds_priority_create();
global.NavMeshClosedSet = ds_map_create();

//Enums
enum eNavNode{
	X, Y, Z, ID, NbArray, DtArray, Gscore, CameFrom, Num}

enum eNavMesh{
	NodeList, QuadGrid, SpatialHash, SpHRegSize, SpHbbox, Num}