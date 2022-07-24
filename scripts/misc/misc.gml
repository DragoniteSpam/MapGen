function array_search(array, item) {
    for (var i = 0, n = array_length(array); i < n; i++) {
        if (array[i] == item) return i;
    }
    return -1;
}

#macro MAP_IN_STORAGE       "map.png"
#macro KEY_TOGGLE_LOCKED    vk_f2