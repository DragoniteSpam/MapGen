gml_release_mode(true);

self.container = new EmuCore(0, 0, window_get_width(), window_get_height());

enum EMapModes {
    DEFAULT,
    NAVMESH,
    AQUILA
}

var ew = 320;
var eh = 32;

self.map_sprite = -1;
self.locations = [];
/// {struct.Location|undefined}
self.active_location = undefined;
/// {struct.Location|undefined}
self.hover_location = undefined;
self.location_placing = false;

self.refresh_list = true;

self.settings = {
    map_mode: EMapModes.DEFAULT,
    
    draw_navmesh_barycenters: false,
    
    export_relative_coordinates: true,
    export_names: true,
    export_summaries: true,
    export_categories: true,
    export_locations: true,
    export_navmesh: true,
};

self.navmesh = new Navmesh();
self.aquila = new AquilaContainer();

try {
    self.map_sprite = sprite_add(MAP_IN_STORAGE, 0, false, false, 0, 0);
} catch (e) {
    show_debug_message("Couldn't load the stashed map file: {0}", e.message);
}

try {
    var buffer = buffer_load(SETTINGS_FILE);
    var json = json_parse(buffer_read(buffer, buffer_text));
    self.settings.export_relative_coordinates = json[$ "export_relative_coordinates"] ?? self.settings.export_relative_coordinates;
    self.settings.export_names = json[$ "export_names"] ?? self.settings.export_names;
    self.settings.export_summaries = json[$ "export_summaries"] ?? self.settings.export_summaries;
    self.settings.export_categories = json[$ "export_categories"] ?? self.settings.export_categories;
    self.settings.draw_navmesh_barycenters = json[$ "draw_navmesh_barycenters"] ?? self.settings.draw_navmesh_barycenters;
    self.settings.export_locations = json[$ "export_locations"] ?? self.settings.export_locations;
    self.settings.export_navmesh = json[$ "export_navmesh"] ?? self.settings.export_navmesh;
    buffer_delete(buffer);
} catch (e) {
    show_debug_message("Couldn't load the settings file: {0}", e.message);
}

self.PurgeActiveLocation = function() {
    self.active_location.DisconnectAll();
    self.navmesh.RemoveAllNodesContaining(self.active_location);
    array_delete(self.locations, array_get_index(self.locations, self.active_location), 1);
    self.aquila.CancelTravel();
    self.active_location = undefined;
};

self.ShowSaveDialog = function() {
    static last_file_ext = "";
    var save_filter = "";
    switch (last_file_ext) {
        case ".json":
            save_filter = "JSON files|*.json|Binary Map Connection files|*.navmesh|Any valid connection files|*.json;*.navmesh";
            break;
        case ".navmesh":
            save_filter = "Binary Map Connection files|*.navmesh|Any valid connection files|*.json;*.navmesh|JSON files|*.json";
            break;
        default:
            save_filter = "Any valid connection files|*.json;*.navmesh|JSON files|*.json|Binary Map Connection files|*.navmesh";
            break;
    }
    
    var filename = get_save_filename(save_filter, "connections.json");
    try {
        switch (filename_ext(filename))  {
            case ".json":
                last_file_ext = filename_ext(filename);
                obj_main.Export(filename);
                break;
            case ".navmesh":
                last_file_ext = filename_ext(filename);
                obj_main.ExportBin(filename);
                break;
        }
    } catch (e) {
        show_debug_message("Could not save the map data: {0}", e.message);
        show_debug_message(e.longMessage);
    }
};

self.ShowLoadDialog = function() {
    var filename = get_open_filename("JSON files|*.json", "connections.json");
    if (filename != "") {
        try {
            obj_main.Import(filename);
        } catch (e) {
            show_debug_message("Could not load the map data: {0}", e.message);
            show_debug_message(e.longMessage);
        }
    }
};

self.ShowImportImageDialog = function() {
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
};

self.SaveSettings = function() {
    try {
        var json = json_stringify(self.settings);
        var buffer = buffer_create(string_byte_length(json), buffer_fixed, 1);
        buffer_write(buffer, buffer_text, json);
        buffer_save_ext(buffer, SETTINGS_FILE, 0, buffer_tell(buffer));
        buffer_delete(buffer);
    } catch (e) {
        show_debug_message("Couldn't save the settings file: {0}", e.message);
    }
};

self.SetActiveLocation = function(location) {
    self.active_location = location;
    self.location_placing = true;
    self.container.Refresh();
};

self.container.AddContent([
    new EmuButton(32, EMU_AUTO, ew, eh, "Import Image", self.ShowImportImageDialog),
    new EmuButton(32, EMU_AUTO, ew / 2, eh, "Save", self.ShowSaveDialog),
    new EmuButton(32 + ew / 2, EMU_INLINE, ew / 2, eh, "Load", self.ShowLoadDialog),
    new EmuButton(32, EMU_AUTO, ew, eh, "Clear", function() {
        obj_main.Clear();
    }),
    new EmuList(32, EMU_AUTO, ew, eh, "Locations:", eh, 10, function() {
        if (!obj_main.refresh_list) return;
        if (!self.root) return;
        obj_main.refresh_list = false;
        obj_main.active_location = self.GetSelectedItem();
        self.root.Refresh();
        obj_main.refresh_list = true;
    })
        .SetCallbackDouble(function() {
            self.GetSibling("MORE").callback();
        })
        .SetUpdate(function() {
            var other_content_height = self.GetSibling("OPTIONS").y + self.GetSibling("OPTIONS").height - self.GetHeight() + self.root.element_spacing_y * 4;
            self.slots = (display_get_gui_height() - other_content_height) div self.height;
        })
        .SetCallbackDouble(function() {
            self.GetSibling("MORE").callback();
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
            self.Select(array_get_index(obj_main.locations, location), true);
        })
        .SetID("LOCATION LIST"),
    new EmuInput(32, EMU_AUTO, ew, eh, "Name:", "", "location name", 100, E_InputTypes.STRING, function() {
        if (obj_main.active_location) {
            obj_main.active_location.name = self.value;
        }
    })
        .SetUpdate(function() {
            var previous = self.GetSibling("LOCATION LIST");
            self.y = previous.y + previous.GetHeight() + self.root.element_spacing_y;
        })
        .SetInteractive(false)
        .SetRefresh(function() {
            self.SetInteractive(!!obj_main.active_location);
            if (!obj_main.active_location) return;
            self.SetValue(obj_main.active_location.name);
        })
        .SetID("LOCATION NAME"),
    new EmuCheckbox(32, EMU_AUTO, ew, eh, "Locked?", true, function() {
        obj_main.active_location.locked = self.value;
    })
        .SetUpdate(function() {
            var previous = self.GetSibling("LOCATION NAME");
            self.y = previous.y + previous.GetHeight() + self.root.element_spacing_y;
        })
        .SetInteractive(false)
        .SetRefresh(function() {
            self.SetInteractive(!!obj_main.active_location);
            if (!obj_main.active_location) return;
            self.SetValue(obj_main.active_location.locked);
        })
        .SetID("LOCATION LOCKED"),
    new EmuButton(32, EMU_AUTO, ew, eh, "More...", function() {
        var dialog = new EmuDialog(560, 320, "More settings: " + string(obj_main.active_location.name));
        var ew = dialog.width - 64;
        var eh = 32;
        // if you double-click the list the "close" button might spawn on top of the list
        dialog.x += 240;
        dialog.AddContent([
            new EmuCheckbox(32, EMU_AUTO, ew, eh, "Locked?", obj_main.active_location.locked, function() {
                obj_main.active_location.locked = self.value;
            })
                .SetID("LOCK"),
            new EmuInput(32, EMU_AUTO, ew, eh, "Description:", obj_main.active_location.summary, "A brief description of the location", 250, E_InputTypes.STRING, function() {
                obj_main.active_location.summary = self.value;
            })
                .SetInputBoxPosition(160, 0)
                .SetID("SUMMARY"),
            new EmuInput(32, EMU_AUTO, ew, eh, "Category:", obj_main.active_location.category, "The category that the location belongs in", 250, E_InputTypes.STRING, function() {
                obj_main.active_location.category = self.value;
            })
                .SetInputBoxPosition(160, 0)
                .SetID("CATEGORY"),
        ]).AddDefaultCloseButton();
        return dialog;
    })
        .SetUpdate(function() {
            var previous = self.GetSibling("LOCATION LOCKED");
            self.y = previous.y + previous.GetHeight() + self.root.element_spacing_y;
        })
        .SetInteractive(false)
        .SetRefresh(function() {
            self.SetInteractive(!!obj_main.active_location);
            if (!obj_main.active_location) return;
        })
        .SetID("MORE"),
    new EmuButton(32, EMU_AUTO, ew, eh, "Options", function() {
        var dialog = new EmuDialog(720, 440, "MapGen Options");
        var ew = dialog.width - 64;
        var eh = 32;
        var bw = 160;
        dialog.AddContent([
            new EmuTabGroup(32, EMU_AUTO, ew, eh, 1, eh)
                .AddTabs(0, [
                    new EmuTab("Settings").AddContent([
                        new EmuCheckbox(32, EMU_AUTO, ew, eh, "Export relative coordinates?", obj_main.settings.export_relative_coordinates, function() {
                            obj_main.settings.export_relative_coordinates = self.value;
                            obj_main.SaveSettings();
                        }),
                        new EmuCheckbox(32, EMU_AUTO, ew, eh, "Export names?", obj_main.settings.export_names, function() {
                            obj_main.settings.export_names = self.value;
                            obj_main.SaveSettings();
                        }),
                        new EmuCheckbox(32, EMU_AUTO, ew, eh, "Export summaries?", obj_main.settings.export_summaries, function() {
                            obj_main.settings.export_summaries = self.value;
                            obj_main.SaveSettings();
                        }),
                        new EmuCheckbox(32, EMU_AUTO, ew, eh, "Export categories?", obj_main.settings.export_categories, function() {
                            obj_main.settings.export_categories = self.value;
                            obj_main.SaveSettings();
                        }),
                        new EmuCheckbox(32, EMU_AUTO, ew, eh, "Export locations?", obj_main.settings.export_locations, function() {
                            obj_main.settings.export_locations = self.value;
                            obj_main.SaveSettings();
                        }),
                        new EmuCheckbox(32, EMU_AUTO, ew, eh, "Export navmesh?", obj_main.settings.export_navmesh, function() {
                            obj_main.settings.export_navmesh = self.value;
                            obj_main.SaveSettings();
                        }),
                        new EmuCheckbox(32, EMU_AUTO, ew, eh, "Draw navmesh barycenters?", obj_main.settings.draw_navmesh_barycenters, function() {
                            obj_main.settings.draw_navmesh_barycenters = self.value;
                            obj_main.SaveSettings();
                        })
                    ]),
                    new EmuTab("Credits").AddContent([
                        new EmuButton(0, EMU_AUTO, bw, eh, "Drago", function() {
                            url_open("https://dragonite.itch.io/");
                        }),
                        new EmuText(bw, EMU_INLINE, ew, eh, "Written by [rainbow]a weird dragon bird wizard thing[/rainbow]"),
                        new EmuButton(0, EMU_AUTO, bw, eh, "Emu", function() {
                            url_open("https://dragonite.itch.io/emu");
                        }),
                        new EmuText(bw, EMU_INLINE, ew, eh, "My UI system"),
                        new EmuButton(0, EMU_AUTO, bw, eh, "Scribble", function() {
                            url_open("https://github.com/JujuAdams/Scribble");
                        }),
                        new EmuText(bw, EMU_INLINE, ew, eh, "A text renderer by Juju Adams [spr_juju_inline]"),
                        new EmuButton(0, EMU_AUTO, bw, eh, "Navmesh", function() {
                            url_open("https://marketplace.yoyogames.com/assets/8245/snidrs-navigation-mesh");
                        }),
                        new EmuText(bw, EMU_INLINE, ew, eh, "General-purpose nagivation meshes by TheSnidr"),
                        new EmuButton(0, EMU_AUTO, bw, eh, "Aquila", function() {
                            url_open("https://dragonite.itch.io/aquila");
                        }),
                        new EmuText(bw, EMU_INLINE, ew, eh, "General-purpose A* pathfinding by me"),
                        
                        new EmuText(0, EMU_AUTO, ew, eh, "Program icon is based on Map by Andi Nur Abdillah from NounProject.com"),
                    ])
                ])
        ]).AddDefaultCloseButton();
        return dialog;
    })
        .SetUpdate(function() {
            var previous = self.GetSibling("MORE");
            self.y = previous.y + previous.GetHeight() + self.root.element_spacing_y;
        })
        .SetID("OPTIONS"),
    new EmuRadioArray(32 + 32 + ew, EMU_BASE, 960, 32, "Editing mode:", EMapModes.DEFAULT, function() {
        obj_main.settings.map_mode = self.value;
        obj_main.navmesh.ExitEditorMode();
    })
        .AddOptions(["Node Placement", "Navmesh Editing", "Aquila (Nodal A*)"])
        .SetColumns(1, ew),
    new EmuRenderSurface(32 + 32 + ew, EMU_AUTO, 960, 656, function(mx, my) {
        draw_clear(c_black);
        if (sprite_exists(obj_main.map_sprite)) {
            draw_sprite_ext(obj_main.map_sprite, 0, self.map_x, self.map_y, self.zoom, self.zoom, 0, c_white, 1);
        }
        
        obj_main.navmesh.Render(self.zoom, self.map_x, self.map_y, mx, my);
        
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
        
        switch (obj_main.settings.map_mode) {
            case EMapModes.DEFAULT:
                draw_set_alpha(0.75);
                draw_rectangle_colour(0, 0, self.width, 32, c_white, c_white, c_white, c_white, false);
                draw_set_alpha(1);
                draw_text_colour(16, 16, "Click to add a location; ctrl+click to connect/disconnect locations; enter resets the camera", c_black, c_black, c_black, c_black, 1);
                
                draw_set_alpha(0.75);
                draw_rectangle_colour(self.width - 144, self.height - 64, self.width, self.height - 33, c_white, c_white, c_white, c_white, false);
                draw_set_alpha(1);
                draw_text_colour(self.width - 128, self.height - 48, string("Nodes: {0}", array_length(obj_main.locations)), c_black, c_black, c_black, c_black, 1);
                break;
            case EMapModes.NAVMESH:
                obj_main.navmesh.RenderTravel(self.zoom, self.map_x, self.map_y);
                draw_set_alpha(0.75);
                draw_rectangle_colour(0, 0, self.width, 64, c_white, c_white, c_white, c_white, false);
                draw_set_alpha(1);
                draw_text_colour(16, 16, "Click on a node to create a navmesh triangle; ctrl+click on a triangle to subdivide a triangle at that point", c_black, c_black, c_black, c_black, 1);
                draw_text_colour(16, 48, "Right click somewhere on the graph to traverse", c_black, c_black, c_black, c_black, 1);
                
                if (obj_main.navmesh.last_build_time != -1) {
                    draw_set_alpha(0.75);
                    draw_rectangle_colour(0, self.height - 64, 360, self.height, c_white, c_white, c_white, c_white, false);
                    draw_set_alpha(1);
                    draw_text_colour(16, self.height - 48, string("Last build time: {0} ms", obj_main.navmesh.last_build_time), c_black, c_black, c_black, c_black, 1);
                    draw_text_colour(16, self.height - 16, string("Last navigation time: {0} ms", obj_main.navmesh.last_navigation_time), c_black, c_black, c_black, c_black, 1);
                }
                
                draw_set_alpha(0.75);
                draw_rectangle_colour(self.width - 144, self.height - 64, self.width, self.height - 33, c_white, c_white, c_white, c_white, false);
                draw_set_alpha(1);
                draw_text_colour(self.width - 128, self.height - 48, string("Tris: {0}", array_length(obj_main.navmesh.triangles)), c_black, c_black, c_black, c_black, 1);
                break;
            case EMapModes.AQUILA:
                obj_main.aquila.RenderTravel(self.zoom, self.map_x, self.map_y);
                
                draw_set_alpha(0.75);
                draw_rectangle_colour(0, 0, self.width, 64, c_white, c_white, c_white, c_white, false);
                draw_set_alpha(1);
                draw_text_colour(16, 16, "Click on a node to traverse the graph", c_black, c_black, c_black, c_black, 1);
                
                if (obj_main.aquila.last_build_time != -1) {
                    draw_set_alpha(0.75);
                    draw_rectangle_colour(0, self.height - 64, 360, self.height, c_white, c_white, c_white, c_white, false);
                    draw_set_alpha(1);
                    draw_text_colour(16, self.height - 48, string("Last build time: {0} ms", obj_main.aquila.last_build_time), c_black, c_black, c_black, c_black, 1);
                    draw_text_colour(16, self.height - 16, string("Last navigation time: {0} ms", obj_main.aquila.last_navigation_time), c_black, c_black, c_black, c_black, 1);
                }
                
                draw_set_alpha(0.75);
                draw_rectangle_colour(self.width - 144, self.height - 64, self.width, self.height - 33, c_white, c_white, c_white, c_white, false);
                draw_set_alpha(1);
                draw_text_colour(self.width - 128, self.height - 48, string("Nodes: {0}", array_length(obj_main.locations)), c_black, c_black, c_black, c_black, 1);
                break;
        }
        
        draw_set_alpha(0.75);
        draw_rectangle_colour(self.width - 144, self.height - 32, self.width, self.height, c_white, c_white, c_white, c_white, false);
        draw_set_alpha(1);
        draw_text_colour(self.width - 128, self.height - 16, string("{0}, {1}", floor(local_to_map_space(mx, self.map_x, self.zoom)), floor(local_to_map_space(my, self.map_y, self.zoom))), c_black, c_black, c_black, c_black, 1);
    }, function(mx, my) {
        self.width = display_get_gui_width() - self.x - 32;
        self.height = display_get_gui_height() - self.y - 32;
        
        if (!self.isActiveDialog()) return;
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
        
        switch (obj_main.settings.map_mode) {
            case EMapModes.DEFAULT:
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
                if (mx >= 0 && my >= 0 && mx <= self.width && my <= self.height) {
                    if (obj_main.active_location && (keyboard_check_pressed(KEY_DELETE) || keyboard_check_pressed(KEY_DELETE_ALT))) {
                        obj_main.PurgeActiveLocation();
                        obj_main.container.Refresh();
                    }
                }
                break;
            case EMapModes.NAVMESH:
                if (mx >= 0 && my >= 0 && mx <= self.width && my <= self.height) {
                    if (obj_main.navmesh.relevant_triangle && (keyboard_check_pressed(KEY_DELETE) || keyboard_check_pressed(KEY_DELETE_ALT))) {
                        obj_main.navmesh.Delete(obj_main.navmesh.relevant_triangle);
                        obj_main.navmesh.relevant_triangle = undefined;
                    }
                }
                break;
            case EMapModes.AQUILA:
                // no modifications are made in this mode
                break;
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
        }
        if (keyboard_check_pressed(KEY_RESET_MAP)) {
            self.zoom = 1;
            self.map_x = 0;
            self.map_y = 0;
            self.panning = false;
            self.pan_x = 0;
            self.pan_y = 0;
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

self.Export = function(filename, force_save_attributes = false) {
    var output = {
        relative: self.settings.export_relative_coordinates && sprite_exists(self.map_sprite),
        full_size: {
            w: (self.settings.export_relative_coordinates && sprite_exists(self.map_sprite) ? sprite_get_width(self.map_sprite) : 1),
            h: (self.settings.export_relative_coordinates && sprite_exists(self.map_sprite) ? sprite_get_height(self.map_sprite) : 1),
        },
        settings: {
            export_relative_coordinates: self.settings.export_relative_coordinates,
            export_names: self.settings.export_names,
            export_summaries: self.settings.export_summaries,
            export_categories: self.settings.export_categories,
            export_locations: self.settings.export_locations,
            export_navmesh: self.settings.export_navmesh,
        },
    };
    
    if (self.settings.export_navmesh || force_save_attributes) {
        output.locations = array_create(array_length(self.locations));
    }
    
    if (self.settings.export_navmesh || force_save_attributes) {
        output.navmesh = self.navmesh.ExportJSON();
    }
    
    if (self.settings.export_navmesh || force_save_attributes) {
        var dwidth = 1 / output.full_size.w;
        var dheight = 1 / output.full_size.h;
        
        for (var i = 0, n = array_length(self.locations); i < n; i++) {
            self.locations[i].export_index = i;
        }
        
        for (var i = 0, n = array_length(self.locations); i < n; i++) {
            var source = self.locations[i];
            var written = {
                x: source.x * dwidth,
                y: source.y * dheight,
                locked: source.locked,
                connections: array_create(variable_struct_names_count(source.connections)),
            };
            
            if (output.settings.export_names || force_save_attributes)
                written.name = source.name;
            if (output.settings.export_summaries || force_save_attributes)
                written.summary = source.summary;
            if (output.settings.export_categories || force_save_attributes)
                written.category = source.category;
            
            var connection_keys = variable_struct_get_names(source.connections);
            for (var j = 0, n2 = array_length(connection_keys); j < n2; j++) {
                written.connections[j] = source.connections[$ connection_keys[j]].export_index;
            }
            output.locations[i] = written;
        }
    }
    
    var buffer = buffer_create(1000, buffer_grow, 1);
    buffer_write(buffer, buffer_text, json_stringify(output));
    buffer_save_ext(buffer, filename, 0, buffer_tell(buffer));
    buffer_delete(buffer);
    
    show_debug_message("Saved json output")
};

self.ExportBin = function(filename) {
    var header = {
        version: 0,
        relative: self.settings.export_relative_coordinates && sprite_exists(self.map_sprite),
        full_size: {
            w: (self.settings.export_relative_coordinates && sprite_exists(self.map_sprite) ? sprite_get_width(self.map_sprite) : 1),
            h: (self.settings.export_relative_coordinates && sprite_exists(self.map_sprite) ? sprite_get_height(self.map_sprite) : 1),
        },
        settings: {
            export_relative_coordinates: self.settings.export_relative_coordinates,
            export_names: self.settings.export_names,
            export_summaries: self.settings.export_summaries,
            export_categories: self.settings.export_categories,
            export_locations: self.settings.export_locations,
            export_navmesh: self.settings.export_navmesh,
        },
    };
    
    var buffer = buffer_create(1000, buffer_grow, 1);
    buffer_write(buffer, buffer_string, json_stringify(header));
    
    if (self.settings.export_locations) {
        var dwidth = 1 / header.full_size.w;
        var dheight = 1 / header.full_size.h;
        
        var output_locations = array_create(array_length(self.locations));
        
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
                summary: source.summary,
                category: source.category,
            };
            var connection_keys = variable_struct_get_names(source.connections);
            for (var j = 0, n2 = array_length(connection_keys); j < n2; j++) {
                written.connections[j] = source.connections[$ connection_keys[j]].export_index;
            }
            output_locations[i] = written;
        }
        
        buffer_write(buffer, buffer_s32, array_length(output_locations));
        for (var i = 0, n = array_length(output_locations); i < n; i++) {
            var location = output_locations[i];
            buffer_write(buffer, buffer_f64, location.x);
            buffer_write(buffer, buffer_f64, location.y);
            buffer_write(buffer, buffer_bool, location.locked);
            
            if (header.settings.export_names)
                buffer_write(buffer, buffer_string, location.name);
            if (header.settings.export_summaries)
                buffer_write(buffer, buffer_string, location.summary);
            if (header.settings.export_categories)
                buffer_write(buffer, buffer_string, location.category);
            
            buffer_write(buffer, buffer_s32, array_length(location.connections));
            for (var j = 0, n2 = array_length(location.connections); j < n2; j++) {
                buffer_write(buffer, buffer_s32, location.connections[j]);
            }
        }
    }
    
    if (self.settings.export_navmesh) {
        var navmesh = self.navmesh.GetBinary();
        var navmesh_size = buffer_get_size(navmesh);
        buffer_write(buffer, buffer_u32, navmesh_size);
        buffer_resize(buffer, buffer_get_size(buffer) + navmesh_size);
        buffer_copy(navmesh, 0, navmesh_size, buffer, buffer_tell(buffer));
        buffer_seek(buffer, buffer_seek_relative, navmesh_size);
        buffer_delete(navmesh);
    }
    
    buffer_save_ext(buffer, filename, 0, buffer_tell(buffer));
    buffer_delete(buffer);
    
    show_debug_message("Saved binary output")
};

self.Import = function(filename) {
    var buffer = buffer_load(filename);
    var data = json_parse(buffer_read(buffer, buffer_text));
    buffer_delete(buffer);
    
    self.Clear();
    for (var i = 0, n = array_length(data.locations); i < n; i++) {
        var source = data.locations[i];
        var location = new Location(source.x * data.full_size.w, source.y * data.full_size.h);
        location.name = source[$ "name"] ?? location.name;
        location.locked = source.locked;
        location.summary = source[$ "summary"] ?? location.summary;
        location.category = source[$ "category"] ?? location.category;
        array_push(self.locations, location);
    }
    for (var i = 0, n = array_length(self.locations); i < n; i++) {
        for (var j = 0, n2 = array_length(data.locations[i].connections); j < n2; j++) {
            self.locations[i].Connect(self.locations[data.locations[i].connections[j]]);
        }
    }
    
    var navmesh = data[$ "navmesh"];
    if (navmesh) {
        for (var i = 0, n = array_length(navmesh.triangles); i < n; i++) {
            var triangle = navmesh.triangles[i];
            self.navmesh.AddTriangle(self.locations[triangle[0]], self.locations[triangle[1]], self.locations[triangle[2]]);
        }
    }
    self.navmesh.relevant_triangle = undefined;
};

self.Clear = function() {
    self.navmesh = new Navmesh();
    array_resize(obj_main.locations, 0);
    obj_main.active_location = undefined;
    obj_main.hover_location = undefined;
};

if (file_exists(GRAPH_IN_STORAGE)) {
    try {
        self.Import(GRAPH_IN_STORAGE);
    } catch (e) {
        show_debug_message("Couldn't load the autosaved map: {0}", e.message);
    }
}