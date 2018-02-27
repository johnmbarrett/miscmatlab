classdef DoubleLeverTask < ws.UserClass
    properties(Access=protected,Transient=true)
        ClearDigitalInputsTimer
        Disabled
        State_ = DoubleLeverTaskState.DELAY_PERIOD % TODO : should there be a state for not running?  should disabled be a state?
        TimeAtStartOfSweep
        
        Figure % can make this constant and use it for storing static data (i.e. DoubleLeverTask.Figure.Blah) if I need to, don't think I do for now
    end
    
    % needs to be public so the test suite can access it, but must be
    % hidden otherwise Wavesurfer tries to save it and gets into an
    % infinite loop
    properties(GetAccess=public,SetAccess=protected,Hidden=true)
        Parent
    end
       
    % Can't use dependent properties for this because then I can't call
    % their setters as methods, which I need to do for the uicontrols
    properties(Access=protected)
        ContinuousReward = false
        SingleLeverMode = false
        Thresholds = [5 5]
        FixedVoltageThreshold = [true true];
        DelayPeriod_ = 1
        StimPeriod_ = 1
        ResponsePeriod_ = 1
        SamplesWritten = 0;
        RollingMean;
        RollingVariance;
    end
    
    % ... except these ones need to be dependent because they depend on
    % ContinuousReward, so looks like I just have to make a set method as
    % well as a set. method
    properties(Dependent=true)
        DelayPeriod
        StimPeriod
        ResponsePeriod
    end
    
    % also needs to be Hidden because Wavesurfer is bad and dumb
    properties(Dependent=true,GetAccess=public,SetAccess=protected,Hidden=true)
        State
    end
    
    methods(Access=protected)
        function clearDigitalInputs(self,~,~,wsModel)
            wsModel.Stimulation.DigitalOutputStateIfUntimed = [false false]; % TODO : this is not safe
            
            if self.ContinuousReward
                self.State = DoubleLeverTaskState.RESPONSE_PERIOD;
            end
        end
        
        % Allows access to protected and protected variables from
        % ws.Coding, because Wavesurfer is bad and terrible
        function out = getPropertyValue_(self, name)
            out = self.(name) ;
        end
        
        function setPropertyValue_(self, name, value)
            self.(name) = value ;
        end 
        
        function giveFeedback(self,wsModel,noCheck,feedback)
            wsModel.Stimulation.DigitalOutputStateIfUntimed = feedback;
            
            if noCheck || ~strcmp(self.ClearDigitalInputsTimer.Running,'on') % TODO : there's a sort of race condition here whereby if you reward then punish in quick succession (or vice-versa) then the punishment will only last as long as the reward had left
                start(self.ClearDigitalInputsTimer);
            end
        end
        
        function punish(self,wsModel,noCheck)
            self.giveFeedback(wsModel,noCheck,[false true]);
        end
        
        function reward(self,wsModel,noCheck)
            self.giveFeedback(wsModel,noCheck,[true false]);
        end
    end
    
    methods
        function s = getContinuousReward(self)
            s = self.ContinuousReward;
        end
        
        function setContinuousReward(self,c)
            if islogical(c) && isscalar(c)
                self.ContinuousReward = c;
            else
                warning('Continuous reward must be a logical scalar');
            end
            
            if self.ContinuousReward
                enable = 'off';
            else
                enable = 'on';
            end
            
            set(findobj(self.Figure,'-regexp','Tag','(Delay|Stim|Response)Period(EditBox|Slider)'),'Enable',enable);
        end
        
        function d = get.DelayPeriod(self)
            if self.ContinuousReward
                d = 0;
            else
                d = self.DelayPeriod_;
            end
        end
        
        function set.DelayPeriod(self,d)
            if isnumeric(d) && isscalar(d) && isreal(d) && isfinite(d) && d >= 0 && d <= 3600
                self.DelayPeriod_ = d;
            else
                warning('Delay period must be a real, numeric, non-negative scalar less than 3601');
            end
            
            set(findobj(self.Figure,'Tag','DelayPeriodEditBox'),'String',sprintf('%f',self.DelayPeriod_));
            set(findobj(self.Figure,'Tag','DelayPeriodSlider'),'Value',self.DelayPeriod_);
        end
        
        function setDelayPeriod(self,d)
            self.DelayPeriod = d;
        end
        
        function r = get.ResponsePeriod(self)
            if self.ContinuousReward
                r = Inf;
            else
                r = self.ResponsePeriod_;
            end
        end
        
        function set.ResponsePeriod(self,r)
            if isnumeric(r) && isscalar(r) && isreal(r) && isfinite(r) && r >= 0 && r <= 3600
                self.ResponsePeriod_ = r;
            else
                warning('Response period must be a real, numeric, non-negative scalar less than 3601');
            end
            
            set(findobj(self.Figure,'Tag','ResponsePeriodEditBox'),'String',sprintf('%f',self.ResponsePeriod_));
            set(findobj(self.Figure,'Tag','ResponsePeriodSlider'),'Value',self.ResponsePeriod_);
        end
        
        function setResponsePeriod(self,r)
            self.ResponsePeriod = r;
        end
        
        function s = get.StimPeriod(self)
            if self.ContinuousReward
                s = 0;
            else
                s = self.StimPeriod_;
            end
        end
        
        function set.StimPeriod(self,s)
            if isnumeric(s) && isscalar(s) && isreal(s) && isfinite(s) && s >= 0 && s <= 3600
                self.StimPeriod_ = s;
            else
                warning('Stimulus period must be a real, numeric, non-negative scalar less than 3601');
            end
            
            set(findobj(self.Figure,'Tag','StimPeriodEditBox'),'String',sprintf('%f',self.StimPeriod_));
            set(findobj(self.Figure,'Tag','StimPeriodSlider'),'Value',self.StimPeriod_);
        end
        
        function setStimPeriod(self,s)
            self.StimPeriod = s;
        end
        
        function m = getSingleLeverMode(self)
            m = self.SingleLeverMode;
        end
        
        function setSingleLeverMode(self,m)
            self.SingleLeverMode = m;
        end
        
        function s = getThresholds(self)
            s = self.Thresholds;
        end
        
        function setThresholds(self,t)
            if isnumeric(t) && isequal(size(t),[1 2]) && all(isreal(t) & isfinite(t) & t >= -10 & t <= 10)
                self.Thresholds = t;
            else
                warning('Thresholds must a two-element real, finite, numeric row vector between -10 and +10');
            end
            
            set(findobj(self.Figure,'Tag','Threshold1EditBox'),'String',sprintf('%f',self.Thresholds(1)));
            set(findobj(self.Figure,'Tag','Threshold1Slider'),'Value',self.Thresholds(1));
            
            set(findobj(self.Figure,'Tag','Threshold2EditBox'),'String',sprintf('%f',self.Thresholds(2)));
            set(findobj(self.Figure,'Tag','Threshold2Slider'),'Value',self.Thresholds(2));
        end
        
        function setThreshold(self,t,index)
            ts = self.Thresholds;
            ts(index) = t;
            self.setThresholds(ts);
        end
        
        function setFixedVoltageThreshold(self,b,index)
            self.FixedVoltageThreshold(index) = b;
        end
        
        function s = get.State(self)
            s = self.State_;
        end
        
        function set.State(self,s)
            assert(isa(s,'DoubleLeverTaskState'),'State must be a valid DoubleLeverTaskState');
            
            self.State_ = s;
            
            set(findobj(self.Figure,'Tag','StateTextBox'),'String',sprintf('%s',self.State_));
        end
    end
    
    methods(Access=public)
        function encodingContainer = encodeForPersistence(self)
            encodingContainer = self.encodeForPersistence@ws.Coding();
        end
        
        function self = DoubleLeverTask(parent)
            if ~isa(parent.Parent,'ws.WavesurferModel')
                disp('You are not the one true Wavesurfer Model');
                self.Disabled = true;
                return
            end
            
            self.Parent = parent.Parent;
            
            disp('Let''s do this');
            self.ClearDigitalInputsTimer = timer(...
                'ExecutionMode',    'singleShot',                               ...
                'StartDelay',       0.25,                                       ... % TODO : expose parameter
                'TimerFcn',         {@self.clearDigitalInputs parent.Parent}    ...
                );
            
            self.Disabled = false;
            
            figureWidth = 355;
            figureHeight = 288;
            self.Figure = figure('Position',[100 100 figureWidth figureHeight]);
            
            set(self.Figure,'Name','Task Control','NumberTitle','off');
            
            uicontrol('Style','text','String','Threshold 1','Position',[10 figureHeight-42.5 100 25],'HorizontalAlignment','left');
            
            uicontrol('Style','edit','String',sprintf('%d',self.Thresholds(1)),'Position',[120 figureHeight-35 100 25],'Tag','Threshold1EditBox',...
                'Callback',{@(editBox,~,task) task.setThreshold(str2double(get(editBox,'String')),1) self});
            
            uicontrol('Style','slider','Value',self.Thresholds(1),'Position',[220 figureHeight-35 15 25], ...
                'Tag','Threshold1Slider','Min',-10,'Max',10,'SliderStep',[0.1/20 1/20], ...
                'Callback',{@(slider,~,task) task.setThreshold(get(slider,'Value'),1) self});
            
            threshold1ButtonGroup = uibuttongroup(self.Figure,'Units','pixels','Position',[240 figureHeight-35 110 25],'Visible','on',...
                'SelectionChangedFcn',{@(~,selectionData,task) task.setFixedVoltageThreshold(strcmp(selectionData.NewValue.Tag,'Threshold1VoltsRadioButton'),1) self});
            
            uicontrol(threshold1ButtonGroup,'Style','radiobutton','Units','pixels','Position',[5 0 50 25], ...
                'String','Volts','Value',self.FixedVoltageThreshold(1),'Tag','Threshold1VoltsRadioButton');
            
            uicontrol(threshold1ButtonGroup,'Style','radiobutton','Units','pixels','Position',[55 0 50 25], ...
                'String','s.d.','Value',~self.FixedVoltageThreshold(1),'Tag','Threshold1SDRadioButton');
            
            threshold2ButtonGroup = uibuttongroup(self.Figure,'Units','pixels','Position',[240 figureHeight-70 110 25],'Visible','on',...
                'SelectionChangedFcn',{@(~,selectionData,task) task.setFixedVoltageThreshold(strcmp(selectionData.NewValue.Tag,'Threshold2VoltsRadioButton'),2) self});
            
            uicontrol(threshold2ButtonGroup,'Style','radiobutton','Units','pixels','Position',[5 0 50 25], ...
                'String','Volts','Value',self.FixedVoltageThreshold(2),'Tag','Threshold2VoltsRadioButton');
            
            uicontrol(threshold2ButtonGroup,'Style','radiobutton','Units','pixels','Position',[55 0 50 25], ...
                'String','s.d.','Value',~self.FixedVoltageThreshold(2),'Tag','Threshold1SDRadioButton');
            
            uicontrol('Style','text','String','Threshold 2','Position',[10 figureHeight-77.5 100 25],'HorizontalAlignment','left');
            
            uicontrol('Style','edit','String',sprintf('%d',self.Thresholds(2)),'Position',[120 figureHeight-70 100 25],'Tag','Threshold2EditBox',...
                'Callback',{@(editBox,~,task) task.setThreshold(str2double(get(editBox,'String')),2) self});
            
            uicontrol('Style','slider','Value',self.Thresholds(2),'Position',[220 figureHeight-70 15 25], ...
                'Tag','Threshold2Slider','Min',-10,'Max',10,'SliderStep',[0.1/20 1/20], ...
                'Callback',{@(slider,~,task) task.setThreshold(get(slider,'Value'),2) self});
            
            uicontrol('Style','text','String','Delay Period','Position',[10 figureHeight-112.5 100 25],'HorizontalAlignment','left');
            
            uicontrol('Style','edit','String',sprintf('%d',self.DelayPeriod),'Position',[120 figureHeight-105 100 25],'Tag','DelayPeriodEditBox',...
                'Callback',{@(editBox,~,task) task.setDelayPeriod(str2double(get(editBox,'String'))) self});
            
            uicontrol('Style','slider','Value',self.DelayPeriod,'Position',[220 figureHeight-105 15 25], ...
                'Tag','DelayPeriodSlider','Min',0,'Max',3601,'SliderStep',[0.1/3601 1/3601], ...
                'Callback',{@(slider,~,task) task.setDelayPeriod(get(slider,'Value')) self});
            
            uicontrol('Style','text','String','Stim Period','Position',[10 figureHeight-147.5 100 25],'HorizontalAlignment','left');
            
            uicontrol('Style','edit','String',sprintf('%d',self.StimPeriod),'Position',[120 figureHeight-140 100 25],'Tag','StimPeriodEditBox',...
                'Callback',{@(editBox,~,task) task.setStimPeriod(str2double(get(editBox,'String'))) self});
            
            uicontrol('Style','slider','Value',self.StimPeriod,'Position',[220 figureHeight-140 15 25], ...
                'Tag','StimPeriodSlider','Min',0,'Max',3601,'SliderStep',[0.1/3601 1/3601], ...
                'Callback',{@(slider,~,task) task.setStimPeriod(get(slider,'Value')) self});
            
            uicontrol('Style','text','String','Response Period','Position',[10 figureHeight-182.5 100 25],'HorizontalAlignment','left');
            
            uicontrol('Style','edit','String',sprintf('%d',self.ResponsePeriod),'Position',[120 figureHeight-175 100 25],'Tag','ResponsePeriodEditBox',...
                'Callback',{@(editBox,~,task) task.setResponsePeriod(str2double(get(editBox,'String'))) self});
            
            uicontrol('Style','slider','Value',self.ResponsePeriod,'Position',[220 figureHeight-175 15 25], ...
                'Tag','ResponsePeriodSlider','Min',0,'Max',3601,'SliderStep',[0.1/3601 1/3601], ...
                'Callback',{@(slider,~,task) task.setResponsePeriod(get(slider,'Value')) self});
            
            uicontrol('Style','text','String','Continuous Reward','Position',[10 figureHeight-217.5 100 25],'HorizontalAlignment','left');
            
            uicontrol('Style','checkbox','Position',[120 figureHeight-210 25 25], ...
                'Value',self.ContinuousReward,'Tag','ContinuousRewardCheckBox', ...
                'Callback',{@(checkBox,~,task) task.setContinuousReward(logical(get(checkBox,'Value'))) self});
            
            uicontrol('Style','text','String','Current State','Position',[10 figureHeight-252.5 100 25],'HorizontalAlignment','left');
            
            uicontrol('Style','text','String',sprintf('%s',self.State),'Position',[120 figureHeight-252.5 100 25],'HorizontalAlignment','left','Tag','StateTextBox');
            
            uicontrol('Style','pushbutton','String','REWARD','Position',[10 figureHeight-277.5 100 25], ...
                'Callback',{@(~,~,task,wsModel) task.reward(wsModel,false) self parent.Parent});
            
            uicontrol('Style','pushbutton','String','PUNISH','Position',[120 figureHeight-277.5 100 25], ...
                'Callback',{@(~,~,task,wsModel) task.punish(wsModel,false) self parent.Parent});
            
            uicontrol('Style','text','String','Task Mode:','Position',[245 figureHeight-117.5 100 25],'HorizontalAlignment','left');
            
            taskModeButtonGroup = uibuttongroup(self.Figure,'Units','pixels','Position',[240 figureHeight-175 110 90],'Visible','on');
            
            uicontrol(taskModeButtonGroup,'Style','radiobutton','Units','pixels','Position',[5 35 100 25], ...
                'String','Single Lever','Value',self.SingleLeverMode,'Tag','SingleLeverRadioButton', ...
                'Callback',{@(radioButton,~,task) task.setSingleLeverMode(logical(get(radioButton,'Value'))) self});
            
            uicontrol(taskModeButtonGroup,'Style','radiobutton','Units','pixels','Position',[5 5 100 25], ...
                'String','Double Lever','Value',~self.SingleLeverMode,'Tag','SingleLeverRadioButton');
            
            uistack(taskModeButtonGroup,'bottom');
        end 
        
        function delete(self)
            close(self.Figure);
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
                
            if self.ContinuousReward
                self.State = DoubleLeverTaskState.RESPONSE_PERIOD;
            else
                self.State = DoubleLeverTaskState.DELAY_PERIOD;
            end
            
            self.TimeAtStartOfSweep = tic;
            self.SamplesWritten = 0;
            self.RollingMean = [NaN NaN];
            self.RollingVariance = [NaN NaN];
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
            
            t = toc(self.TimeAtStartOfSweep);
            
            data = wsModel.Acquisition.getLatestAnalogData();
            
            if isnan(self.RollingMean(1))
                % bootstrap mean and variance to the mean and variance of
                % the first lot of data so it settles quicker 
                self.RollingMean = mean(data);
                self.RollingVariance = var(data);
            end
            
            thresholds = zeros(size(data));
            
            m = [self.RollingMean; zeros(size(data))];
            v = [self.RollingVariance; zeros(size(data))];
            
            for ii = 1:2
                if self.FixedVoltageThreshold(ii)
                    thresholds(:,ii) = repmat(self.Thresholds(ii),size(data,1),1);
                elseif self.State == DoubleLeverTaskState.DELAY_PERIOD || (self.ContinuousReward && self.State == DoubleLeverTaskState.RESPONSE_PERIOD)
                    % TODO : expose?
                    alpha = 0.01;

                    for jj = 1:size(data,1)
                        m(jj+1,ii) = (1-alpha)*m(jj,ii)+alpha*data(jj,ii);
                        v(jj+1,ii) = (1-alpha)*(v(jj,ii)+alpha*(data(jj,ii)-m(jj,ii)).^2);
                    end

                    s = sqrt(v(:,ii));
                    thresholds(:,ii) = m(2:end,ii)+self.Thresholds(ii)*s(2:end,ii);
                end
            end
            
            state = data > thresholds;
            
            triggered = any(state,1);
            
            for ii = 1:2
                if ~triggered(ii) % went above threshold during the window, so set mean 
                    self.RollingMean(ii) = m(end,ii);
                    self.RollingVariance(ii) = v(end,ii);
                elseif ~all(state(:,ii))
                    lastBelowThresholdSample = find(~state,1,'last');
                    self.RollingMean(ii) = m(lastBelowThresholdSample,ii);
                    self.RollingVariance(ii) = v(lastBelowThresholdSample,ii);
                end
            end
            
            if self.SingleLeverMode
                triggered = any(triggered,2);
            else
                triggered = all(triggered,2);
            end
            
            if wsModel.Logging.IsEnabled
                thisSweepIndex = wsModel.Logging.NextSweepIndex;
                
                stateDatasetName = sprintf('/sweep_%04d/doubleLeverTaskState',thisSweepIndex);
                thresholdDatasetName = sprintf('/sweep_%04d/doubleLeverTaskThreshold',thisSweepIndex);
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
                
                try
                    h5create(wsModel.Logging.CurrentRunAbsoluteFileName, ...
                    thresholdDatasetName, ...
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
                    double(state), ...
                    [self.SamplesWritten+1 1], ...
                    size(state));
                    
                h5write(wsModel.Logging.CurrentRunAbsoluteFileName, ...
                    thresholdDatasetName, ...
                    thresholds, ...
                    [self.SamplesWritten+1 1], ...
                    size(thresholds));
                
                self.SamplesWritten = self.SamplesWritten + size(data,1);
            end
            
            if self.State == DoubleLeverTaskState.TRIAL_END
                return % do nothing during ITI
            end

            if t > self.DelayPeriod
                if t <= self.DelayPeriod + self.StimPeriod
                    self.State = DoubleLeverTaskState.STIM_PERIOD;
                    return % do nothing during stim period
                elseif t <= self.DelayPeriod + self.StimPeriod + self.ResponsePeriod
                    self.State = DoubleLeverTaskState.RESPONSE_PERIOD;
                else
                    self.State = DoubleLeverTaskState.TRIAL_END;

                    % got to TRIAL_END without being triggered => punish
                    self.punish(wsModel,true);
                end
            end

            if self.State == DoubleLeverTaskState.STIM_PERIOD
                return
            end
            
            if strcmp(self.ClearDigitalInputsTimer.Running,'on')
                return % don't check levers if we're already responding to a lever push, but still need to keep track of state
            end
            
            if ~triggered
                return
            end
            
            if self.State == DoubleLeverTaskState.DELAY_PERIOD
                self.punish(wsModel,true);
            elseif self.State == DoubleLeverTaskState.RESPONSE_PERIOD
                self.reward(wsModel,true);
            else
                warning('Levers triggered in state %s. State machine corrupt.',self.State);
            end
            
            self.State = DoubleLeverTaskState.TRIAL_END; % triggering once puts you in TRIAL_END regardless of current state
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
        