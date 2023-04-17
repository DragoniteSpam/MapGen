function Aquila() constructor {
    self.AquilaNode = function(data) constructor {
        static node_counter = 0;
        
        self.data = data;
        self.connections = { };
        self.id = string(node_counter++);
        
        self.GetConnections = function() {
            var keys = variable_struct_get_names(self.connections);
            var connections = array_create(array_length(keys));
            for (var i = 0, n = array_length(keys); i < n; i++) {
                connections[i] = self.connections[$ keys[i]];
            }
            return connections;
        };
        
        self.Connect = function(node, cost, bidirectional) {
            self.connections[$ node.id] = { source: self, destination: node, cost: cost };
            if(bidirectional) {
                node.Connect(self, cost, false);
            }
        };
        
        self.Disconnect = function(node) {
            if (variable_struct_exists(self.connections, node.id)) {
                variable_struct_remove(self.connections, node.id);
            }
        };
    };
    
    self.AquilaResult = function(route, stops, total_cost) constructor {
        self.route = route;
        self.stops = stops;
        self.total_cost = total_cost;
    };
    
    self.nodes = { };
    
    /// @return {struct.AquilaNode}
    self.AddNode = function(data) {
        var node = new self.AquilaNode(data);
        self.nodes[$ node.id] = node;
        return node;
    };
    
    /// @param node {struct.AquilaNode}
    self.RemoveNode = function(node) {
        if (variable_struct_exists(self.nodes, node.id)) {
            variable_struct_remove(self.nodes, node.id);
        }
    };
    
    /// @param a {struct.AquilaNode}
    /// @param b {struct.AquilaNode}
    /// @param cost {real}
    /// @param bidirectional {bool}
    self.ConnectNodes = function(a, b, cost = 1, bidirectional = true) {
        a.Connect(b, cost, bidirectional);
    };
    
    /// @param a {struct.AquilaNode}
    /// @param b {struct.AquilaNode}
    self.DisconnectNodes = function(a, b) {
        a.Disconnect(b);
        b.Disconnect(a);
    };
    
    self.ClearNodes = function() {
        self.nodes = { };
    };
    
    /// @return {array<struct.AquilaNode>}
    self.GetAllNodes = function() {
        var keys = variable_struct_get_names(self.nodes);
        /// {array<struct.AquilaNode>}
        var nodes = array_create(array_length(keys));
        for (var i = 0, n = array_length(keys); i < n; i++) {
            nodes[i] = self.nodes[$ keys[i]];
        }
        return nodes;
    };
    
    /// @return {real}
    self.Size = function() {
        return variable_struct_names_count(self.nodes);
    };
    
    /// @param source {struct.AquilaNode}
    /// @param source {struct.AquilaNode}
    /// return {struct.AquilaResult|undefined}
    self.Navigate = function(source, destination) {
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
                cost_current ??= 0;
                cost_neighbor ??= 0;
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