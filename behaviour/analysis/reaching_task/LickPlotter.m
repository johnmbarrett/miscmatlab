classdef LickPlotter < handle
    properties
        CurrentState
        CurrentTime
        Figure
        ReachExcessivelyHandle
        ReachInVainHandle
        ReachSuccessfullyHandle
        ReachBuffer
        StateHandle
        StateBuffer
        TaskAxis
    end
    
    methods
        function self = LickPlotter
            self.Figure = figure;
            
            nSubplots = 1;
            self.TaskAxis = subplot(nSubplots,1,1);
            colormap(gray(10));
            set(self.TaskAxis,'CLim',[0 10],'XLim',[-10 0]);
            
            self.ReachBuffer = zeros(0,2);
            self.StateBuffer = zeros(0,2);
        end
        
        function parseIncomingData(self,bytes)
            chars = char(bytes);
            
            firstNewline = find(chars == self.Newline,1,'first');
            
            if isempty(firstNewline)
                return % not enough data to bother with
            end
            
            lastNewline = find(chars == self.Newline,1,'last');
            
            if lastNewline == firstNewline
                return
            end
            
            % throw away first and last lines in case they're crap
            A = textscan(chars((firstNewline+1):lastNewline),self.Format,'CollectOutput',true,'CommentStyle','=');
            
            A = double(A{1});
            
            timestamps = A(:,1)/1e6;
            state = A(:,2);
            reaches = A(:,3);
%             responses = double(A(:,4));

            self.CurrentState = state(end);
            self.CurrentTime = timestamps(end);
            
            stateChangeIndices = find(diff(state) ~= 0)+1;
            
            if ~isempty(stateChangeIndices)
                self.StateBuffer = [self.StateBuffer; timestamps(stateChangeIndices) state(stateChangeIndices)];
            end
            
            reachChangeIndices = find(diff(reaches) > 0)+1;
            
            if ~isempty(stateChangeIndices)
                self.ReachBuffer = [self.ReachBuffer; timestamps(reachChangeIndices) state(reachChangeIndices)];
            end
            
            self.updatePlots();
        end
        
        function updatePlots(self)
            tic;
            if size(self.StateBuffer,1) < 4
                return
            end
            
            t = bsxfun(@plus,[self.StateBuffer((end-2):end,1)'-self.CurrentTime 0],[0;1;1;0]);
            u = bsxfun(@plus,zeros(1,4),[0;0;1;1]);
            s = [self.StateBuffer((end-3):end,2); self.CurrentState]+4;
            
            if ~isgraphics(self.StateHandle)
                self.StateHandle = fill(self.TaskAxis,t,u,s,'EdgeColor','none');
            else
                set(self.StateHandle,'CData',num2cell(s),'XData',mat2cell(t,4,ones(1,4)));
            end
            
            toc;
        end
    end
end