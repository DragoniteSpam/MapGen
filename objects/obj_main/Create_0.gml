self.container = new EmuCore(0, 0, window_get_width(), window_get_height());

var ew = 320;
var eh = 32;

self.map_sprite = -1;
self.locations = [];
/// {struct.Location|undefined}
self.active_location = undefined;
/// {struct.Location|undefined}
self.hover_location = undefined;
self.location_placing = false;

self.relative_coordinates = true;

self.refresh_list = true;

try {
    self.map_sprite = sprite_add(MAP_IN_STORAGE, 0, false, false, 0, 0);
} catch (e) {
}

self.SetActiveLocation = function(location) {
    self.active_location = location;
    self.location_placing = true;
    self.container.Refresh();
};

self.container.AddContent([
    new EmuText(32, EMU_BASE, ew, eh, "[c_aqua]MapGen"),
    new EmuButton(32, EMU_AUTO, ew, eh, "Import Image", function() {
        var path = get_open_filename("Image files|*.png;*.bmp;*.jpg;*.jpeg", "map.png");
        if (file_exists(path)) {
            try {
                var sprite = sprite_add(path, 0, false, false, 0, 0);
                if (sprite_exists(obj_main.map_sprite)) {
                    sprite_delete(obj_main.map_sprite);
                }
                obj_main.map_sprite = sprite;
                sprite_save(obj_main.map_sprite, 0, MAP_IN_STORAGE);
            } catch (e) {
                show_debug_message("Could not load the map image:");
                show_debug_message(e.message);
                show_debug_message(e.longMessage);
            }
        }
    }),
    new EmuButton(32, EMU_AUTO, ew, eh, "Export JSON", function() {
        var filename = get_save_filename("JSON files|*.json", "connections.json");
        if (filename != "") {
            try {
                obj_main.Export(filename);
            } catch (e) {
                show_debug_message("Could not save the map data:");
                show_debug_message(e.message);
                show_debug_message(e.longMessage);
            }
        }
    }),
    new EmuCheckbox(32, EMU_AUTO, ew, eh, "Export relative coordinates", self.relative_coordinates, function() {
        obj_main.relative_coordinates = self.value;
    }),
    new EmuList(32, EMU_AUTO, ew, eh, "Locations:", eh, 12, function() {
        if (!obj_main.refresh_list) return;
        if (!self.root) return;
        obj_main.refresh_list = false;
        obj_main.active_location = self.GetSelectedItem();
        self.root.Refresh();
        obj_main.refresh_list = true;
    })
        .SetList(self.locations)
        .SetNumbered(true)
        .SetEntryTypes(E_ListEntryTypes.STRINGS)
        .SetRefresh(function() {
            // ::ClearSelection will erase active_location when it invokes the
            // list callback so save the original value here and use it instead
            var location = obj_main.active_location;
            if (!location) return;
            self.ClearSelection();
            self.Select(array_search(obj_main.locations, location));
        }),
    new EmuInput(32, EMU_AUTO, ew, eh, "Name:", "", "location name", 100, E_InputTypes.STRING, function() {
        obj_main.active_location.name = self.value;
    })
        .SetInteractive(false)
        .SetRefresh(function() {
            self.SetInteractive(!!obj_main.active_location);
            if (!obj_main.active_location) return;
            self.SetValue(obj_main.active_location.name);
        }),
    new EmuCheckbox(32, EMU_AUTO, ew, eh, "Locked?", true, function() {
        obj_main.active_location.locked = self.value;
    })
        .SetInteractive(false)
        .SetRefresh(function() {
            self.SetInteractive(!!obj_main.active_location);
            if (!obj_main.active_location) return;
            self.value = obj_main.active_location.locked;
        })
        .SetID("LOCK"),
    new EmuRenderSurface(32 + 32 + ew, EMU_BASE, 960, 720, function(mx, my) {
        draw_clear(c_black);
        if (sprite_exists(obj_main.map_sprite)) {
            draw_sprite_ext(obj_main.map_sprite, 0, self.map_x, self.map_y, self.zoom, self.zoom, 0, c_white, 1);
        }
        obj_main.hover_location = undefined;
        for (var i = 0, n = array_length(obj_main.locations); i < n; i++) {
            obj_main.locations[i].RenderConnections(self.zoom, self.map_x, self.map_y);
        }
        for (var i = 0, n = array_length(obj_main.locations); i < n; i++) {
            obj_main.locations[i].RenderPre(self.zoom, self.map_x, self.map_y, mx, my);
        }
        for (var i = 0, n = array_length(obj_main.locations); i < n; i++) {
            obj_main.locations[i].Render(self.zoom, self.map_x, self.map_y, mx, my);
        }
        for (var i = 0, n = array_length(obj_main.locations); i < n; i++) {
            obj_main.locations[i].RenderPost(self.zoom, self.map_x, self.map_y, mx, my);
        }
        draw_set_alpha(0.75);
        draw_rectangle_colour(0, 0, self.width, 32, c_white, c_white, c_white, c_white, false);
        draw_set_alpha(1);
        draw_text_colour(16, 16, "Click to add a location; ctrl+click to connect/disconnect locations; enter resets the camera", c_black, c_black, c_black, c_black, 1);
    }, function(mx, my) {
        var mouse_in_view = (mx >= 0 && mx <= self.width && my >= 0 && my <= self.width);
        if (mouse_in_view) {
            if (mouse_wheel_down()) {
                var cx = (mx - self.map_x) / self.zoom;
                var cy = (my - self.map_y) / self.zoom;
                self.zoom = max(0.25, self.zoom - 0.125);
                self.map_x = mx - self.zoom * cx;
                self.map_y = my - self.zoom * cy;
            } else if (mouse_wheel_up()) {
                var cx = (mx - self.map_x) / self.zoom;
                var cy = (my - self.map_y) / self.zoom;
                self.zoom = min(4.00, self.zoom + 0.125);
                self.map_x = mx - self.zoom * cx;
                self.map_y = my - self.zoom * cy;
            }
        }
        var spacing = 1;
        var cmx = ((mx - self.map_x) div spacing) * spacing / self.zoom;
        var cmy = ((my - self.map_y) div spacing) * spacing / self.zoom;
        if (mouse_in_view && mouse_check_button_pressed(mb_left)) {
            if (!obj_main.hover_location && (!obj_main.active_location || (obj_main.active_location && !obj_main.active_location.MouseIsOver(self.zoom, self.map_x, self.map_y, mx, my)))) {
                var location = new Location(cmx, cmy);
                array_push(obj_main.locations, location);
                obj_main.SetActiveLocation(location);
            }
        }
        if (mouse_check_button(mb_left)) {
            if (obj_main.active_location && obj_main.location_placing) {
                obj_main.active_location.Move(cmx, cmy);
            }
        } else {
            obj_main.location_placing = false;
        }
        if (mouse_in_view && mouse_check_button_pressed(mb_middle)) {
            self.panning = true;
            self.pan_x = mx;
            self.pan_y = my;
        }
        if (mouse_check_button(mb_middle)) {
            self.map_x += mx - self.pan_x;
            self.map_y += my - self.pan_y;
            self.pan_x = mx;
            self.pan_y = my;
            window_set_cursor(cr_size_all);
        } else {
            self.panning = false;
            window_set_cursor(cr_default);
        }
        
        if (obj_main.active_location && keyboard_check_pressed(KEY_TOGGLE_LOCKED)) {
            obj_main.active_location.locked = !obj_main.active_location.locked;
            obj_main.container.GetChild("LOCK").Refresh();
        }
        if (keyboard_check_pressed(KEY_RESET_MAP)) {
            self.zoom = 1;
            self.map_x = 0;
            self.map_y = 0;
            self.panning = false;
            self.pan_x = 0;
            self.pan_y = 0;
        }
        if (obj_main.active_location && keyboard_check_pressed(KEY_DELETE)) {
            obj_main.active_location.DisconnectAll();
            array_delete(obj_main.locations, array_search(obj_main.locations, obj_main.active_location), 1);
            obj_main.active_location = undefined;
            obj_main.container.Refresh();
        }
    }, function() {
        self.zoom = 1;
        self.map_x = 0;
        self.map_y = 0;
        self.panning = false;
        self.pan_x = 0;
        self.pan_y = 0;
    })
        .SetID("RS")
]);

self.Export = function(filename) {
    var output = {
        relative: obj_main.relative_coordinates && sprite_exists(self.map_sprite),
        full_size: {
            w: (obj_main.relative_coordinates && sprite_exists(self.map_sprite) ? sprite_get_width(self.map_sprite) : 1),
            h: (obj_main.relative_coordinates && sprite_exists(self.map_sprite) ? sprite_get_height(self.map_sprite) : 1),
        },
        locations: array_create(array_length(self.locations)),
    };
    
    var dwidth = 1 / output.full_size.w;
    var dheight = 1 / output.full_size.h;
    
    for (var i = 0, n = array_length(self.locations); i < n; i++) {
        self.locations[i].export_index = i;
    }
    
    for (var i = 0, n = array_length(self.locations); i < n; i++) {
        var source = self.locations[i];
        var written = {
            name: source.name,
            x: source.x * dwidth,
            y: source.y * dheight,
            connections: array_create(variable_struct_names_count(source.connections)),
            locked: source.locked,
        };
        var connection_keys = variable_struct_get_names(source.connections);
        for (var j = 0, n2 = array_length(connection_keys); j < n2; j++) {
            written.connections[j] = source.connections[$ connection_keys[j]].export_index;
        }
        output.locations[i] = written;
    }
    
    var buffer = buffer_create(1000, buffer_grow, 1);
    buffer_write(buffer, buffer_text, json_stringify(output));
    buffer_save_ext(buffer, filename, 0, buffer_tell(buffer));
    buffer_delete(buffer);
};