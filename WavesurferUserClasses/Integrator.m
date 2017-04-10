classdef Integrator < ws.UserClass
    properties(Access=protected)
        Displacement;
        Figure;
        Axes;
        Plot;
        MaxSamples;
    end
    
    methods(Access=public)
        function self = Integrator(model)
            self.Figure = figure('Position',[100 100 800 600]);
            self.Axes = subplot(1,1,1); % lol
            self.Displacement = [];
            self.MaxSamples = model.Parent.Acquisition.SampleRate;
        end
        
        % these are called in the frontend process
        function startingRun(self,wsModel,eventName)
            self.Displacement = 0;
            cla(self.Axes);
            self.Plot = plot(0,0);
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
            analogData = wsModel.Acquisition.getLatestAnalogData();
            v = analogData(:,2); % TODO : choose channel
            d = cumsum(v-mean(v)) + self.Displacement;
            
            x = get(self.Plot,'XData');
            y = get(self.Plot,'YData');
            
            x = [x x(end)+(1:numel(d))/self.MaxSamples];
            y = [y d'];
            n = numel(y);
            extra = n-self.MaxSamples;
            
            if extra > 0
                x(1:extra) = [];
                y(1:extra) = [];
            end
                
            set(self.Plot,'XData',x,'YData',y);
            
            self.Displacement = d(end);
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