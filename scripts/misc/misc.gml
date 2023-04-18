#macro MAP_IN_STORAGE       "map.png"
#macro GRAPH_IN_STORAGE     "autosave.json"
#macro SETTINGS_FILE        "settings.json"
#macro KEY_TOGGLE_LOCKED    vk_f2
#macro KEY_RESET_MAP        vk_enter
#macro KEY_DELETE           vk_delete
#macro KEY_DELETE_ALT       vk_backspace

#macro c_location_label_fill            #ffffcc
#macro c_navmesh_fill                   (obj_main.settings.map_mode == EMapModes.NAVMESH ? c_red : c_maroon)
#macro c_navmesh_fill_relevant          #ffbb33
#macro c_navmesh_fill_alpha             (obj_main.settings.map_mode == EMapModes.NAVMESH ? 0.25 : 0.2)
#macro c_navmesh_fill_alpha_relevant    0.5
#macro c_navmesh_path_connection        c_white
#macro c_node_connection                c_blue
#macro c_node_connection_navmesh_active #ff0066
#macro c_node_connection_aquila_route   #ff0066
#macro NODE_CONNECTION_WIDTH            2
#macro NODE_CONNECTION_NAVMESH_WIDTH    4
#macro NODE_CONNECTION_AQUILA_WIDTH     4

function local_to_map_space(coord, map_offset, zoom) {
    return (coord - map_offset) / zoom;
}

function map_to_local_space(coord, map_offset, zoom) {
    return coord * zoom + map_offset;
}