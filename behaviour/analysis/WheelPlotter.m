classdef WheelPlotter < handle
    properties(Constant=true)
        Format = strjoin(repmat({'%f'},1,10),'\t');
        Newline = sprintf('\n');
        Tab = sprintf('\t');
    end
    
    properties(GetAccess=public,SetAccess=protected)
        AngleAxis
        AngleBuffer
        AngleDataHandle
        Figure
        LowerThresholdHandle
        RewardAxis
        RewardBuffer
        RewardedTurnsHandle
        StateAxis
        StateBuffer
        StateDataHandle
        ThresholdBuffer
        UnrewardedTurnsHandle
        UpperThresholdHandle
        WheelAxis
        WheelBuffer
        WheelDataHandle
    end
    
    properties(Dependent=true)
        TimeWindow
        WheelBufferLength
    end
    
    properties(Access=protected)
        TimeWindow_
        WheelBufferLength_
    end
    
    methods
        function self = WheelPlotter(timeWindow,wheelBufferLength)
            self.Figure = figure;
            
            self.WheelAxis = subplot(4,1,1);
            hold(self.WheelAxis,'on');
            
            self.AngleAxis = subplot(4,1,2);
            hold(self.AngleAxis,'on');
            
            self.RewardAxis = subplot(4,1,3);
            hold(self.RewardAxis,'on');
            
            self.StateAxis = subplot(4,1,4);
            hold(self.AngleAxis,'on');
            
            self.AngleBuffer = nan(1,2);
            self.RewardBuffer = nan(1,3);
            self.StateBuffer = nan(1,2);
            self.ThresholdBuffer = nan(1,2);
            
            if nargin < 1
                timeWindow = 5;
            end
            
            self.TimeWindow = timeWindow;
            
            if nargin < 2
                wheelBufferLength = 1e4;
            end
            
            self.WheelBufferLength = wheelBufferLength;
        end
        
        function w = get.TimeWindow(self)
            w = self.TimeWindow_;
        end
        
        function set.TimeWindow(self,w)
            self.TimeWindow_ = w;
            xlim(self.WheelAxis,[-w 0]);
        end
        
        function l = get.WheelBufferLength(self)
            l = self.WheelBufferLength_;
        end
        
        function set.WheelBufferLength(self,l)
            oldWheelBufferLength = self.WheelBufferLength_;
            
            self.WheelBufferLength_ = l;
            
            if isempty(self.WheelBuffer)
                self.WheelBuffer = nan(self.WheelBufferLength_,2);
            elseif oldWheelBufferLength < self.WheelBufferLength_
                self.WheelBuffer = [nan(self.WheelBufferLength_-oldWheelBufferLength,1); self.WheelBuffer];
            elseif oldWheelBufferLength > self.WheelBufferLength_
                self.WheelBuffer = self.WheelBuffer((end-self.WheelBufferLength_+1):end,:);
            end
            
            self.updatePlots();
        end
        
        function parseIncomingData(self,bytes)
            tic;
%             evalin('base','stop(td.Timer)');
            
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
            A = textscan(chars((firstNewline+1):lastNewline),self.Format,'CollectOutput',true);
            
            A = double(A{1});
            
            nSamples = size(A,1);
            
            if nSamples > self.WheelBufferLength_
                nSamples = self.WheelBufferLength_;
                A = A((end-nSamples+1):end,:);
            end
            
            if nSamples < self.WheelBufferLength_
                self.WheelBuffer(1:(end-nSamples),:) = self.WheelBuffer((nSamples+1):end,:);
            end
            
            self.WheelBuffer((end-nSamples+1):end,:) = [A(:,1)/1e6 360*A(:,2)/4096];
            
            self.AngleBuffer(end+(1:floor(nSamples/100)),:) = [A(100:100:end,1)/1e6 360*A(100:100:end,2)/4096];
            
            [rewards,rewardIndices] = unique(A(:,8:9),'rows');
            rewardTimes = A(rewardIndices,1)/1e6;
            self.RewardBuffer(end+(1:numel(rewardIndices)),:) = [rewardTimes rewards];
            
            [state,stateIndices] = unique(A(:,3));
            stateTimes = A(stateIndices,1)/1e6;
            self.StateBuffer(end+(1:numel(stateIndices)),:) = [stateTimes state];
            
            % this is for forcing variable sampling rate data into fixed
            % sampling rate, but it doesn't quite work
%             t = A(:,1)/1e3;
%             
%             if isnan(self.WheelBuffer(end,1))
%                 nSamples = floor(t(end)-t(1))+1;
%             else
%                 nSamples = floor(t(end)-self.WheelBuffer(end,1)*1e3);
%             end
%             
%             u = (t(end)-((min(nSamples,self.TimeAxisLength_)-1):-1:0))'/1e3;
%             
%             if nSamples >= self.TimeAxisLength_
%                 self.WheelBuffer = [u interp1(t/1e3,A(:,2),u)];
%             elseif nSamples > 0    
%                 self.WheelBuffer(1:end-nSamples,:) = self.WheelBuffer((nSamples+1):end,:);
% 
%                 if isnan(self.WheelBuffer(end,1))
%                     self.WheelBuffer((end-nSamples+1):end,1) = u;
%                 else
%                     self.WheelBuffer((end-nSamples+1):end,1) = self.WheelBuffer(end-nSamples,1)+(1:nSamples)/1e3;
%                 end
% 
%                 self.WheelBuffer((end-nSamples+1):end,2) = interp1(t/1e3,A(:,2),self.WheelBuffer((end-nSamples+1):end,1));
%             end
            
            self.updatePlots();
            
            toc;
        end
    end
    
    methods(Access=protected)
        function updatePlots(self)
            if isempty(self.WheelDataHandle)
                self.WheelDataHandle = plot(self.WheelAxis,NaN,NaN);
                self.LowerThresholdHandle = line([NaN NaN],[NaN NaN],'Color','r','Parent',self.WheelAxis);
                self.UpperThresholdHandle = line([NaN NaN],[NaN NaN],'Color','g','Parent',self.WheelAxis);
            end
            
            t = self.WheelBuffer(:,1)-self.WheelBuffer(end,1);
            set(self.WheelDataHandle,'XData',t,'YData',self.WheelBuffer(:,2));
            set(self.LowerThresholdHandle,'XData',t([1 end]),'YData',self.ThresholdBuffer(1)*[1 1]);
            set(self.UpperThresholdHandle,'XData',t([1 end]),'YData',self.ThresholdBuffer(2)*[1 1]);
            
            if isempty(self.AngleDataHandle)
                self.AngleDataHandle = plot(self.AngleAxis,NaN,NaN);
            end
            
            set(self.AngleDataHandle,'XData',self.AngleBuffer(:,1),'YData',self.AngleBuffer(:,2));
            
            if isempty(self.RewardedTurnsHandle)
                self.RewardedTurnsHandle = plot(self.RewardAxis,NaN,NaN,'r');
                self.UnrewardedTurnsHandle = plot(self.RewardAxis,NaN,NaN,'b');
            end
               
            set(self.RewardedTurnsHandle,'XData',self.RewardBuffer(:,1),'YData',self.RewardBuffer(:,2));
            set(self.UnrewardedTurnsHandle,'XData',self.RewardBuffer(:,1),'YData',self.RewardBuffer(:,3));
            
            if isempty(self.StateDataHandle)
                self.StateDataHandle = plot(self.StateAxis,NaN,NaN);
            end
            
            set(self.StateDataHandle,'XData',self.StateBuffer(:,1),'YData',self.StateBuffer(:,2));
            
            drawnow;
        end
    end
end