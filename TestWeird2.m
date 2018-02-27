classdef TestWeird2
    properties
        Test
    end
    
    methods
        function self = TestWeird2()
            self.Test = @(x) @(y) 1;
        end
    end
end