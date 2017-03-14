classdef DeflectionTask < ws.UserClass
    properties(Access=protected)
        BaselineMean;
        BaselineSTD;
        Ones;
        PunishmentFile;
        RewardFile;
        SampleRate;
        StimFile;
        StimStartSeconds;
        Zeros;
        
        IsDisabled;
        IsOddNumberedSweep;
    end
    
    methods(Access=public)
        function self = DeflectionTask(model)
            self.IsDisabled = ~isa(model,'ws.WavesurferModel');
            
            if self.IsDisabled
                return
            end
            
            self.SampleRate = model.Acquisition.SampleRate;
            self.Ones = ones(floor(0.1*self.SampleRate),1);
            self.Zeros = zeros(floor(0.1*self.SampleRate),1);
            
            self.RewardFile = 'reward.wav';
            self.PunishmentFile = 'punishment.wav';
            self.StimFile = 'stimulus.wav';
        end
        
        % these are called in the frontend process
        function startingRun(self,wsModel,eventName)
            audiowrite(self.RewardFile,self.Zeros,self.SampleRate);
            audiowrite(self.PunishmentFile,self.Zeros,self.SampleRate);
            
            self.IsOddNumberedSweep = false;
        end
        
        function completingRun(self,wsModel,eventName)
        end
        
        function stoppingRun(self,wsModel,eventName)
        end
        
        function abortingRun(self,wsModel,eventName)
        end
        
        function startingSweep(self,wsModel,eventName) 
            self.IsOddNumberedSweep = ~self.IsOddNumberedSweep;
            
            if ~self.IsOddNumberedSweep
                self.StimStartSeconds = 0.21+0.3*rand(1);
                audiowrite(self.StimFile,[zeros(floor(self.StimStartSeconds*self.SampleRate),1);ones(floor(0.001*self.SampleRate),1)],self.SampleRate);
            end
        end
        
        function completingSweep(self,wsModel,eventName)   
            if self.IsDisabled
                return
            end
            
            if self.IsOddNumberedSweep
                baseline = wsModel.Acquisition.getAnalogDataFromCache();
                self.BaselineMean = mean(baseline);
                self.BaselineSTD = std(baseline);
                return
            end
            
            deflection = wsModel.Acquisition.getAnalogDataFromCache();
            Z = abs((deflection-self.BaselineMean)/self.BaselineSTD);
            
            stimStartSamples = floor(self.StimStartSeconds*self.SampleRate);
            stimDurationSeconds = 0.06;
            stimDurationSamples = stimDurationSeconds*self.SampleRate;
            
            % TODO : this will prevent preemptions just before the stimulus
            % being detected as preemptions
            Z(stimStartSamples+(1:stimDurationSamples)) = 0; % blank out stimulus
            
            % find first time the deflection goes outside 5 S.D. of baseline
            % and stays there for at least 10ms
            N = 0.01*self.SampleRate;
            
            aboveThreshold = Z > 5; % TODO : adjustable threshold?
            reaction = true(size(aboveThreshold,1)-N+1,1);
            
            tic;
            for ii = 1:N
                reaction = reaction & aboveThreshold(ii:(end-N+ii));
            end
            toc;
            
            reaction = find(reaction,1);
            
            if isempty(reaction) % no response
                audiowrite(self.RewardFile,self.Zeros,self.SampleRate);
                audiowrite(self.PunishmentFile,self.Zeros,self.SampleRate);
            elseif reaction < stimStartSamples % response before stimulus
                 audiowrite(self.RewardFile,self.Zeros,self.SampleRate);
                 audiowrite(self.PunishmentFile,self.Ones,self.SampleRate);
            else % good response
                 audiowrite(self.RewardFile,self.Ones,self.SampleRate);
                 audiowrite(self.PunishmentFile,self.Zeros,self.SampleRate);
            end
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