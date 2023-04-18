function Location(x, y) constructor {
    self.x = x;
    self.y = y;
    self.name = "Location" + string(array_length(obj_main.locations));
    self.locked = true;
    self.summary = "";
    self.category = "";
    
    // this is only set when exporting
    self.export_index = 0;
    
    self.connections = { };
    
    self.Move = function(x, y) {
        if (self.locked) return;
        self.x = x;
        self.y = y;
    };
    
    self.Connect = function(dest) {
        self.connections[$ string(ptr(dest))] = dest;
        dest.connections[$ string(ptr(self))] = self;
    };
    
    self.IsConnected = function(dest) {
        if (!dest) return false;
        return variable_struct_exists(self.connections, string(ptr(dest)));
    };
    
    self.Disconnect = function(dest) {
        if (variable_struct_exists(self.connections, string(ptr(dest))))
            variable_struct_remove(self.connections, string(ptr(dest)));
        if (variable_struct_exists(dest.connections, string(ptr(self))))
            variable_struct_remove(dest.connections, string(ptr(self)));
    };
    
    self.DisconnectAll = function() {
        var keys = variable_struct_get_names(self.connections);
        for (var i = 0, n = array_length(keys); i < n; i++) {
            self.connections[$ keys[i]].Disconnect(self);
        }
    };
    
    self.RenderConnections = function(zoom, map_x, map_y) {
        var xx = map_to_local_space(self.x, map_x, zoom);
        var yy = map_to_local_space(self.y, map_y, zoom);
        
        var keys = variable_struct_get_names(self.connections);
        for (var i = 0, n = array_length(keys); i < n; i++) {
            var dest = self.connections[$ keys[i]];
            var c = c_node_connection;
            var w = NODE_CONNECTION_WIDTH;
            
            switch (obj_main.settings.map_mode) {
                case EMapModes.NAVMESH:
                    var navmesh_tri = obj_main.navmesh.relevant_triangle;
                    if (navmesh_tri && navmesh_tri.Contains(self) && navmesh_tri.Contains(dest)) {
                        c = c_node_connection_navmesh_active;
                        w = NODE_CONNECTION_NAVMESH_WIDTH;
                    }
                    break;
                case EMapModes.AQUILA:
                    if (obj_main.aquila.ConnectionOnRoute(self, dest)) {
                        c = c_node_connection_aquila_route;
                        w = NODE_CONNECTION_AQUILA_WIDTH;
                    }
                    break;
            }
            
            var dx = map_to_local_space(dest.x, map_x, zoom);
            var dy = map_to_local_space(dest.y, map_y, zoom);
            
            draw_line_width_color(xx, yy, dx, dy, w, c, c);
        }
    };
    
    self.RenderNavmesh = function(zoom, map_x, map_y, mx, my, color, alpha) {
        var xx = map_to_local_space(self.x, map_x, zoom);
        var yy = map_to_local_space(self.y, map_y, zoom);
        draw_vertex_color(xx, yy, color, alpha);
        return { x: xx, y: yy };
    };
    
    self.RenderPre = function(zoom, map_x, map_y, mx, my) {
        var xx = map_to_local_space(self.x, map_x, zoom);
        var yy = map_to_local_space(self.y, map_y, zoom);
        if (self.locked) {
            draw_sprite(spr_lock, 0, xx, yy + 20);
        }
    };
    
    self.RenderPost = function(zoom, map_x, map_y, mx, my) {
        var xx = map_to_local_space(self.x, map_x, zoom);
        var yy = map_to_local_space(self.y, map_y, zoom);
    };
    
    self.Render = function(zoom, map_x, map_y, mx, my) {
        var xx = map_to_local_space(self.x, map_x, zoom);
        var yy = map_to_local_space(self.y, map_y, zoom);
        
        var mouse_is_over = self.MouseIsOver(zoom, map_x, map_y, mx, my);
        if (mouse_is_over) {
            var index = 1;
            obj_main.hover_location = self;
            switch (obj_main.settings.map_mode) {
                case EMapModes.DEFAULT:
                    if (mouse_check_button_pressed(mb_left)) {
                        if (obj_main.active_location && obj_main.active_location != self && keyboard_check(vk_control)) {
                            if (self.IsConnected(obj_main.active_location)) {
                                obj_main.active_location.Disconnect(self);
                            } else {
                                obj_main.active_location.Connect(self);
                            }
                        } else {
                            obj_main.SetActiveLocation(self);
                        }
                    }
                    if (obj_main.active_location == self) {
                        index = 2;
                    }
                    if (mouse_check_button_pressed(mb_left)) {
                        obj_main.location_placing = true;
                    }
                    break;
                case EMapModes.NAVMESH:
                    if (mouse_check_button_pressed(mb_left)) {
                        obj_main.SetActiveLocation(self);
                        if (!obj_main.navmesh.relevant_triangle || obj_main.navmesh.relevant_triangle.IsComplete()) {
                            obj_main.navmesh.AddTriangle();
                        }
                        obj_main.navmesh.relevant_triangle.AddVertex(self);
                    }
                    break;
                case EMapModes.AQUILA:
                    if (mouse_check_button_pressed(mb_left)) {
                        obj_main.aquila.SetTarget(self);
                    }
                    if (obj_main.aquila.LocationOnRoute(self)) {
                        index = 3;
                    }
                    break;
            }
            draw_sprite(spr_location, index, xx, yy);
        } else {
            var index = 0;
            switch (obj_main.settings.map_mode) {
                case EMapModes.DEFAULT:
                    if (obj_main.active_location == self) {
                        index = 2;
                    }
                    break;
                case EMapModes.NAVMESH:
                    if (obj_main.navmesh.relevant_triangle && obj_main.navmesh.relevant_triangle.Contains(self)) {
                        index = 2;
                    }
                    break;
                case EMapModes.AQUILA:
                    if (obj_main.aquila.LocationOnRoute(self)) {
                        index = 2;
                    }
                    break;
            }
            draw_sprite(spr_location, index, xx, yy);
        }
    };
    
    self.MouseIsOver = function(zoom, map_x, map_y, mx, my) {
        static sw = sprite_get_width(spr_location) / 2;
        static sh = sprite_get_height(spr_location) / 2;
        var xx = map_to_local_space(self.x, map_x, zoom);
        var yy = map_to_local_space(self.y, map_y, zoom);
        return mx >= xx - sw && my >= yy - sh && mx <= xx + sw && my <= yy + sh;
    };
    
    self.toString = function() {
        return (self.locked ? "[spr_lock]" : "") + (self.summary != "" ? "[c_aqua]" : "") + self.name + (self.category != "" ? (" [c_gray](" + self.category + ")") : "");
    };
    
    self.Hash = function() {
        return string("{0}-{1}", self.x, self.y);
    };
}