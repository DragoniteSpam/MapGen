function Location(x, y) constructor {
    self.x = x;
    self.y = y;
    self.name = "Location" + string(array_length(obj_main.locations));
    self.locked = true;
    
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
        return variable_struct_exists(self.connections, string(ptr(dest)));
    };
    
    self.Disconnect = function(dest) {
        if (variable_struct_exists(self.connections, string(ptr(dest))))
            variable_struct_remove(self.connections, string(ptr(dest)));
        if (variable_struct_exists(dest.connections, string(ptr(self))))
            variable_struct_remove(dest.connections, string(ptr(self)));
    };
    
    self.RenderConnections = function(zoom, map_x, map_y) {
        var keys = variable_struct_get_names(self.connections);
        for (var i = 0, n = array_length(keys); i < n; i++) {
            var dest = self.connections[$ keys[i]];
            draw_line_width_color(
                self.x * zoom + map_x, self.y * zoom + map_y,
                dest.x * zoom + map_x, dest.y * zoom + map_y,
                2, c_blue, c_blue
            );
        }
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
                    obj_main.active_location.Connect(self);
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
}