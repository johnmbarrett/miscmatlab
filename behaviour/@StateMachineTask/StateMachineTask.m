classdef StateMachineTask < ws.UserClass
    properties % TODO : decide attributes
        Time
        CurrentState
        SamplesWritten
        States
    end
    
    properties(Access=protected,Transient=true)
        Disabled
    end
    
    methods(Access=protected)
        % Allows access to protected and protected variables from
        % ws.Coding, because Wavesurfer is bad and terrible
        function out = getPropertyValue_(self, name)
            out = self.(name) ;
        end
        
        function setPropertyValue_(self, name, value)
            self.(name) = value ;
        end 
        
%         function giveFeedback(self,wsModel,noCheck,feedback)
%             wsModel.Stimulation.DigitalOutputStateIfUntimed = feedback;
%             
%             if noCheck || ~strcmp(self.ClearDigitalInputsTimer.Running,'on') % TODO : there's a sort of race condition here whereby if you reward then punish in quick succession (or vice-versa) then the punishment will only last as long as the reward had left
%                 start(self.ClearDigitalInputsTimer);
%             end
%         end
%         
%         function punish(self,wsModel,noCheck)
%             self.giveFeedback(wsModel,noCheck,[false true]);
%         end
%         
%         function reward(self,wsModel,noCheck)
%             self.giveFeedback(wsModel,noCheck,[true false]);
%         end
    end
    
    methods(Access=public)
        function encodingContainer = encodeForPersistence(self)
            encodingContainer = self.encodeForPersistence@ws.Coding();
        end
        
        function self = StateMachineTask(parent)
%             if ~isa(parent.Parent,'ws.WavesurferModel')
%                 self.Disabled = true;
%                 return
%             end
%             
%             self.Parent = parent.Parent;
%             
%             self.Disabled = false;
            
%             figureWidth = 355;
%             figureHeight = 288;
%             self.Figure = figure('Position',[100 100 figureWidth figureHeight]);
%             
%             set(self.Figure,'Name','Task Control','NumberTitle','off');
%             
%             uicontrol('Style','text','String','Threshold 1','Position',[10 figureHeight-42.5 100 25],'HorizontalAlignment','left');
%             
%             uicontrol('Style','edit','String',sprintf('%d',self.Thresholds(1)),'Position',[120 figureHeight-35 100 25],'Tag','Threshold1EditBox',...
%                 'Callback',{@(editBox,~,task) task.setThreshold(str2double(get(editBox,'String')),1) self});
%             
%             uicontrol('Style','slider','Value',self.Thresholds(1),'Position',[220 figureHeight-35 15 25], ...
%                 'Tag','Threshold1Slider','Min',-10,'Max',10,'SliderStep',[0.1/20 1/20], ...
%                 'Callback',{@(slider,~,task) task.setThreshold(get(slider,'Value'),1) self});
%             
%             threshold1ButtonGroup = uibuttongroup(self.Figure,'Units','pixels','Position',[240 figureHeight-35 110 25],'Visible','on',...
%                 'SelectionChangedFcn',{@(~,selectionData,task) task.setFixedVoltageThreshold(strcmp(selectionData.NewValue.Tag,'Threshold1VoltsRadioButton'),1) self});
%             
%             uicontrol(threshold1ButtonGroup,'Style','radiobutton','Units','pixels','Position',[5 0 50 25], ...
%                 'String','Volts','Value',self.FixedVoltageThreshold(1),'Tag','Threshold1VoltsRadioButton');
%             
%             uicontrol(threshold1ButtonGroup,'Style','radiobutton','Units','pixels','Position',[55 0 50 25], ...
%                 'String','s.d.','Value',~self.FixedVoltageThreshold(1),'Tag','Threshold1SDRadioButton');
%             
%             threshold2ButtonGroup = uibuttongroup(self.Figure,'Units','pixels','Position',[240 figureHeight-70 110 25],'Visible','on',...
%                 'SelectionChangedFcn',{@(~,selectionData,task) task.setFixedVoltageThreshold(strcmp(selectionData.NewValue.Tag,'Threshold2VoltsRadioButton'),2) self});
%             
%             uicontrol(threshold2ButtonGroup,'Style','radiobutton','Units','pixels','Position',[5 0 50 25], ...
%                 'String','Volts','Value',self.FixedVoltageThreshold(2),'Tag','Threshold2VoltsRadioButton');
%             
%             uicontrol(threshold2ButtonGroup,'Style','radiobutton','Units','pixels','Position',[55 0 50 25], ...
%                 'String','s.d.','Value',~self.FixedVoltageThreshold(2),'Tag','Threshold1SDRadioButton');
%             
%             uicontrol('Style','text','String','Threshold 2','Position',[10 figureHeight-77.5 100 25],'HorizontalAlignment','left');
%             
%             uicontrol('Style','edit','String',sprintf('%d',self.Thresholds(2)),'Position',[120 figureHeight-70 100 25],'Tag','Threshold2EditBox',...
%                 'Callback',{@(editBox,~,task) task.setThreshold(str2double(get(editBox,'String')),2) self});
%             
%             uicontrol('Style','slider','Value',self.Thresholds(2),'Position',[220 figureHeight-70 15 25], ...
%                 'Tag','Threshold2Slider','Min',-10,'Max',10,'SliderStep',[0.1/20 1/20], ...
%                 'Callback',{@(slider,~,task) task.setThreshold(get(slider,'Value'),2) self});
%             
%             uicontrol('Style','text','String','Delay Period','Position',[10 figureHeight-112.5 100 25],'HorizontalAlignment','left');
%             
%             uicontrol('Style','edit','String',sprintf('%d',self.DelayPeriod),'Position',[120 figureHeight-105 100 25],'Tag','DelayPeriodEditBox',...
%                 'Callback',{@(editBox,~,task) task.setDelayPeriod(str2double(get(editBox,'String'))) self});
%             
%             uicontrol('Style','slider','Value',self.DelayPeriod,'Position',[220 figureHeight-105 15 25], ...
%                 'Tag','DelayPeriodSlider','Min',0,'Max',3601,'SliderStep',[0.1/3601 1/3601], ...
%                 'Callback',{@(slider,~,task) task.setDelayPeriod(get(slider,'Value')) self});
%             
%             uicontrol('Style','text','String','Stim Period','Position',[10 figureHeight-147.5 100 25],'HorizontalAlignment','left');
%             
%             uicontrol('Style','edit','String',sprintf('%d',self.StimPeriod),'Position',[120 figureHeight-140 100 25],'Tag','StimPeriodEditBox',...
%                 'Callback',{@(editBox,~,task) task.setStimPeriod(str2double(get(editBox,'String'))) self});
%             
%             uicontrol('Style','slider','Value',self.StimPeriod,'Position',[220 figureHeight-140 15 25], ...
%                 'Tag','StimPeriodSlider','Min',0,'Max',3601,'SliderStep',[0.1/3601 1/3601], ...
%                 'Callback',{@(slider,~,task) task.setStimPeriod(get(slider,'Value')) self});
%             
%             uicontrol('Style','text','String','Response Period','Position',[10 figureHeight-182.5 100 25],'HorizontalAlignment','left');
%             
%             uicontrol('Style','edit','String',sprintf('%d',self.ResponsePeriod),'Position',[120 figureHeight-175 100 25],'Tag','ResponsePeriodEditBox',...
%                 'Callback',{@(editBox,~,task) task.setResponsePeriod(str2double(get(editBox,'String'))) self});
%             
%             uicontrol('Style','slider','Value',self.ResponsePeriod,'Position',[220 figureHeight-175 15 25], ...
%                 'Tag','ResponsePeriodSlider','Min',0,'Max',3601,'SliderStep',[0.1/3601 1/3601], ...
%                 'Callback',{@(slider,~,task) task.setResponsePeriod(get(slider,'Value')) self});
%             
%             uicontrol('Style','text','String','Continuous Reward','Position',[10 figureHeight-217.5 100 25],'HorizontalAlignment','left');
%             
%             uicontrol('Style','checkbox','Position',[120 figureHeight-210 25 25], ...
%                 'Value',self.ContinuousReward,'Tag','ContinuousRewardCheckBox', ...
%                 'Callback',{@(checkBox,~,task) task.setContinuousReward(logical(get(checkBox,'Value'))) self});
%             
%             uicontrol('Style','text','String','Current State','Position',[10 figureHeight-252.5 100 25],'HorizontalAlignment','left');
%             
%             uicontrol('Style','text','String',sprintf('%s',self.State),'Position',[120 figureHeight-252.5 100 25],'HorizontalAlignment','left','Tag','StateTextBox');
%             
%             uicontrol('Style','pushbutton','String','REWARD','Position',[10 figureHeight-277.5 100 25], ...
%                 'Callback',{@(~,~,task,wsModel) task.reward(wsModel,false) self parent.Parent});
%             
%             uicontrol('Style','pushbutton','String','PUNISH','Position',[120 figureHeight-277.5 100 25], ...
%                 'Callback',{@(~,~,task,wsModel) task.punish(wsModel,false) self parent.Parent});
%             
%             uicontrol('Style','text','String','Task Mode:','Position',[245 figureHeight-117.5 100 25],'HorizontalAlignment','left');
%             
%             taskModeButtonGroup = uibuttongroup(self.Figure,'Units','pixels','Position',[240 figureHeight-175 110 90],'Visible','on');
%             
%             uicontrol(taskModeButtonGroup,'Style','radiobutton','Units','pixels','Position',[5 35 100 25], ...
%                 'String','Single Lever','Value',self.SingleLeverMode,'Tag','SingleLeverRadioButton', ...
%                 'Callback',{@(radioButton,~,task) task.setSingleLeverMode(logical(get(radioButton,'Value'))) self});
%             
%             uicontrol(taskModeButtonGroup,'Style','radiobutton','Units','pixels','Position',[5 5 100 25], ...
%                 'String','Double Lever','Value',~self.SingleLeverMode,'Tag','SingleLeverRadioButton');
%             
%             uistack(taskModeButtonGroup,'bottom');
        end 
        
        function delete(self)
%             close(self.Figure);
        end
        
        function startingRun(self,wsModel,eventName)
            % Called just before each set of sweeps (a.k.a. each
            % "run")
        end
        
        function completingRun(self,wsModel,eventName)
            % Called just after each set of sweeps (a.k.a. each
            % "run")
        end
        
        function stoppingRun(self,wsModel,eventName)
            % Called if a sweep goes wrong
        end        
        
        function abortingRun(self,wsModel,eventName)
            % Called if a run goes wrong, after the call to
            % abortingSweep()
        end
        
        function startingSweep(self,wsModel,eventName)
            % Called just before each sweep
            if self.Disabled
                return
            end
                
            self.SamplesWritten = 0;
            self.State = 1;
            self.Time = 0;
        end
        
        function completingSweep(self,wsModel,eventName)
            % Called after each sweep completes
        end
        
        function stoppingSweep(self,wsModel,eventName)
            % Called if a sweep goes wrong
        end        
        
        function abortingSweep(self,wsModel,eventName)
            % Called if a sweep goes wrong
        end  
        
        function dataAvailable(self,wsModel,eventName)
            % Called each time a "chunk" of data (typically 100 ms worth) 
            % has been accumulated from the looper.
            if self.Disabled
                return
            end
            
            data = wsModel.Acquisition.getLatestAnalogData();
            
            n = size(data,1);
            t = [0; self.Time + (1:n)'/wsModel.Acquisition.SampleRate];
            s = zeros(n,1);
            
            nextState = self.CurrentState;
            nextTransition = 0;
            lastTransition = 0;
            
            while ~isempty(nextTransition)
                nextTransition = nextTransition+lastTransition;
                
                t((nextTransition+2):end) = t((nextTransition+2):end)-t(nextTransition+1);
                s((nextTransition+1):end) = nextState;
                
                self.CurrentState = nextState;
                lastTransition = nextTransition;
                
                [nextTransition,nextState] = self.States(self.CurrentState).checkInputs(t((nextTransition+2):end),data((nextTransition+1):end));
            end
            
            self.Time = t(end);
            
            if wsModel.Logging.IsEnabled
                thisSweepIndex = wsModel.Logging.NextSweepIndex;
                
                stateDatasetName = sprintf('/sweep_%04d/StateMachineTask/state',thisSweepIndex);
%                 nActiveAnalogChannels = sum(wsModel.Acquisition.IsAnalogChannelActive);
                
                if wsModel.AreSweepsFiniteDuration
                    chunkSize = wsModel.Acquisition.ExpectedScanCount;
                else
                    chunkSize = wsModel.Acquisition.SampleRate;
                end
                
                try
                    h5create(wsModel.Logging.CurrentRunAbsoluteFileName, ...
                    stateDatasetName, ...
                    [Inf 2], ...
                    'ChunkSize', [chunkSize 2], ...
                    'DataType','double');
                catch e
                    if ~strcmp(e.identifier,'MATLAB:imagesci:h5create:datasetAlreadyExists')
                        error(e);
                    end
                end
                    
                h5write(wsModel.Logging.CurrentRunAbsoluteFileName, ...
                    stateDatasetName, ...
                    s, ...
                    [self.SamplesWritten+1 1], ...
                    size(s));
                
                self.SamplesWritten = self.SamplesWritten + size(data,1);
            end
        end
        
        % These methods are called in the looper process
        function samplesAcquired(self,looper,eventName,analogData,digitalData) 
            % Called each time a "chunk" of data (typically a few ms worth) 
            % is read from the DAQ board.
        end
        
        % These methods are called in the refiller process
        function startingEpisode(self,refiller,eventName)
            % Called just before each episode
        end
        
        function completingEpisode(self,refiller,eventName)
            % Called after each episode completes
        end
        
        function stoppingEpisode(self,refiller,eventName)
            % Called if a episode goes wrong
        end        
        
        function abortingEpisode(self,refiller,eventName)
            % Called if a episode goes wrong
        end
    end
end
        