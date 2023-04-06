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
        var keys = variable_struct_get_names(self.connections);
        for (var i = 0, n = array_length(keys); i < n; i++) {
            var dest = self.connections[$ keys[i]];
            var c = c_node_connection;
            var w = NODE_CONNECTION_WIDTH;
            
            var navmesh_tri = obj_main.navmesh.relevant_triangle;
            if (navmesh_tri && navmesh_tri.Contains(self) && navmesh_tri.Contains(dest)) {
                c = c_node_connection_navmesh_active;
                w = NODE_CONNECTION_NAVMESH_WIDTH;
            }
            
            draw_line_width_color(
                self.x * zoom + map_x, self.y * zoom + map_y,
                dest.x * zoom + map_x, dest.y * zoom + map_y,
                w, c, c
            );
        }
    };
    
    self.RenderNavmesh = function(zoom, map_x, map_y, mx, my) {
        var xx = self.x * zoom + map_x;
        var yy = self.y * zoom + map_y;
        draw_vertex_color(xx, yy, c_navmesh_fill, c_navmesh_fill_alpha);
    };
    
    self.RenderPre = function(zoom, map_x, map_y, mx, my) {
        var xx = self.x * zoom + map_x;
        var yy = self.y * zoom + map_y;
        if (self.locked) {
            draw_sprite(spr_lock, 0, xx, yy + 20);
        }
    };
    
    self.RenderPost = function(zoom, map_x, map_y, mx, my) {
        var xx = self.x * zoom + map_x;
        var yy = self.y * zoom + map_y;
    };
    
    self.Render = function(zoom, map_x, map_y, mx, my) {
        var mouse_is_over = self.MouseIsOver(zoom, map_x, map_y, mx, my);
        if (obj_main.active_location == self) {
            draw_sprite(spr_location, 2, self.x * zoom + map_x, self.y * zoom + map_y);
            if (mouse_is_over && mouse_check_button_pressed(mb_left)) {
                obj_main.location_placing = true;
            }
        } else if (mouse_is_over) {
            draw_sprite(spr_location, 1, self.x * zoom + map_x, self.y * zoom + map_y);
            obj_main.hover_location = self;
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
        } else {
            draw_sprite(spr_location, 0, self.x * zoom + map_x, self.y * zoom + map_y);
        }
    };
    
    self.MouseIsOver = function(zoom, map_x, map_y, mx, my) {
        static sw = sprite_get_width(spr_location) / 2;
        static sh = sprite_get_height(spr_location) / 2;
        return mx >= self.x * zoom - sw + map_x && my >= self.y * zoom - sh + map_y && mx <= self.x * zoom + sw + map_x && my <= self.y * zoom + sh + map_y;
    };
    
    self.toString = function() {
        return (!self.locked ? "[spr_lock]" : "") + (self.summary != "" ? "[c_aqua]" : "") + self.name + (self.category != "" ? (" [c_gray](" + self.category + ")") : "");
    };
}