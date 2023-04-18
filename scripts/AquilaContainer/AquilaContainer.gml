function AquilaContainer() constructor {
    self.last_build_time = -1;
    self.last_navigation_time = -1;
    self.travel = {
        position: undefined,
        path: [],
        start: undefined
    };
    
    self.CancelTravel = function() {
        self.travel.position = undefined;
        self.travel.path = [];
        self.travel.start = undefined;
    };
    
    self.SetTarget = function(target) {
        // if you already have a route, clear it
        if (array_length(self.travel.path) > 0) {
            self.CancelTravel();
        }
        // if you have a starting point set, navigate to the target
        if (self.travel.start) {
            self.Navigate(self.travel.start, target);
        // if nothing is set, set the target to the starting point
        } else {
            self.travel.start = target;
        }
    };
    
    self.Navigate = function(start, finish) {
        if (!start) return;
        if (!finish) return;
        
        if (!self.travel.position) {
            self.travel.position = { x: start.x, y: start.y };
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
        
        var result = aquila.Navigate(node_map[$ string(ptr(start))].node, node_map[$ string(ptr(finish))].node);
        
        if (result) {
            self.travel.path = array_create(result.stops);
            for (var i = 0, n = result.stops; i < n; i++) {
                self.travel.path[i + 1] = result.route[i].data;
            }
        } else {
            show_debug_message("No path found between {0} and {1}", start.name, finish.name);
            self.travel.path = [];
        }
        
        self.last_navigation_time = (get_timer() - t_start) / 1000;
    };
    
    self.ConnectionOnRoute = function(a, b) {
        for (var i = 0, n = array_length(self.travel.path) - 1; i < n; i++) {
            if ((self.travel.path[i] == a && self.travel.path[i + 1] == b) ||
                (self.travel.path[i] == b && self.travel.path[i + 1] == a)) {
                    return true;
            }
        }
        return false;
    };
    
    self.LocationOnRoute = function(location) {
        for (var i = 0, n = array_length(self.travel.path); i < n; i++) {
            if (self.travel.path[i] == location) {
                return true;
            }
        }
        return false;
    };
}