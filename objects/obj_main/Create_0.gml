#macro MAP_IN_STORAGE       "map.png"

self.container = new EmuCore(0, 0, window_get_width(), window_get_height());

var ew = 320;
var eh = 32;

self.map_sprite = -1;
self.locations = [];
self.active_location = undefined;
self.hover_location = undefined;

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
    })
        .SetInteractive(false)
        .SetRefresh(function() {
            self.SetInteractive(!!obj_main.active_location);
            if (!obj_main.active_location) return;
        }),
    new EmuInput(32, EMU_AUTO, ew, eh, "Name:", "", "location name", 100, E_InputTypes.STRING, function() {
    })
        .SetInteractive(false)
        .SetRefresh(function() {
            self.SetInteractive(!!obj_main.active_location);
            if (!obj_main.active_location) return;
        }),
    new EmuCheckbox(32, EMU_AUTO, ew, eh, "Locked?", true, function() {
    })
        .SetInteractive(false)
        .SetRefresh(function() {
            self.SetInteractive(!!obj_main.active_location);
            if (!obj_main.active_location) return;
        }),
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
            obj_main.locations[i].Render(self.zoom, self.map_x, self.map_y, mx, my);
        }
    }, function(mx, my) {
        if (mouse_wheel_down()) {
            self.zoom = max(0.25, self.zoom - 0.125);
        } else if (mouse_wheel_up()) {
            self.zoom = min(4.00, self.zoom + 0.125);
        }
        var spacing = 1;
        var cmx = (mx div spacing) * spacing / self.zoom;
        var cmy = (my div spacing) * spacing / self.zoom;
        if (mouse_check_button_pressed(mb_left)) {
            if (!obj_main.hover_location && (!obj_main.active_location || (obj_main.active_location && !obj_main.active_location.MouseIsOver(self.zoom, self.map_x, self.map_y, mx, my)))) {
                obj_main.active_location = new Location(cmx, cmy);
                self.location_placing = true;
                array_push(obj_main.locations, obj_main.active_location);
            }
            // if you click on something this frame it'll be re-registered
            // when you iterate over the locations later
            //obj_main.active_location = undefined;
        }
        if (mouse_check_button(mb_left)) {
            if (obj_main.active_location && self.location_placing) {
                obj_main.active_location.x = cmx;
                obj_main.active_location.y = cmy;
            }
        } else {
            self.location_placing = false;
        }
        if (mx >= 0 && my >= 0 && mx <= self.width && my <= self.height && mouse_check_button_pressed(mb_middle)) {
            self.panning = true;
            self.pan_x = mx;
            self.pan_y = my;
        }
        if (mouse_check_button(mb_middle)) {
            self.map_x += mx - self.pan_x;
            self.map_y += my - self.pan_y;
            self.pan_x = mx;
            self.pan_y = my;
        } else {
            self.panning = false;
        }
    }, function() {
        self.zoom = 1;
        self.map_x = 0;
        self.map_y = 0;
        self.panning = false;
        self.pan_x = 0;
        self.pan_y = 0;
        self.location_placing = false;
    })
        .SetID("RS")
]);