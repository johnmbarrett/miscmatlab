% matlab y u no inner class?!?
classdef StateMachineState < ws.Coding % inherits Coding so it can be saved
    events
        EnteredState
        LeftState
    end
    
    properties(Access=protected)
        Name_
        InputFunctions_ % A cell array of function handles.  Each takes two inputs, the first of which is an NxM matrix of data, and returns an NxP logical matrix indicating where the ith row of the jth column indicates whether input j was detected at time i.
        InputParams_ % A cell array of the same size as InputFunctions_, where each element is the second input to each InputFunction.  Each element can be anything your heart desires.
%         OutputFunction_ % A function called when entering the state.  For now it takes no args and returns nothing.
        TransitionMatrix_ % A P-element vector where the ith element indicates the index of the state to move to when the ith input is detected.  A little bit dirty since we can't really validate how many states there are in the state machine, so we'll just have to trust StateMachineTask to ensure all its list of States is internally consistent
    end
    
    properties(Access=protected,Transient=true)
        Triggered
    end
    
    properties(Access=public,Dependent=true)
        Name
        InputFunctions
        InputParams
%         OutputFunction
        TransitionMatrix
    end
    
    properties(Constant=true)
        Validators = struct(    ...
            'Name',             @ischar,                                                                             ...
            'InputFunctions',   isCellArrayOfFunctionHandles(),                                                             ...
            'InputParams',      @iscell,                                                                           ...
...%             'OutputFunction',   @(x) isa(x,'function_handle'),                                                              ...
            'TransitionMatrix', @(x) isnumeric(x) && isvector(x) && all(isfinite(x) & isreal(x) & x > 0 & round(x) == x)    ...
            );
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
        
        % This one is purely for my own laziness
        function setPropertyValue(self, name, value)
            assert(self.Validators.(name)(value),sprintf('Value of %s must satisfy the function %s',name,func2str(self.Validators.(name))));
            self.([name '_']) = value;
        end
    end
    
    methods
        function out = get.Name(self)
            out = self.Name_;
        end
        
        function set.Name(self,value)
            self.setPropertyValue('Name',value);
        end
        
        function out = get.InputFunctions(self)
            out = self.InputFunctions_;
        end
        
        function set.InputFunctions(self,value)
            self.setPropertyValue('InputFunctions',value);
        end
        
        function out = get.InputParams(self)
            out = self.InputParams_;
        end
        
        function set.InputParams(self,value)
            self.setPropertyValue('InputParams',value);
        end
        
%         function out = get.OutputFunction(self)
%             out = self.OutputFunction_;
%         end
%         
%         function set.OutputFunction(self,value)
%             self.setPropertyValue('OutputFunction',value);
%         end
        
        function out = get.TransitionMatrix(self)
            out = self.TransitionMatrix_;
        end
        
        function set.TransitionMatrix(self,value)
            self.setPropertyValue('TransitionMatrix',value);
        end
    end
    
    methods(Access=public)
        function self = StateMachineState(varargin)
            parser = inputParser;
            parser.addOptional('name','A Nice State',self.Validators.Name);
            parser.addOptional('inputs',{@nop},self.Validators.InputFunctions);
            parser.addOptional('params',NaN,self.Validators.InputParams);
%             parser.addOptional('output',@nop,self.Validators.OutputFunction);
            parser.addOptional('matrix',1,self.Validators.TransitionMatrix);
            
            parser.parse(varargin{:});
            
            self.Name = parser.Results.name;
            self.InputFunctions = parser.Results.inputs;
            self.InputParams = parser.Results.params;
%             self.OutputFunction = parser.Results.output;
            self.TransitionMatrix = parser.Results.matrix;
            
            self.Triggered = false;
        end
        
        function [nextTransition,nextState] = checkInputs(self,t,data)
            if ~self.Triggered
                fprintf('Entered state %s\n',self.Name);
                self.notify('EnteredState'); %self.OutputFunction();
                self.Triggered = true;
            end
            
            update = false(numel(t),numel(self.InputFunctions));
            
            for ii = 1:numel(self.InputFunctions)
                update(:,ii) = self.InputFunctions{ii}([t data],self.InputParams{ii});
            end
            
            nextTransition = find(any(update,2),1);
            
            if isempty(nextTransition)
                nextState = [];
                return
            end
            
            detectedInput = find(update(nextTransition,:),1); % TODO : there's an implicit 'priority' to inputs where if multiple inputs are detected simultaneously, whichever is listed first is responded to and the rest are ignored.  Not sure if this is an issue.
            
            nextState = self.TransitionMatrix(detectedInput);
            
            self.Triggered = false;
            
            self.notify('LeftState');
        end
    end
end