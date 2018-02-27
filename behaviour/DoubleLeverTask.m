classdef DoubleLeverTask < ws.UserClass
    properties(Access=protected,Constant=true)
        TimeoutFun = @(t,tau) t(:,1) > tau;
        SingleThresholdCrossingFun = @(data,thresh) any(bsxfun(@gt,data(:,2:3),thresh),2);
        DoubleThresholdCrossingFun = @(data,thresh) all(bsxfun(@gt,data(:,2:3),thresh),2);
        Lever1ThresholdCrossingFun = @(data,thresh) data(:,2) > thresh(1);
        Lever2ThresholdCrossingFun = @(data,thresh) data(:,3) > thresh(2);
        Lever1ThresholdUncrossingFun = @(data,thresh) data(:,2) <= thresh(1);
        Lever2ThresholdUncrossingFun = @(data,thresh) data(:,3) <= thresh(2);
    end
    
    properties(GetAccess=public,SetAccess=protected,Transient=true,Hidden=true)
        CurrentStateMachine
        
        ContinuousRewardResponseState
        ContinuousRewardRewardState

        ContinuousRewardStateMachine

        DelayedResponseDelayState
        DelayedResponseStimState
        DelayedResponseResponseState
        DelayedResponseRewardState
        DelayedResponsePrematureResponseState
        DelayedResponseNoResponseState
        DelayedResponseIntertrialIntervalState

        DelayedResponseStateMachine
        
        EitherOrResponseState
        EitherOrLever1PressedState
        EitherOrLever2PressedState
        EitherOrSingleRewardState
        EitherOrQuadRewardState
        
        EitherOrStateMachine
        
        ClearDigitalInputsTimer
        
        Figure % can make this constant and use it for storing static data (i.e. DoubleLeverTask.Figure.Blah) if I need to, don't think I do for now
    end
        
    properties(GetAccess=public,SetAccess=protected,Transient=true)
        Disabled
        TimeAtStartOfSweep
        
        SuccessfulTrials
        PrematureResponses
        MissedResponses
    end
    
    % needs to be public so the test suite can access it, but must be
    % hidden and transient otherwise Wavesurfer tries to save it and gets
    % into an infinite loop
    properties(GetAccess=public,SetAccess=protected,Hidden=true,Transient=true)
        Parent
    end
       
    % Can't use dependent properties for this because then I can't call
    % their setters as methods, which I need to do for the uicontrols
    properties(Access=protected)
        ContinuousReward = false
        Thresholds = [5 5]
        DelayPeriod_ = 1
        StimPeriod_ = 1
        ResponsePeriod_ = 1
        SamplesWritten = 0;
        A
        B
        LastData
    end
    
    % ... except these ones need to be dependent because they depend on
    % ContinuousReward, so looks like I just have to make a set method as
    % well as a set. method
    properties(Dependent=true)
        DelayPeriod
        StimPeriod
        ResponsePeriod
    end
    
    methods(Access=protected)
        function clearDigitalInputs(~,~,~,wsModel)
            wsModel.Stimulation.DigitalOutputStateIfUntimed = [false false false]; % TODO : this is not safe
        end
        
        % Allows access to protected and protected variables from
        % ws.Coding, because Wavesurfer is bad and terrible
        function out = getPropertyValue_(self, name)
            out = self.(name) ;
        end
        
        function setPropertyValue_(self, name, value)
            self.(name) = value ;
        end 
        
        function giveFeedback(self,wsModel,feedback,delay)
            wsModel.Stimulation.DigitalOutputStateIfUntimed = feedback;
            
            if ~strcmp(self.ClearDigitalInputsTimer.Running,'on') % TODO : there's a sort of race condition here whereby if you reward then punish in quick succession (or vice-versa) then the punishment will only last as long as the reward had left
                if nargin > 3
                    self.ClearDigitalInputsTimer.StartDelay = delay;
                else
                    self.ClearDigitalInputsTimer.StartDelay = 0.25;
                end
                
                start(self.ClearDigitalInputsTimer);
            end
        end
        
        function punish(self,wsModel,varargin)
            self.giveFeedback(wsModel,[false true false],varargin{:});
        end
        
        function reward(self,wsModel,varargin)
            self.giveFeedback(wsModel,[true false false],varargin{:});
        end
        
        function trigger(self,wsModel,varargin)
            self.giveFeedback(wsModel,[false false true],varargin{:});
        end
        
        function recordSuccessfulTrial(self,varargin)
            self.reward(self.Parent);
            self.SuccessfulTrials = self.SuccessfulTrials + 1;
        end
        
        function recordPrematureResponse(self,varargin)
            self.punish(self.Parent);
            self.PrematureResponses = self.PrematureResponses + 1;
        end
        
        function recordMissedResponse(self,varargin)
            self.punish(self.Parent);
            self.MissedResponses = self.MissedResponses + 1;
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
                error('Continuous reward must be a logical scalar');
            end
            
            if self.ContinuousReward
                enable = 'off';
                self.CurrentStateMachine = self.ContinuousRewardStateMachine;
            else
                enable = 'on';
                self.CurrentStateMachine = self.DelayedResponseStateMachine;
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
            
            self.DelayedResponseDelayState.InputParams{1} = d;
            
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
            
            self.DelayedResponseResponseState.InputParams{1} = r;
            
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
            
            self.DelayedResponseStimState.InputParams{1} = s;
            
            set(findobj(self.Figure,'Tag','StimPeriodEditBox'),'String',sprintf('%f',self.StimPeriod_));
            set(findobj(self.Figure,'Tag','StimPeriodSlider'),'Value',self.StimPeriod_);
        end
        
        function setStimPeriod(self,s)
            self.StimPeriod = s;
        end
        
        function setTaskMode(self,mode)
            if strcmp(mode,'QuadRewardMode')
                self.setContinuousReward(true);
                self.CurrentStateMachine = self.EitherOrStateMachine;
                set(findobj(self.Figure,'Tag','ContinuousRewardCheckBox'),'Enable','off');
                return
            end
            
            set(findobj(self.Figure,'Tag','ContinuousRewardCheckBox'),'Enable','on');
            self.setContinuousReward(logical(get(findobj(self.Figure,'Tag','ContinuousRewardCheckBox'),'Value')));
            
            switch mode
                case 'SingleLeverMode'
                    fun = self.SingleThresholdCrossingFun;
                case 'DoubleLeverMode'
                    fun = self.DoubleThresholdCrossingFun;
                otherwise
                    error('DoubleLeverTask:UnknownTaskMode','Unknown task mode ''%s''\n',mode);
            end
            
            self.ContinuousRewardResponseState.InputFunctions{1} = fun;
            self.DelayedResponseDelayState.InputFunctions{2} = fun;
            self.DelayedResponseResponseState.InputFunctions{2} = fun;
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
            
            self.ContinuousRewardResponseState.InputParams{1} = t;
            self.DelayedResponseDelayState.InputParams{2} = t;
            self.DelayedResponseResponseState.InputParams{2} = t;
            self.EitherOrResponseState.InputParams{1} = t;
            self.EitherOrResponseState.InputParams{2} = t;
            self.EitherOrLever1PressedState.InputParams{2} = t;
            self.EitherOrLever1PressedState.InputParams{3} = t;
            self.EitherOrLever2PressedState.InputParams{2} = t;
            self.EitherOrLever2PressedState.InputParams{3} = t;
            
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
            
            self.ContinuousRewardResponseState = StateMachineState('Response',{self.SingleThresholdCrossingFun},{[1 1]},2);
            
            self.ContinuousRewardRewardState = StateMachineState('Reward',{self.TimeoutFun},{0.25},1);
            self.ContinuousRewardRewardState.addlistener('EnteredState',@(varargin) self.reward(parent.Parent));

            self.ContinuousRewardStateMachine = StateMachine([self.ContinuousRewardResponseState self.ContinuousRewardRewardState]);

            self.DelayedResponseDelayState = StateMachineState('Delay',{self.TimeoutFun, self.SingleThresholdCrossingFun},{1 self.Thresholds},[2 5]);
            
            self.DelayedResponseStimState = StateMachineState('Stimulus',{self.TimeoutFun},{1},3);
            self.DelayedResponseStimState.addlistener('EnteredState',@(varargin) self.trigger(parent.Parent));
            
            self.DelayedResponseResponseState = StateMachineState('Response',{self.TimeoutFun, self.SingleThresholdCrossingFun},{1 self.Thresholds},[6 4]);
            
            self.DelayedResponseRewardState = StateMachineState('Reward',{self.TimeoutFun},{0.25},7);
            self.DelayedResponseRewardState.addlistener('EnteredState',@self.recordSuccessfulTrial);
            
            self.DelayedResponsePrematureResponseState = StateMachineState('PrematureResponse',{self.TimeoutFun},{0.25},7);
            self.DelayedResponsePrematureResponseState.addlistener('EnteredState',@self.recordPrematureResponse);
            
            self.DelayedResponseNoResponseState = StateMachineState('NoResponse',{self.TimeoutFun},{0.25},7);
            self.DelayedResponseNoResponseState.addlistener('EnteredState',@self.recordMissedResponse);
            
            self.DelayedResponseIntertrialIntervalState = StateMachineState('ITI',{self.TimeoutFun},{3},1);

            self.DelayedResponseStateMachine = StateMachine([self.DelayedResponseDelayState self.DelayedResponseStimState self.DelayedResponseResponseState self.DelayedResponseRewardState self.DelayedResponsePrematureResponseState self.DelayedResponseNoResponseState self.DelayedResponseIntertrialIntervalState]);
            
            self.EitherOrResponseState = StateMachineState('Response',{self.Lever1ThresholdCrossingFun self.Lever2ThresholdCrossingFun},{self.Thresholds self.Thresholds},[2 3]);
            self.EitherOrLever1PressedState = StateMachineState('Lever 1 Pressed',{self.TimeoutFun self.Lever1ThresholdUncrossingFun self.Lever2ThresholdCrossingFun},{0.1 self.Thresholds self.Thresholds},[4 4 5]);
            self.EitherOrLever2PressedState = StateMachineState('Lever 2 Pressed',{self.TimeoutFun self.Lever2ThresholdUncrossingFun self.Lever1ThresholdCrossingFun},{0.1 self.Thresholds self.Thresholds},[4 4 5]);
            
            self.EitherOrSingleRewardState = StateMachineState('Single Reward',{self.TimeoutFun},{3},1);
            self.EitherOrSingleRewardState.addlistener('EnteredState',@(varargin) self.reward(parent.Parent,0.125));
            
            self.EitherOrQuadRewardState = StateMachineState('Quadruple Reward',{self.TimeoutFun},{3},1);
            self.EitherOrQuadRewardState.addlistener('EnteredState',@(varargin) self.reward(parent.Parent,0.5));
            
            self.EitherOrStateMachine = StateMachine([self.EitherOrResponseState self.EitherOrLever1PressedState self.EitherOrLever2PressedState self.EitherOrSingleRewardState self.EitherOrQuadRewardState]);
            
            self.CurrentStateMachine = self.DelayedResponseStateMachine;
            
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
            
            uicontrol('Style','text','String',sprintf('%s',self.CurrentStateMachine.States(self.CurrentStateMachine.CurrentState).Name),'Position',[120 figureHeight-252.5 100 25],'HorizontalAlignment','left','Tag','StateTextBox');
            
            uicontrol('Style','pushbutton','String','REWARD','Position',[10 figureHeight-277.5 100 25], ...
                'Callback',{@(~,~,task,wsModel) task.reward(wsModel) self parent.Parent});
            
            uicontrol('Style','pushbutton','String','PUNISH','Position',[120 figureHeight-277.5 100 25], ...
                'Callback',{@(~,~,task,wsModel) task.punish(wsModel) self parent.Parent});
            
            uicontrol('Style','text','String','Task Mode:','Position',[245 figureHeight-117.5 100 25],'HorizontalAlignment','left');
            
            taskModeButtonGroup = uibuttongroup(self.Figure,'Units','pixels','Position',[240 figureHeight-210 110 125],'Visible','on',...
                'SelectionChangedFcn',{@(~,eventData,task) task.setTaskMode(get(eventData.NewValue,'Tag')) self});
            
            uicontrol(taskModeButtonGroup,'Style','radiobutton','Units','pixels','Position',[5 65 100 25], ...
                'String','Single Lever','Value',true,'Tag','SingleLeverMode');
            
            uicontrol(taskModeButtonGroup,'Style','radiobutton','Units','pixels','Position',[5 35 100 25], ...
                'String','Double Lever','Value',false,'Tag','DoubleLeverMode');
            
            uicontrol(taskModeButtonGroup,'Style','radiobutton','Units','pixels','Position',[5 5 100 25], ...
                'String','Quad Reward','Value',false,'Tag','QuadRewardMode');
            
            uistack(taskModeButtonGroup,'bottom');
        end 
        
        function delete(self)
            close(self.Figure);
        end
        
        function startingRun(self,wsModel,eventName)
            % Called just before each set of sweeps (a.k.a. each
            % "run")
            if self.Disabled
                return
            end
                
            self.CurrentStateMachine.initialise();
            self.SuccessfulTrials = 0;
            self.PrematureResponses = 0;
            self.MissedResponses = 0;
            
            self.LastData = zeros(4,2,2); % TODO : right number of columns
            [self.B,self.A] = butter(4,1e3/wsModel.Acquisition.SampleRate); % TODO : programmable
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
            
            data = filtfilt(self.B,self.A,data);

            self.CurrentStateMachine.update(data,wsModel);
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
        