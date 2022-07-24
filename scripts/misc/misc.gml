function array_search(array, item) {
    for (var i = 0, n = array_length(array); i < n; i++) {
        if (array[i] == item) return i;
    }
    return -1;
}