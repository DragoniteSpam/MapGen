function AquilaContainer() constructor {
    self.last_build_time = -1;
    self.last_navigation_time = -1;
    self.travel = {
        position: undefined,
        path: [],
        start: undefined
    };
    
    self.CancelTravel = function(reset_position = false) {
        //self.travel.position = undefined;
        self.travel.path = [];
        self.travel.start = undefined;
        if (reset_position) {
            self.travel.position = undefined;
        }
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
            self.travel.position = { x: target.x, y: target.y };
        }
    };
    
    self.Navigate = function(start, finish) {
        if (!start) return;
        if (!finish) return;
        
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
                self.travel.path[i] = result.route[i].data;
            }
        } else {
            show_debug_message("No path found between {0} and {1}", start.name, finish.name);
            self.travel.path = [];
        }
        
        self.last_navigation_time = (get_timer() - t_start) / 1000;
    };
    
    self.RenderTravel = function(zoom, map_x, map_y) {
        if (!self.travel.position) return;
        
        static spd = 4;
        
        if (array_length(self.travel.path) > 0) {
            var xx = self.travel.path[0].x;
            var yy = self.travel.path[0].y;
            var dist = point_distance(self.travel.position.x, self.travel.position.y, xx, yy);
            var dir = point_direction(self.travel.position.x, self.travel.position.y, xx, yy);
            if (dist <= spd) {
                self.travel.position.x = xx;
                self.travel.position.y = yy;
                array_delete(self.travel.path, 0, 1);
                if (array_length(self.travel.path) == 0) {
                    self.CancelTravel();
                }
            } else {
                self.travel.position.x += spd * dcos(dir);
                self.travel.position.y -= spd * dsin(dir);
            }
        }
        
        var jx = map_to_local_space(self.travel.position.x, map_x, zoom);
        var jy = map_to_local_space(self.travel.position.y, map_y, zoom);
        draw_sprite(spr_aquila, 0, jx, jy);
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
        if (array_length(self.travel.path) == 0) {
            return self.travel.start == location;
        }
        
        for (var i = 0, n = array_length(self.travel.path); i < n; i++) {
            if (self.travel.path[i] == location) {
                return true;
            }
        }
        return false;
    };
}