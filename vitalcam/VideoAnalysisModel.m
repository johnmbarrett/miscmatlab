classdef VideoAnalysisModel < ws.Model
    properties (SetAccess = protected)
        GetVideoTimer
        RefreshRate
        Running
        ROI
        Threshold
        VideoSource
        
        % TODO: refactor these out into a filter class? does WaveSurfer
        % already have something like that?
        BufferSize;
        InputBuffer
        OutputBuffer
        A
        B
    end
    
    methods (Access = public)
        function self = VideoAnalysisModel(varargin)
            self@ws.Model([]); % TODO: parent???
            
            self.RefreshRate = 20;
            
            self.GetVideoTimer = timer( ...
                'ExecutionMode',    'fixedRate',        ...
                'Period',           1/self.RefreshRate, ...
                'TimerFcn', @self.getVideo              ...
                );
            
            self.Running = false;
            self.ROI = nan(1,4);
            self.Threshold = 0;
            self.VideoSource = EmptyVideoStream();
            
            self.BufferSize = 1024;
            self.InputBuffer = zeros(self.BufferSize,1);
            self.OutputBuffer = zeros(self.BufferSize,1);
            self.A = 1;
            self.B = 1;
        end
    end
    
    methods (Access = private)
        function getVideo(self)
            if ~self.VideoSource.hasFrame()
                self.Running = false;
                stop(self.GetVideoTimer);

                return;
            end

            frame = handles.cam.readFrame();
            fprintf(handles.logto,'Retrieved frame in %f seconds\n',toc);
            % frame = frame(240+(-127:128),320+(-127:128),:);

            % tic;
            % frame = handles.evm.filter(frame);
            % toc;

            switch get(handles.threshtypemenu,'Value')
                case 1
                    t = get(handles.threshslider,'Value');
                case 2
                    t = get(handles.threshslider,'Value');
                case 3
                    if get(handles.applyfilterbox,'Value') == 0
                        m = nanmean(handles.outbuffer);
                        s = nanstd(handles.outbuffer);
                    else
                        m = nanmean(handles.inbuffer);
                        s = nanstd(handles.inbuffer);
                    end

                    t = m+s*get(handles.threshslider,'Value');
            end

            set(handles.threshold,'YData',[t t]);

            tic;
            if ~any(isnan(handles.roi))
                x = max(1,floor(handles.roi(1)));
                y = max(1,floor(handles.roi(2)));
                w = max(1,floor(handles.roi(3)));
                h = max(1,floor(handles.roi(4)));
                v = mean(mean(mean(frame(y:y+h,x:x+w,:),1),2),3);

                handles.inbuffer = [handles.inbuffer(2:end); v];

                b = getappdata(hfigure,'b');
                p = numel(b);

                a = getappdata(hfigure,'a');
                q = numel(a)-1;

                % the transpose in the indices for a prevents errors when a is scalar
                w = (sum(b.*handles.inbuffer(end:-1:end-p+1))-sum(a((2:end)').*handles.outbuffer(end:-1:end-q+1)))/a(1);

                handles.outbuffer = [handles.outbuffer(2:end); w];

                if get(handles.applyfilterbox,'Value') == 0
                    u = handles.inbuffer(end-1:end);
                else
                    u = handles.outbuffer(end-1:end);
                end

                isPositiveSlope = logical(get(handles.posslopebutton,'Value'));

                if isPositiveSlope && (u(2) > t && u(1) <= t) || ...
                  ~isPositiveSlope && (u(2) < t && u(1) >= t)
                    sendTrigger = timer('ExecutionMode','singleShot','StartDelay',get(handles.leddelayslider,'Value')/1000,'TimerFcn', ...
                    {@sendLEDPulse handles.task get(handles.leddurslider,'Value')});
                    start(sendTrigger);
                end
            end

            fprintf(handles.logto,'Saved ROI to buffer in %f seconds\n',toc);

            tic;
            guidata(hfigure,handles);
            fprintf(handles.logto,'Saved handles in %f seconds\n',toc);

            % function update_display(hObject,eventdata,hfigure)
            % tic;
            % handles = guidata(hfigure);
            % fprintf(handles.logto,'Retrieved handles in %f seconds\n',toc);
            % tic;
            set(handles.liveStream,'CData',frame);

            if size(frame,3) == 1
                colormap(handles.display,gray(255));
            end

            fprintf(handles.logto,'Showed camera image in %f seconds\n',toc);
            tic;
            fprintf(handles.logto,'Summed ROI in %f seconds\n',toc);
            tic;
            % plot(handles.respmonitor,t,handles.outbuffer);

            if get(handles.diffcheckbox,'Value') == 0
                ydataRaw = handles.inbuffer;
                ydataFiltered = handles.outbuffer;
            else
                ydataRaw = [NaN; diff(handles.inbuffer)];
                ydataFiltered = [NaN; diff(handles.outbuffer)];
            end

            set(handles.rawsignal,'YData',ydataRaw)
            set(handles.filteredsignal,'YData',ydataFiltered)
            % arrayfun(@(h,ii) set(h,'YData',ydata(:,ii)),handles.rawsignal,(1:2)');
            fprintf(handles.logto,'Plotted ROI sum in %f seconds\n',toc);
            tic;
            drawROI(handles);
            fprintf(handles.logto,'Drew ROI in %f seconds\n',toc);
        end
    end
end