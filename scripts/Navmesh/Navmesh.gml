function Navmesh() constructor {
    self.triangles = [];
    
    self.AddTriangle = function() {
        var tri = new NavmeshTriangle();
        array_push(self.triangles, tri);
        return tri;
    };
    
    self.Top = function() {
        return self.triangles[array_length(self.triangles) - 1];
    };
    
    self.Pop = function() {
        self.Delete(array_length(self.triangles) - 1);
    };
    
    self.Delete = function(index) {
        if (index >= 0 && index < array_length(self.triangles)) {
            array_delete(self.triangles, index, 1);
        }
    };
    
    self.HasTriangleWaiting = function() {
        var top = self.Top();
        return !top.a || !top.b || !top.c;
    };
    
    self.ExitEditorMode = function() {
        if (self.HasTriangleWaiting()) {
            self.Pop();
        }
    };
}

function NavmeshTriangle() constructor {
    self.a = undefined;
    self.b = undefined;
    self.c = undefined;
}