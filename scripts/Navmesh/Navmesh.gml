function Navmesh() constructor {
    self.triangles = [];
    self.relevant_triangle = undefined;
    
    self.AddTriangle = function() {
        var tri = new NavmeshTriangle();
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
    
    self.Delete = function(index) {
        if (index >= 0 && index < array_length(self.triangles)) {
            array_delete(self.triangles, index, 1);
        }
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
            self.triangles[i].Render(zoom, map_x, map_y, mx, my);
        }
        draw_primitive_end();
    };
}

function NavmeshTriangle() constructor {
    self.vertices = [];
    
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
    
    self.Render = function(zoom, map_x, map_y, mx, my) {
        static positions = array_create(3);
        var cx = 0;
        var cy = 0;
        for (var i = 0, n = array_length(self.vertices); i < n; i++) {
            var position = self.vertices[i].RenderNavmesh(zoom, map_x, map_y, mx, my);
            cx += position.x;
            cy += position.y;
            positions[i] = position;
        }
        
        if (obj_main.settings.draw_navmesh_barycenters) {
            if (self.IsComplete()) {
                cx /= 3;
                cy /= 3;
                for (var i = 0; i < 3; i++) {
                    draw_line_colour(cx, cy, positions[i].x, positions[i].y, c_navmesh_fill, c_navmesh_fill);
                }
            }
        }
    };
}