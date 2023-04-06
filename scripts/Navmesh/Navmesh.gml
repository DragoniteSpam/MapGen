function Navmesh() constructor {
    self.editor_index = -1;
    self.triangles = [];
    
    self.AddTriangle = function() {
        var tri = new NavmeshTriangle();
        array_push(self.triangles, tri);
        return tri;
    };
    
    self.Top = function() {
        return self.triangles[array_length(self.triangles) - 1];
    };
}

function NavmeshTriangle() constructor {
    self.a = undefined;
    self.b = undefined;
    self.c = undefined;
}