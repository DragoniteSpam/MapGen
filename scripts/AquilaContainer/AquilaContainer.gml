function AquilaContainer() constructor {
    self.last_build_time = -1;
    self.last_navigation_time = -1;
    
    self.start = undefined;
    self.finish = undefined;
    
    self.SetStart = function(start) {
        self.start = start;
        return self;
    };
    
    self.SetFinish = function(finish) {
        self.finish = finish;
        return self;
    };
    
    self.Navigate = function() {
        
    };
}