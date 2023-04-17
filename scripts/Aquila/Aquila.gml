function Aquila() constructor {
    static AquilaNode = function(data, graph) constructor {
        static node_counter = 0;
        
        self.data = data;
        self.graph = graph;
        self.connections = { };
        self.id = string(node_counter++);
        
        static GetConnections = function() {
            var keys = variable_struct_get_names(self.connections);
            var connections = array_create(array_length(keys));
            for (var i = 0, n = array_length(keys); i < n; i++) {
                connections[i] = self.connections[$ keys[i]];
            }
            return connections;
        };
        
        static connect = function(node, cost, bidirectional) {
            self.connections[$ node.id] = { source: self, destination: node, cost: cost };
            if(bidirectional) {
                node.connect(self, cost, false);
            }
        };
        
        static disconnect = function(node) {
            if (variable_struct_exists(self.connections, node.id)) {
                variable_struct_remove(self.connections, node.id);
            }
        };
    };
    
    static AquilaResult = function(route, stops, total_cost) constructor {
        self.route = route;
        self.stops = stops;
        self.total_cost = total_cost;
    };
    
    static graph_counter = 0;
    
    self.id = graph_counter++;
    self.nodes = { };
    
    static AddNode = function(data) {
        var node = new self.AquilaNode(data, self.id);
        self.nodes[$ node.id] = node;
        return node;
    };
    
    static RemoveNode = function(node) {
        if (variable_struct_exists(self.nodes, node.id)) {
            node.graph = undefined;
            variable_struct_remove(self.nodes, node.id);
        }
    };
    
    static ConnectNodes = function(a, b, cost = 1, bidirectional = true) {
        if (a.graph == self.id && b.graph == self.id) {
            a.connect(b, cost, bidirectional);
        } else {
            show_debug_message("Unable to connect nodes " + string(ptr(a)) + " and " + string(ptr(b)) + " - both nodes must be long to the same network");
        }
    };
    
    static DisconnectNodes = function(a, b) {
        if (a.graph == self.id && b.graph == self.id) {
            a.disconnect(b);
            b.disconnect(a);
        } else {
            show_debug_message("Unable to disconnect nodes " + string(ptr(a)) + " and " + string(ptr(b)) + " - both nodes must be long to the same network");
        }
    };
    
    static ClearNodes = function() {
        var keys = variable_struct_get_names(self.nodes);
        var nodes = array_create(array_length(keys));
        for (var i = 0, n = array_length(keys); i < n; i++) {
            self.nodes[$ keys[i]].graph = undefined;
        }
        self.nodes = { };
    };
    
    static GetAllNodes = function() {
        var keys = variable_struct_get_names(self.nodes);
        var nodes = array_create(array_length(keys));
        for (var i = 0, n = array_length(keys); i < n; i++) {
            nodes[i] = self.nodes[$ keys[i]];
        }
        return nodes;
    };
    
    static Size = function() {
        return variable_struct_names_count(self.nodes);
    };
    
    static Navigate = function(source, destination) {
        if (source.graph != self.id || destination.graph != self.id) {
            show_debug_message("Unable to navigate between nodes " + string(ptr(source)) + " and " + string(ptr(destination)) + " - both nodes must be long to the same network");
            return undefined;
        }
        
        var t = source;
        source = destination;
        destination = t;
        
        static frontier = ds_priority_create();
        ds_priority_clear(frontier);
        var came_from = { };
        var costs = { };
        
        ds_priority_add(frontier, source, 0);
        
        // this one doesnt work but in a different way...
        while (!ds_priority_empty(frontier)) {
            var current = ds_priority_delete_min(frontier);
            
            if (current == destination) {
                var path = [destination];
                var total_cost = 0;
                while (current != source) {
                    total_cost += current.connections[$ came_from[$ current.id].id].cost;
                    current = came_from[$ current.id];
                    array_push(path, current);
                }
                return new self.AquilaResult(path, array_length(path), total_cost);
            }
            
            var neighbor_ids = variable_struct_get_names(current.connections);
            for (var i = 0, n = array_length(neighbor_ids); i < n; i++) {
                var neighbor = neighbor_ids[i];
                var cost_current = costs[$ current.id];
                var cost_neighbor = costs[$ neighbor];
                if (cost_current == undefined) cost_current = 0;
                if (cost_neighbor == undefined) cost_neighbor = 0;
                var cost_tentative = cost_current + current.connections[$ neighbor].cost;
                
                if (!came_from[$ neighbor] || cost_tentative < cost_neighbor) {
                    came_from[$ neighbor] = current;
                    costs[$ neighbor] = cost_tentative;
                    ds_priority_add(frontier, self.nodes[$ neighbor], cost_tentative);
                }
            }
        }
        
        return undefined;
    };
}