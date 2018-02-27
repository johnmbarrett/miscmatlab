classdef FakeStimulation < handle
    properties(Dependent=true)
        DigitalOutputStateIfUntimed
    end
    
    properties(Access=protected)
        DigitalOutputStateIfUntimed_
    end
    
    methods
        function s = prettyPrintBoolean(~,b)
            if b
                s = 'HIGH';
            else
                s = 'LOW';
            end
        end
        
        function s = get.DigitalOutputStateIfUntimed(self)
            s = self.DigitalOutputStateIfUntimed_;
        end
        
        function set.DigitalOutputStateIfUntimed(self,s)
            fprintf('Reward pin is %s\tPunishmnet pin is %s\n',self.prettyPrintBoolean(s(1)),self.prettyPrintBoolean(s(2)));
            self.DigitalOutputStateIfUntimed_ = s;
        end
    end
end