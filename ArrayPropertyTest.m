classdef ArrayPropertyTest
    properties
        TheArray
    end
    
    methods
        function self = ArrayPropertyTest
            self.TheArray = 1:10;
        end
        
        function array = get.TheArray(self)
            disp('hello, beautiful world!');
            array = self.TheArray;
        end
        
        function self = set.TheArray(self, array)
            disp('goodbye, cruel world!');
            self.TheArray = array;
        end
    end
end
        