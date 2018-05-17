classdef WheelPlotter < handle
    properties(Constant=true)
        Newline = newline;
        Tab = sprintf('\t');
    end
    
    properties(GetAccess=public,SetAccess=protected)
        AngleAxis
        AngleBuffer
        AngleDataHandle
        Figure
        Format
        LickAxis
        LickBuffer
        LickDataHandle
        LowerThresholdHandle
        RewardAxis
        RewardColumns
        RewardBuffer
        RewardedTurnsHandle
        StateAxis
        StateColumn
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
        WheelBufferWidth
    end
    
    methods
        function self = WheelPlotter(timeWindow,wheelBufferLength,wheelBufferWidth,format,stateColumn,rewardColumns)
            self.Figure = figure;
            
            self.WheelAxis = subplot(5,1,1);
            hold(self.WheelAxis,'on');
            xlabel(self.WheelAxis,'Time (s)');
            ylabel(self.WheelAxis,'Wheel Angle (degrees)');
            
            self.AngleAxis = subplot(5,1,2);
            hold(self.AngleAxis,'on');
            xlabel(self.AngleAxis,'Time (s)');
            ylabel(self.AngleAxis,'Wheel Angle (degrees)');
            
            self.RewardAxis = subplot(5,1,3);
            hold(self.RewardAxis,'on');
            xlabel(self.RewardAxis,'Time (s)');
            ylabel(self.RewardAxis,'# Turns');
            
            self.StateAxis = subplot(5,1,4);
            hold(self.StateAxis,'on');
            xlabel(self.StateAxis,'Time (s)');
            ylabel(self.StateAxis,'State');
            
            self.LickAxis = subplot(5,1,5);
            hold(self.LickAxis,'on');
            xlabel(self.LickAxis,'Time (s)');
            ylabel(self.LickAxis,'# Licks');
            
            if nargin < 3
                wheelBufferWidth = 1;
            end
            
            self.WheelBufferWidth = wheelBufferWidth;
            self.AngleBuffer = nan(1,1+self.WheelBufferWidth);
            self.RewardBuffer = nan(1,3);
            self.StateBuffer = nan(1,2);
            self.ThresholdBuffer = nan(1,2);
            self.LickBuffer = zeros(1,2);
            
            if nargin < 1
                timeWindow = 5;
            end
            
            self.TimeWindow = timeWindow;
            
            if nargin < 2
                wheelBufferLength = 1e4;
            end
            
            self.WheelBufferLength = wheelBufferLength;
            
            if nargin < 4
                format = 10;
            end
            
            if ischar(format)
                self.Format = format;
            elseif isnumeric(format) && isscalar(format) && isfinite(format) && format > 0
                self.Format = strjoin(repmat({'%f'},1,format),'\t');
            else
                error('nothing about this is okay');
            end
            
            if nargin < 5
                self.StateColumn = 3;
            else
                self.StateColumn = stateColumn;
            end
            
            if nargin < 6
                self.RewardColumns = 8:9;
            else
                self.RewardColumns = rewardColumns;
            end
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
                self.WheelBuffer = nan(self.WheelBufferLength_,1+self.WheelBufferWidth);
            elseif oldWheelBufferLength < self.WheelBufferLength_
                self.WheelBuffer = [nan(self.WheelBufferLength_-oldWheelBufferLength,1+self.WheelBufferWidth); self.WheelBuffer];
            elseif oldWheelBufferLength > self.WheelBufferLength_
                self.WheelBuffer = self.WheelBuffer((end-self.WheelBufferLength_+1):end,:);
            end
            
            self.updatePlots();
        end
        
        function parseIncomingData(self,bytes)
            try
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
            A = textscan(chars((firstNewline+1):lastNewline),self.Format,'CollectOutput',true,'CommentStyle','=');
            
            A = double(A{1});
            
            nSamples = size(A,1);
            
            if nSamples > self.WheelBufferLength_
                nSamples = self.WheelBufferLength_;
                B = A((end-nSamples+1):end,:);
            else
                B = A;
            end
            
            if nSamples < self.WheelBufferLength_
                self.WheelBuffer(1:(end-nSamples),:) = self.WheelBuffer((nSamples+1):end,:);
            end
            
            self.WheelBuffer((end-nSamples+1):end,:) = [B(:,1)/1e6 360*B(:,2:(self.WheelBufferWidth+1))/4096];
            
            self.AngleBuffer(end+(1:floor(size(A,1)/100)),:) = [A(100:100:end,1)/1e6 360*A(100:100:end,2:(self.WheelBufferWidth+1))/4096];
            
            [rewards,rewardIndices] = unique(A(:,self.RewardColumns),'rows');
            rewardTimes = A(rewardIndices,1)/1e6;
            self.RewardBuffer(end+(1:numel(rewardIndices)),:) = [rewardTimes rewards];
            
            stateIndices = find(diff(A(:,self.StateColumn)))+1;
            state = A(stateIndices,self.StateColumn);
            stateTimes = A(stateIndices,1)/1e6;
            self.StateBuffer(end+(1:numel(stateIndices)),:) = [stateTimes state];
            
            if size(A,1) > 1
                dLicks = diff(A(:,end));
                lickIndices = find(dLicks > 0);
                
                if ~isempty(lickIndices)
                    lickTimes = kron(A(lickIndices+1,1)/1e6,ones(2,1))+repmat([0;0.001],numel(lickIndices),1);
                    licks = kron(dLicks(lickIndices),ones(2,1)).*repmat([1;0],numel(lickIndices),1);
                    self.LickBuffer(end+(1:numel(lickTimes)),:) = [lickTimes licks];
                end
            end
            
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
            catch err
                logMatlabError(err);
            end
        end
    end
    
    methods(Access=protected)
        function updatePlots(self)
            if isempty(self.WheelDataHandle)
                self.WheelDataHandle = plot(self.WheelAxis,NaN,NaN(1,self.WheelBufferWidth));
                self.LowerThresholdHandle = line([NaN NaN],[NaN NaN],'Color','r','Parent',self.WheelAxis);
                self.UpperThresholdHandle = line([NaN NaN],[NaN NaN],'Color','g','Parent',self.WheelAxis);
            end
            
            t = self.WheelBuffer(:,1)-self.WheelBuffer(end,1);
            set(self.WheelDataHandle,{'XData'},repmat({t},self.WheelBufferWidth,1),{'YData'},mat2cell(self.WheelBuffer(:,2:end),size(t,1),ones(self.WheelBufferWidth,1))');
            set(self.LowerThresholdHandle,'XData',t([1 end]),'YData',self.ThresholdBuffer(1)*[1 1]);
            set(self.UpperThresholdHandle,'XData',t([1 end]),'YData',self.ThresholdBuffer(2)*[1 1]);
            
            if isempty(self.AngleDataHandle)
                self.AngleDataHandle = plot(self.AngleAxis,NaN,NaN(1,self.WheelBufferWidth));
            end
            
            set(self.AngleDataHandle,{'XData'},repmat({self.AngleBuffer(:,1)},self.WheelBufferWidth,1),{'YData'},mat2cell(self.AngleBuffer(:,2:end),size(self.AngleBuffer,1),ones(self.WheelBufferWidth,1))');
            
            if isempty(self.RewardedTurnsHandle)
                self.RewardedTurnsHandle = stairs(self.RewardAxis,NaN,NaN,'r');
                self.UnrewardedTurnsHandle = stairs(self.RewardAxis,NaN,NaN,'b');
            end
               
            set(self.RewardedTurnsHandle,'XData',self.RewardBuffer(:,1),'YData',self.RewardBuffer(:,2));
            set(self.UnrewardedTurnsHandle,'XData',self.RewardBuffer(:,1),'YData',self.RewardBuffer(:,3));
            
            if isempty(self.StateDataHandle)
                self.StateDataHandle = stairs(self.StateAxis,NaN,NaN);
            end
            
            set(self.StateDataHandle,'XData',self.StateBuffer(:,1),'YData',self.StateBuffer(:,2));
            
            if isempty(self.LickDataHandle)
                self.LickDataHandle = stairs(self.LickAxis,NaN,NaN);
            end
            
            set(self.LickDataHandle,'XData',self.LickBuffer(:,1),'YData',self.LickBuffer(:,2));
            
            drawnow;
        end
    end
end