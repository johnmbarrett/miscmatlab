% matlab y u no inner class?!?
classdef StateMachineTaskState < ws.Coding % inherits Coding so it can be saved
    properties % TODO : attributes?
        Name
        InputFunctions % Takes two inputs, the first of which is an NxM matrix of data, and returns an NxP logical matrix indicating where the ith row of the jth column indicates whether input j was detected at time i.
        InputParams % The second input to each InputFunction.  Can be anything your heart desires.
        OutputFunctions % A P-element cell array of function handles.  The ith element is called when leaving the state after detecting the ith input.  For now each function takes no args and returns nothing.
        TransitionMatrix % A P-element vector where the ith element indicates the index of the state to move to when the ith input is detected.  A little bit dirty since we can't really validate how many states there are in the state machine, so we'll just have to trust StateMachineTask to ensure all its list of States is internally consistent
    end
    
    methods
        function self = StateMachineTaskState(name,inputs,params,outputs,matrix)
            parser = inputParser;
            parser.addOptional('name','A Nice State',@(x) ischar(x));
            
            isCellArrayOfFunctionHandles = @(x) iscell(x) && all(cellfun(@(y) isa(y,'function_handle'),x));
            
            parser.addOptional('inputs',{@(x,varargin) false(size(x,1),1)},isCellArrayOfFunctionHandles);
            parser.addOptional('params',NaN);
            parser.addOptional('outputs',{@nop},isCellArrayOfFunctionHandles);
            parser.addOptional('matrix',1,@(x) isnumeric(x) && isvector(x) && all(isfinite(x) & isreal(x) & x > 0 & round(x) == x));
            
            parser.parse(name,inputs,params,outputs,matrix);
            
            self.Name = parser.Results.name;
            self.InputFunctions = parser.Results.inputs;
            self.InputParams = parser.Results.params;
            self.OutputFunctions = parser.Results.outputs;
            self.TransitionMatrix = parser.Results.matrix;
        end
        
        function [nextTransition,nextState] = checkInputs(self,t,data)
            update = false(numel(t),numel(self.InputFunctions));
            
            for ii = 1:numel(self.InputFunctions)
                update(:,ii) = self.InputFunctions{ii}([t data],self.InputParams);
            end
            
            nextTransition = find(any(update,2),1);
            
            if isempty(nextTransition)
                nextState = [];
                return
            end
            
            detectedInput = find(update(nextTransition,:),1); % TODO : there's an implicit 'priority' to inputs where if multiple inputs are detected simultaneously, whichever is listed first is responded to and the rest are ignored.  Not sure if this is an issue.
            
            nextState = self.TransitionMatrix(detectedInput);
            
            self.OutputFunctions{detectedInput}();
        end
    end
end