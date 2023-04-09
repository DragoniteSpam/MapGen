function Navmesh() constructor {
    self.triangles = [];
    self.relevant_triangle = undefined;
    
    self.last_build_time = -1;
    self.last_navigation_time = -1;
    
    self.ExportJSON = function() {
        self.ExitEditorMode();
        
        var json = {
            triangles: array_create(array_length(self.triangles)),
        };
        
        for (var i = 0, n = array_length(self.triangles); i < n; i++) {
            json.triangles[i] = self.triangles[i].ExportJSON();
        }
        
        return json;
    };
    
    self.travel = {
        position: undefined,
        // this is one of snidr's returned navmesh paths - it's an array of (positions * 3) elements, with x y z stored sequentially
        path: []
    };
    
    self.SetRelevantTriangle = function(triangle) {
        self.relevant_triangle = triangle;
    };
    
    self.AddTriangle = function(a = undefined, b = undefined, c = undefined) {
        var tri = new NavmeshTriangle(a, b, c);
        array_push(self.triangles, tri);
        self.relevant_triangle = tri;
        return tri;
    };
    
    self.Empty = function() {
        return array_length(self.triangles) == 0;
    };
    
    self.Top = function() {
        if (self.Empty())
            return undefined;
        return self.triangles[array_length(self.triangles) - 1];
        
    };
    
    self.Pop = function() {
        if (self.Empty())
            return;
        self.Delete(array_length(self.triangles) - 1);
    };
    
    self.Delete = function(triangle) {
        var index = array_get_index(self.triangles, triangle);
        if (index == -1)
            return;
        array_delete(self.triangles, index, 1);
    };
    
    self.HasTriangleWaiting = function() {
        if (self.Empty()) return false;
        return self.Top().IsComplete();
    };
    
    self.ExitEditorMode = function() {
        for (var i = array_length(self.triangles) - 1; i >= 0; i--) {
            if (!self.triangles[i].IsComplete()) {
                array_delete(self.triangles, i, 1);
            }
        }
        self.relevant_triangle = undefined;
    };
    
    self.RemoveAllNodesContaining = function(node) {
        for (var i = array_length(self.triangles) - 1; i >= 0; i--) {
            if (self.triangles[i].Contains(node)) {
                if (self.relevant_triangle == self.triangles[i])
                    self.relevant_triangle = undefined;
                array_delete(self.triangles, i, 1);
            }
        }
    };
    
    self.Render = function(zoom, map_x, map_y, mx, my) {
        draw_primitive_begin(pr_trianglelist);
        for (var i = 0, n = array_length(self.triangles); i < n; i++) {
            var color = self.triangles[i] == self.relevant_triangle ? c_navmesh_fill_relevant : c_navmesh_fill;
            var alpha = self.triangles[i] == self.relevant_triangle ? c_navmesh_fill_alpha_relevant : c_navmesh_fill_alpha;
            self.triangles[i].Render(zoom, map_x, map_y, mx, my, color, alpha);
        }
        draw_primitive_end();
    };
    
    self.RenderTravel = function(zoom, map_x, map_y) {
        if (self.travel.position) {
            static spd = 4;
            
            if (array_length(self.travel.path) > 0) {
                if (array_length(self.travel.path) > 3) {
                    var dist = point_distance(self.travel.position.x, self.travel.position.y, self.travel.path[3], self.travel.path[4]);
                    var dir = point_direction(self.travel.position.x, self.travel.position.y, self.travel.path[3], self.travel.path[4]);
                    if (dist <= spd) {
                        self.travel.position.x = self.travel.path[3];
                        self.travel.position.y = self.travel.path[4];
                        array_delete(self.travel.path, 0, 3);
                    } else {
                        self.travel.position.x += spd * dcos(dir);
                        self.travel.position.y -= spd * dsin(dir);
                        self.travel.path[0] = self.travel.position.x;
                        self.travel.path[1] = self.travel.position.y;
                    }
                }
                
                draw_primitive_begin(pr_linestrip);
                for (var i = 0, n = array_length(self.travel.path); i < n; i += 3) {
                    var px = map_to_local_space(self.travel.path[i + 0], map_x, zoom);
                    var py = map_to_local_space(self.travel.path[i + 1], map_y, zoom);
                    draw_vertex_colour(px, py, c_navmesh_path_connection, 1);
                }
                draw_primitive_end();
            }
            
            var jx = map_to_local_space(self.travel.position.x, map_x, zoom);
            var jy = map_to_local_space(self.travel.position.y, map_y, zoom);
            draw_sprite(spr_juju, 0, jx, jy);
        }
    };
    
    self.SetTravelPoint = function(x, y) {
        if (!self.travel.position) {
            self.travel.position = { x: x, y: y };
            return;
        }
        
        var t_start = get_timer();
        var mesh = navmesh_create();
        
        var data = self.GetBinary();
        navmesh_add_mbuff(mesh, data, -1);
        navmesh_preprocess(mesh, 5);
        buffer_delete(data);
        
        self.last_build_time = (get_timer() - t_start) / 1000;
        
        t_start = get_timer();
        
        var path = navmesh_find_path(mesh, self.travel.position.x, self.travel.position.y, 0, x, y, 0, true);
        self.travel.path = (path == -1) ? [] : path;
        
        self.last_navigation_time = (get_timer() - t_start) / 1000;
        
        show_debug_message("Navmesh creation took {0} ms", );
        show_debug_message("Navmesh traversal took {0} ms", (get_timer() - t_start) / 1000);
        
        navmesh_destroy(mesh);
    };
    
    self.GetBinary = function() {
        var data = buffer_create(1000, buffer_grow, 1);
        
        for (var i = 0, n = array_length(self.triangles); i < n; i++) {
            var triangle = self.triangles[i];
            if (!triangle.IsComplete()) continue;
            var a = triangle.vertices[0];
            var b = triangle.vertices[1];
            var c = triangle.vertices[2];
            buffer_write(data, buffer_f32, a.x);
            buffer_write(data, buffer_f32, a.y);
            buffer_write(data, buffer_f32, 0);
            buffer_write(data, buffer_f32, b.x);
            buffer_write(data, buffer_f32, b.y);
            buffer_write(data, buffer_f32, 0);
            buffer_write(data, buffer_f32, c.x);
            buffer_write(data, buffer_f32, c.y);
            buffer_write(data, buffer_f32, 0);
        }
        
        buffer_resize(data, buffer_tell(data));
        
        return navmesh__mbuff_trim_attributes(data, 12);
    };
}

function NavmeshTriangle(a = undefined, b = undefined, c = undefined) constructor {
    self.vertices = [];
    
    self.ExportJSON = function() {
        return [
            array_get_index(obj_main.locations, self.vertices[0]),
            array_get_index(obj_main.locations, self.vertices[1]),
            array_get_index(obj_main.locations, self.vertices[2])
        ];
    };
    
    self.IsComplete = function() {
        return array_length(self.vertices) == 3;
    };
    
    self.AddVertex = function(node) {
        // if the node is already in the triangle, skip it
        for (var i = 0, n = array_length(self.vertices); i < n; i++) {
            if (self.vertices[i] == node)
                return;
        }
        
        // if the node does not have a connection to any existing vertex
        // in the triangle, skip it
        for (var i = 0, n = array_length(self.vertices); i < n; i++) {
            if (!node.IsConnected(self.vertices[i]))
                return;
        }
        
        // if all of those conditions are not met, add the node
        array_push(self.vertices, node);
    };
    
    if (a) self.AddVertex(a);
    if (b) self.AddVertex(b);
    if (c) self.AddVertex(c);
    
    self.IndexOf = function(node) {
        return array_get_index(self.vertices, node);
    };
    
    self.Contains = function(node) {
        return self.IndexOf(node) != -1;
    };
    
    self.DeleteVertex = function(node) {
        if (self.Contains(node)) {
            array_delete(self.vertices, self.IndexOf(node), 1);
        }
    };
    
    self.Subdivide = function(x, y) {
        if (!self.IsComplete())
            return;
        
        if (obj_main.navmesh.HasTriangleWaiting())
            obj_main.navmesh.Pop();
        
        var a = self.vertices[0];
        var b = self.vertices[1];
        var c = self.vertices[2];
        
        var location = new Location(x, y);
        array_push(obj_main.locations, location);
        
        location.Connect(a);
        location.Connect(b);
        location.Connect(c);
        
        obj_main.navmesh.AddTriangle(a, b, location);
        obj_main.navmesh.AddTriangle(b, c, location);
        obj_main.navmesh.AddTriangle(c, a, location);
        
        obj_main.navmesh.Delete(self);
    };
    
    self.Render = function(zoom, map_x, map_y, mx, my, color, alpha) {
        static positions = array_create(3);
        
        if (self.IsComplete()) {
            var cx = 0;
            var cy = 0;
            for (var i = 0, n = array_length(self.vertices); i < n; i++) {
                var position = self.vertices[i].RenderNavmesh(zoom, map_x, map_y, mx, my, color, alpha);
                cx += position.x;
                cy += position.y;
                positions[i] = position;
            }
            
            if (obj_main.settings.draw_navmesh_barycenters && obj_main.settings.map_mode == EMapModes.NAVMESH) {
                cx /= 3;
                cy /= 3;
                for (var i = 0; i < 3; i++) {
                    draw_line_colour(cx, cy, positions[i].x, positions[i].y, c_navmesh_fill, c_navmesh_fill);
                }
            }
            
            var abs_x = local_to_map_space(mx, map_x, zoom);
            var abs_y = local_to_map_space(my, map_y, zoom);
            
            if (obj_main.settings.map_mode == EMapModes.NAVMESH) {
                if (point_in_triangle(mx, my, positions[0].x, positions[0].y, positions[1].x, positions[1].y, positions[2].x, positions[2].y)) {
                    if (mouse_check_button_pressed(mb_left)) {
                        if (keyboard_check(vk_control)) {
                            self.Subdivide(abs_x, abs_y);
                        } else {
                            var near_corner = array_reduce(self.vertices, method({ mx: mx, my: my, map_x: map_x, map_y: map_y, zoom: zoom }, function(state, location) {
                                static closeness = sprite_get_width(spr_location) * 2;
                                return state || point_distance(self.mx, self.my, map_to_local_space(location.x, self.map_x, self.zoom), map_to_local_space(location.y, self.map_y, self.zoom)) < closeness;
                            }), false);
                            
                            if (!near_corner) {
                                obj_main.navmesh.SetRelevantTriangle(self);
                            }
                        }
                    }
                    
                    if (mouse_check_button_pressed(mb_right)) {
                        obj_main.navmesh.SetTravelPoint(abs_x, abs_y);
                    }
                }
            }
        }
    };
}