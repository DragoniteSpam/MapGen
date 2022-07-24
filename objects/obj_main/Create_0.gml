self.container = new EmuCore(0, 0, window_get_width(), window_get_height());

var ew = 320;
var eh = 32;

self.map_sprite = -1;

self.container.AddContent([
    new EmuText(32, EMU_BASE, ew, eh, "[c_aqua]MapGen"),
    new EmuButton(32, EMU_AUTO, ew, eh, "Import Image", function() {
        var path = get_open_filename("Image files|*.png;*.bmp", "map.png");
        if (file_exists(path)) {
            try {
                var sprite = sprite_add(path, 0, false, false, 0, 0);
                if (sprite_exists(obj_main.map_sprite)) {
                    sprite_delete(obj_main.map_sprite);
                }
                obj_main.map_sprite = sprite;
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
    new EmuRenderSurface(32 + 32 + ew, EMU_BASE, 640, 640, function() {
        draw_clear(c_black);
        if (sprite_exists(obj_main.map_sprite)) {
            draw_sprite(obj_main.map_sprite, 0, 0, 0);
        }
    }, function() {
    }, function() { })
]);