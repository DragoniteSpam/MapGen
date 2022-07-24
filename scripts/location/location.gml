function Location(x, y) constructor {
    self.x = x;
    self.y = y;
    self.name = "Location" + string(ds_list_size(obj_main.locations));
    
    self.connections = { };
    
    self.Connect = function(dest) {
        self.connections[$ string(ptr(dest))] = dest;
        dest.connections[$ string(ptr(self))] = self;
    };
    
    self.Disconnect = function(dest) {
        if (variable_struct_exists(self.connections, string(ptr(dest))))
            variable_struct_remove(self.connections, string(ptr(dest)));
        if (variable_struct_exists(dest.connections, string(ptr(self))))
            variable_struct_remove(dest.connections, string(ptr(self)));
    };
    
    self.Render = function(mx, my) {
        static sw = sprite_get_width(spr_location) / 2;
        static sh = sprite_get_height(spr_location) / 2;
        if (obj_main.active_location == self) {
            draw_sprite(spr_location, 2, self.x, self.y);
        } else if (mx >= self.x - sw && my >= self.y - sh && mx <= self.x + sw && my <= self.y + sh) {
            draw_sprite(spr_location, 1, self.x, self.y);
        } else {
            draw_sprite(spr_location, 0, self.x, self.y);
        }
    };
}