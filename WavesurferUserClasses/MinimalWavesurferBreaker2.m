classdef MinimalWavesurferBreaker2 < ws.UserClass
    methods(Access=public)
        function self = MinimalWavesurferBreaker2(varargin)
            figure;
        end
        
        % these are called in the frontend process
        function startingRun(self,wsModel,eventName)
        end
        
        function completingRun(self,wsModel,eventName)
        end
        
        function stoppingRun(self,wsModel,eventName)
        end
        
        function abortingRun(self,wsModel,eventName)
        end
        
        function startingSweep(self,wsModel,eventName)        
        end
        
        function completingSweep(self,wsModel,eventName)      
        end
        
        function stoppingSweep(self,wsModel,eventName)      
        end
        
        function abortingSweep(self,wsModel,eventName)
        end
        
        function dataAvailable(self,wsModel,eventName)
        end
        
        
        % this one is called in the looper process
        function samplesAcquired(self,looper,eventName,analogData,digitalData) 
        end
        
        % these are are called in the refiller process
        function startingEpisode(self,refiller,eventName)        
        end
        
        function completingEpisode(self,refiller,eventName)    
        end
          
        function stoppingEpisode(self,refiller,eventName)      
        end
        
        function abortingEpisode(self,refiller,eventName)        
        end
    end  % methods
end  % classdef