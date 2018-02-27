classdef StateMachine < ws.Coding
    properties(Access=protected)
        States_
    end
    
    properties(Access=public,Dependent=true)
        CurrentState
        States
    end
    
    properties(Access=protected,Transient=true)
        Time
        SamplesWritten
    end
    
    % hidden and transient so wavesurfer never tries to save it
    properties(Access=protected,Transient=true,Hidden=true)
        CurrentState_
    end
    
    methods(Access=protected)
        % Allows access to protected and protected variables from
        % ws.Coding, because Wavesurfer is bad and terrible
        function out = getPropertyValue_(self, name)
            out = self.(name);
        end
        
        function setPropertyValue_(self, name, value)
            self.(name) = value;
        end
    end
    
    methods
        function states = get.States(self)
            states = self.States_;
        end
        
        function set.States(self,states)
            assert(isa(states,'StateMachineState'),'StateMachine States must be StateMachineStates');
            
            self.States_ = states;
        end
        
        function state = get.CurrentState(self)
            state = self.CurrentState_;
        end
        
        function set.CurrentState(self,state)
            assert(isnumeric(state) && isscalar(state) && isreal(state) && isfinite(state) && round(state) == state && state > 0 && state <= numel(self.States_),'StateMachine CurrentState must be a positive scalar integer less than or equal to the number of States');
            
            self.CurrentState_ = state;
        end
    end
    
    methods(Access=public)
        function encodingContainer = encodeForPersistence(self) % TODO : needed?
            encodingContainer = self.encodeForPersistence@ws.Coding();
        end
        
        function self = StateMachine(states)
            if nargin < 1 || ~isa(states,'StateMachineState')
                self.States_ = StateMachineState();
            else
                self.States_ = states;
            end
            
            self.initialise();
        end 
        
         % TODO : these methods don't actually need to be called this now that this isn't a ws.UserClass
        function initialise(self,varargin)
            % Called just before each sweep
            self.SamplesWritten = 0;
            self.CurrentState = 1;
            self.Time = 0;
        end 
        
        function update(self,data,wsModel,varargin) % TODO : can we get wsModel out of this?
%             data = wsModel.Acquisition.getLatestAnalogData();
            
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
                
                [nextTransition,nextState] = self.States(self.CurrentState).checkInputs(t((nextTransition+2):end),data((nextTransition+1):end,:));
            end
            
            self.Time = t(end);
            
            if wsModel.Logging.IsEnabled
                thisSweepIndex = wsModel.Logging.NextSweepIndex;
                
                stateDatasetName = sprintf('/sweep_%04d/StateMachineTask/state',thisSweepIndex);
                inputDatasetName = sprintf('/sweep_%04d/StateMachineTask/input',thisSweepIndex);
                
                if wsModel.AreSweepsFiniteDuration
                    chunkSize = wsModel.Acquisition.ExpectedScanCount;
                else
                    chunkSize = wsModel.Acquisition.SampleRate;
                end
                
                try
                    h5create(wsModel.Logging.CurrentRunAbsoluteFileName, ...
                    stateDatasetName, ...
                    [Inf 1], ...
                    'ChunkSize', [chunkSize 1], ...
                    'DataType','double');
                catch e
                    if ~strcmp(e.identifier,'MATLAB:imagesci:h5create:datasetAlreadyExists')
                        error(e);
                    end
                end
                
                try
                    h5create(wsModel.Logging.CurrentRunAbsoluteFileName, ...
                    inputDatasetName, ...
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
                    
                h5write(wsModel.Logging.CurrentRunAbsoluteFileName, ...
                    inputDatasetName, ...
                    data, ...
                    [self.SamplesWritten+1 1], ...
                    size(data));
                
                self.SamplesWritten = self.SamplesWritten + size(data,1);
            end
        end
    end
end
        