function array_search(array, item) {
    for (var i = 0, n = array_length(array); i < n; i++) {
        if (array[i] == item) return i;
    }
    return -1;
}

#macro MAP_IN_STORAGE       "map.png"
#macro GRAPH_IN_STORAGE     "autosave.json"
#macro KEY_TOGGLE_LOCKED    vk_f2
#macro KEY_RESET_MAP        vk_enter
#macro KEY_DELETE           vk_delete