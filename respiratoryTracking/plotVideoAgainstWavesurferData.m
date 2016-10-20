function plotVideoAgainstWavesurferData(h5File,videoFile,channel,varargin)
    if nargin < 1 || ~ischar(h5File) || ~exist(h5File,'file')
        h5File = uigetfile({'*.h5','HDF5 Files (*.hdf5)'},'Choose Wavesurfer data file...');
        
        if h5File == 0
            return
        end
    end
    
    if nargin < 2 || ~ischar(videoFile) || ~exist(videoFile,'file')
        supportedFormats = VideoReader.getFileFormats();
        supportedExtensions = cellstr([repmat('*.',9,1) vertcat(supportedFormats.Extension)]);
        videoFile = uigetfile({strjoin(supportedExtensions,';'),['Video Files (' strjoin(supportedExtensions,',') ')']},'Choose video file...');
        
        if videoFile == 0
            return
        end
    end
    
    data = ws.loadDataFile(h5File);
    
    analogChannelNames = data.header.Acquisition.AnalogChannelNames;

    nAnalogChannels = numel(analogChannelNames);
    
    if nargin < 3 || ~isscalar(channel) || ~isnumeric(channel) || ~ismember(channel,1:nAnalogChannels)
        channel = NaN;
    
        fprintf('Choose camera trigger channel:\n\n');
        
        arrayfun(@(n,c) fprintf('\t(%d) %s\n',n,c{1}),1:nAnalogChannels,analogChannelNames');
        
        fprintf('\n');
        
        while ~isscalar(channel) || ~isnumeric(channel) || ~ismember(channel,1:nAnalogChannels)
            channel = input(sprintf('Enter a channel number (1-%d): ',nAnalogChannels));
        end
    end
    
    nSweeps = sum(cellfun(@(s) ~isempty(regexp(s,'sweep_[0-9]{4}','once')),fieldnames(data)));
    
    allData = zeros([size(data.sweep_0001.analogScans) nSweeps]);
    
    for ii = 1:nSweeps
        allData(:,:,ii) = data.(sprintf('sweep_%04d',ii)).analogScans;
    end
    
    samplesPerSweep = size(allData,1);
    
    cameraTriggers = permute(allData(1:end-1,channel,:) >= 2.5 & allData(2:end,channel,:) < 2.5,[1 3 2]); % pretty sure the camera triggers off the falling edge
    cameraTriggerIndices = cell(nSweeps,1);
    
    for ii = 1:nSweeps
        cameraTriggerIndices{ii} = find(cameraTriggers(:,ii));
    end
    
    triggersPerSweep = cumsum(cellfun(@numel,cameraTriggerIndices));
    cameraTriggerIndices = vertcat(cameraTriggerIndices{:});
    
    fig = figure;
    
    monitorPositions = get(0,'MonitorPositions');
    [~,bestMonitor] = max(monitorPositions(:,4)); % largest height
    bestMonitorPosition = monitorPositions(bestMonitor,:);
    
    parser = safeInputParser;
    parser.addParameter('padding',0.1,@(p) isnumeric(p) && ismember(numel(p),[1 2]) && all(isfinite(p)) && all(p >= 0) && all(p <= 1));
    isRealFinitePositiveScalar = @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0;
    parser.addParameter('secondsBefore',1,isRealFinitePositiveScalar);
    parser.addParameter('secondsAfter',1,isRealFinitePositiveScalar);
    
    [~,videoFileName] = fileparts(videoFile);
    
    parser.addParameter('outputFile',[videoFileName ' analysis.avi'],@ischar);
    
    parser.addParameter('analyseROI',true,@(x) islogical(x) && isscalar(x))
    
    parser.parse(varargin{:});
    
    padding = parser.Results.padding;
    
    if ~isnumeric(padding) || ~ismember(numel(padding),[1 2]) || ~all(isfinite(padding)) || any(padding < 0)
        padding = 0.1;
    end
    
    xPadding = padding(1);
    
    reader = VideoReader(videoFile);
    
    if numel(padding) == 2
        yPadding = padding(2);
    else
        yPadding = xPadding*reader.Width/(3*(reader.Height/2-reader.Height*xPadding+xPadding*reader.Width));
    end
    
    baseFigureHeight = 1.5*reader.Height;
    
    figureHeight = Inf;
    divisor = 0;
    
    while figureHeight > bestMonitorPosition(4)
        divisor = divisor+1;
        figureHeight = baseFigureHeight/divisor;
        
        if yPadding > 0;
            figureHeight = figureHeight/(1-3*yPadding);
        end
    end
    
    figureWidth = reader.Width/divisor;
    
    if xPadding > 0
        figureWidth = figureWidth/(1-2*xPadding);
    end
    
    set(fig, 'Position', [bestMonitorPosition(1)+100 bestMonitorPosition(2)+100 figureWidth figureHeight])
    
    axisX = xPadding;
    axisWidth = 1-2*xPadding;
    dataAxisHeight = (1-3*yPadding)/3;
    videoAxisY = 2*yPadding+dataAxisHeight;
    videoAxisHeight = 2*dataAxisHeight;
    
    videoAxis = subplot('Position', [axisX videoAxisY axisWidth videoAxisHeight]);
    
    dataAxis = subplot('Position', [axisX yPadding axisWidth dataAxisHeight]);
    
    sampleRate = data.header.Acquisition.SampleRate;
    samplePeriod = 1/sampleRate;
    secondsBefore = parser.Results.secondsBefore;
    samplesBefore = secondsBefore*sampleRate;
    secondsAfter = parser.Results.secondsAfter;
    samplesAfter = secondsAfter*sampleRate;
    
    time = -secondsBefore:samplePeriod:secondsAfter;
    
    writer = VideoWriter(parser.Results.outputFile);
    writer.FrameRate = sampleRate/median(diff(cameraTriggerIndices));
    open(writer);
    
    pixelValues = zeros(size(cameraTriggerIndices));
    pixelTimes = zeros(size(cameraTriggerIndices));
    pixelSweeps = zeros(size(cameraTriggerIndices));
    
    frameIndex = 0;
    
    while hasFrame(reader)
        frameIndex = frameIndex + 1;
        
        frame = readFrame(reader);
        
        image(videoAxis, frame);
        set(videoAxis,'XTick',[],'YTick',[]);
        
        if frameIndex > numel(cameraTriggerIndices)
            warning('Reached frame #%d but only %d camera triggers were recorded.  Most likely video recording continued after Wavesurfer finished recording.',frameIndex,numel(cameraTriggerIndices));
        end
        
        sampleIndex = cameraTriggerIndices(frameIndex);
        sweepIndex = find(frameIndex <= triggersPerSweep,1);
        
        paddingBefore = max(0,min(numel(time),samplesBefore-sampleIndex+1));
        paddingAfter = max(0,min(numel(time),samplesAfter-(samplesPerSweep-sampleIndex)));
        
        traces = [nan(paddingBefore,nAnalogChannels); allData(max(1,sampleIndex-samplesBefore):min(samplesPerSweep,sampleIndex+samplesAfter),:,sweepIndex); nan(paddingAfter,nAnalogChannels)];
        timestamp = data.(sprintf('sweep_%04d',sweepIndex)).timestamp+(sampleIndex-1)/sampleRate;
        
        hold(dataAxis,'off');
        
        for jj = 1:nAnalogChannels
            plot(dataAxis,time+timestamp,traces(:,jj)+6*(nAnalogChannels-jj));
            
            if jj == 1
                hold(dataAxis,'on');
            end
            
            line(dataAxis,timestamp+[-secondsBefore secondsAfter],[6 6]*(nAnalogChannels-jj),'Color',[0.5 0.5 0.5],'LineStyle','-');
            text(timestamp-secondsBefore-0.05*(secondsBefore+secondsAfter),2.5+6*(nAnalogChannels-jj),strtrim(analogChannelNames{jj}),'FontSize',8,'HorizontalAlignment','center','Parent',dataAxis,'Rotation',90,'VerticalAlignment','middle');
        end
        
        line(dataAxis,[timestamp timestamp],[-1 6*nAnalogChannels+1],'Color','k','LineStyle','--');
        
        xlabel(dataAxis,'Time (s)');
        xlim(dataAxis,[-secondsBefore secondsAfter]+timestamp);
        ylim(dataAxis,[-1 6*nAnalogChannels]);
        
        set(dataAxis,'YTick',repmat([0 5],1,nAnalogChannels)+kron(0:6:(6*(nAnalogChannels-1)),ones(1,2)),'YTickLabel',repmat([0 5],1,nAnalogChannels));
        
        writeVideo(writer, getframe(fig));
        
        if parser.Results.analyseROI
            if frameIndex == 1
                rect = imrect(videoAxis);
            
                roiPosition = getPosition(rect);
                xidx = max(1,min(reader.Width,round(roiPosition(1))+(1:round(roiPosition(3)))));
                yidx = max(1,min(reader.Height,round(roiPosition(2))+(1:round(roiPosition(4)))));
            end
            
            pixelValues(frameIndex) = sum(sum(mean(double(frame(yidx,xidx,:)),3),2),1)/(reader.Width*reader.Height);
            pixelTimes(frameIndex) = timestamp;
            pixelSweeps(frameIndex) = sweepIndex;
        end
    end
    
    if frameIndex < numel(cameraTriggerIndices)
        warning('Expected %d frames but only saw %d.  Either some frames were dropped or recording was stopped early.',numel(cameraTriggerIndices),frameIndex);
    end
    
    save([parser.Results.outputFile(1:end-4) '.mat'],'pixelValues','pixelTimes','pixelSweeps','roiPosition');
end