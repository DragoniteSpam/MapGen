function AquilaContainer() constructor {
    self.last_build_time = -1;
    self.last_navigation_time = -1;
    self.travel = {
        position: undefined
    };
    
    self.start = undefined;
    self.finish = undefined;
    
    self.SetStart = function(start) {
        self.start = start;
        self.Navigate();
        return self;
    };
    
    self.SetFinish = function(finish) {
        self.finish = finish;
        self.Navigate();
        return self;
    };
    
    self.Navigate = function() {
        if (!self.start) return;
        if (!self.finish) return;
        
        if (!self.travel.position) {
            self.travel.position = { x: self.start.x, y: self.start.y };
        }
        
        var t_start = get_timer();
        var aquila = new Aquila();
        var node_list = array_create(array_length(obj_main.locations));
        var node_map = { };
        
        for (var i = 0, n = array_length(obj_main.locations); i < n; i++) {
            var node = aquila.AddNode(obj_main.locations[i]);
            node_list[i] = {
                location: obj_main.locations[i],
                node: node,
                index: i
            };
            node_map[$ string(ptr(obj_main.locations[i]))] = node_list[i];
        }
        
        for (var i = 0, n = array_length(obj_main.locations); i < n; i++) {
            var location = obj_main.locations[i];
            var connections = variable_struct_get_names(location.connections);
            var this_aquila = node_list[i];
            for (var j = 0, n2 = array_length(connections); j < n2; j++) {
                // oof
                var other_aquila = node_map[$ string(ptr(location.connections[$ connections[j]]))];
                var other_location = other_aquila.location;
                var dist = point_distance(location.x, location.y, other_location.x, other_location.y);
                aquila.ConnectNodes(this_aquila.node, other_aquila.node, dist);
            }
        }
        
        self.last_build_time = (get_timer() - t_start) / 1000;
        
        t_start = get_timer();
        
        self.last_navigation_time = (get_timer() - t_start) / 1000;
    };
}