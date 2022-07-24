#macro MAP_IN_STORAGE       "map.png"

self.container = new EmuCore(0, 0, window_get_width(), window_get_height());

var ew = 320;
var eh = 32;

self.map_sprite = -1;
self.locations = ds_list_create();
self.active_location = undefined;

try {
    self.map_sprite = sprite_add(MAP_IN_STORAGE, 0, false, false, 0, 0);
} catch (e) {
}

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
            }
        }
    }),
    new EmuButton(32, EMU_AUTO, ew, eh, "Export JSON", function() {
    }),
    new EmuList(32, EMU_AUTO, ew, eh, "Locations:", eh, 12, function() {
    }),
    new EmuInput(32, EMU_AUTO, ew, eh, "Name:", "", "location name", 100, E_InputTypes.STRING, function() {
    }),
    new EmuRenderSurface(32 + 32 + ew, EMU_BASE, 640, 640, function(mx, my) {
        draw_clear(c_black);
        if (sprite_exists(obj_main.map_sprite)) {
            draw_sprite_ext(obj_main.map_sprite, 0, self.map_x, self.map_y, self.zoom, self.zoom, 0, c_white, 1);
        }
        for (var i = 0, n = ds_list_size(obj_main.locations); i < n; i++) {
            obj_main.locations[| i].Render(self.zoom, mx, my);
        }
    }, function(mx, my) {
        if (mouse_wheel_down()) {
            self.zoom = max(0.25, self.zoom - 0.125);
        } else if (mouse_wheel_up()) {
            self.zoom = min(4.00, self.zoom + 0.125);
        }
        if (mouse_check_button_pressed(mb_left)) {
            var spacing = 12;
            ds_list_add(obj_main.locations, new Location((mx div spacing) * spacing / self.zoom, (my div spacing) * spacing / self.zoom));
        }
    }, function() {
        self.zoom = 1;
        self.map_x = 0;
        self.map_y = 0;
]);