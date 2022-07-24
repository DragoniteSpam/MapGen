function Location(x, y) constructor {
    self.x = x;
    self.y = y;
    self.name = "Location" + string(array_length(obj_main.locations));
    
    self.connections = { };
    
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
    
    self.Render = function(zoom, map_x, map_y, mx, my) {
        if (obj_main.active_location == self) {
            draw_sprite(spr_location, 2, self.x * zoom + map_x, self.y * zoom + map_y);
        } else if (self.MouseIsOver(zoom, map_x, map_y, mx, my)) {
            draw_sprite(spr_location, 1, self.x * zoom + map_x, self.y * zoom + map_y);
            obj_main.hover_location = self;
            if (mouse_check_button_pressed(mb_left)) {
                if (obj_main.active_location && obj_main.active_location != self && keyboard_check(vk_control)) {
                    obj_main.active_location.Connect(self);
                } else {
                    obj_main.active_location = self;
                    obj_main.container.GetChild("RS").location_placing = true;
                }
            }
        } else {
            draw_sprite(spr_location, 0, self.x * zoom + map_x, self.y * zoom + map_y);
        }
    };
    
    self.MouseIsOver = function(zoom, map_x, map_y, mx, my) {
        static sw = sprite_get_width(spr_location) / 2;
        static sh = sprite_get_height(spr_location) / 2;
        return mx >= self.x * zoom - sw && my >= self.y * zoom - sh && mx <= self.x * zoom + sw && my <= self.y * zoom + sh
    };
}