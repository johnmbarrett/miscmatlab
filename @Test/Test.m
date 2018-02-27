classdef Test
    properties(Dependent=true)
        Hello
    end
    
    methods
        function self = Test()
            self.helloWorld;
        end
        
        function helpA(~)
        % HELPA This help can be found
        end
        
        helpb(~)
    end
end