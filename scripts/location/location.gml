function Location(x, y) {
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
}