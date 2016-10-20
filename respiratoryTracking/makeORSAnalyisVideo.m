function makeORSAnalyisVideo(dataFile,videoFiles,outputFile,frameRate,framesPerTrigger, sampleRate, secondsEitherSide, padding, initialStartThreshold, initialStopThreshold, ignoreCameraTriggers)
    [voltage, triggered, camTriggered, delaying, flashing, params, paramIndices] = parseORSDataFile(dataFile);
    
    nSamples = size(voltage,1);
    
    voltageOffset = min(voltage);
    voltageScale = (max(voltage)-voltageOffset);
    
    if voltageScale == 0
        voltageScale = 1;
    end
    
    rescale = @(x) (x-voltageOffset)/voltageScale;
    
    data = [rescale(voltage) triggered camTriggered delaying flashing zeros(nSamples,2)];
    data(isnan(data(:,1)),1) = 0;
    
    lastParamsBeforeAcquisitionStart = find(paramIndices < 1, 1, 'last');
    
    startThresholds = rescale(vertcat(params.startThreshold));
    stopThresholds = rescale(vertcat(params.stopThreshold));
    
    if isempty(lastParamsBeforeAcquisitionStart)
        if nargin < 9
            initialStartThreshold = rescale(5);
        else
            initialStartThreshold = rescale(initialStartThreshold);
        end
        
        if nargin < 8
            initialStopThreshold = rescale(5);
        else
            initialStopThreshold = rescale(initialStopThreshold);
        end
    else
        initialStartThreshold = startThresholds(lastParamsBeforeAcquisitionStart);
        initialStopThreshold = stopThresholds(lastParamsBeforeAcquisitionStart);
        paramIndices(1:lastParamsBeforeAcquisitionStart) = [];
        startThresholds(1:lastParamsBeforeAcquisitionStart) = [];
        stopThresholds(1:lastParamsBeforeAcquisitionStart) = [];
    end
    
    if ~isempty(paramIndices)
        data(1:paramIndices(1)-1,6) = initialStartThreshold;
        data(1:paramIndices(1)-1,7) = initialStopThreshold;

        for ii = 2:numel(paramIndices)
            data(paramIndices(ii-1):paramIndices(ii)-1,6) = startThresholds(ii-1);
            data(paramIndices(ii-1):paramIndices(ii)-1,7) = stopThresholds(ii-1);
        end
        
        data(paramIndices(end):end,6) = startThresholds(end);
        data(paramIndices(end):end,7) = stopThresholds(end);
    else
        data(:,6) = initialStartThreshold;
        data(:,7) = initialStopThreshold;
    end
    
    % TODO : name value pairs?
    if nargin < 6 || ~isnumeric(sampleRate) || ~isscalar(sampleRate) || ~isfinite(sampleRate) || sampleRate <= 0
        sampleRate = 1.6e7/(512*13);
    end
    
    time = (1:nSamples)'/sampleRate;
    
    if ~iscell(videoFiles)
        videoFiles = {videoFiles};
    end
    
    reader = VideoReader(videoFiles{1});
    
    if nargin < 4
        frameRate = reader.FrameRate;
    end
    
    camTriggers = find(diff(camTriggered) == 1)+1;
    
    if nargin > 10
        camTriggers = camTriggers(ignoreCameraTriggers+1:end);
    end
    
    if nargin < 5
        framesPerTrigger = 100;
    end
    
    if framesPerTrigger > 1 && framesPerTrigger < Inf
        timePerTrigger = framesPerTrigger/frameRate;

        camTriggers(diff(time(camTriggers)) < timePerTrigger) = [];
    end
    
    nTriggers = numel(camTriggers);    
    
    fig = figure;
    
    monitorPositions = get(0,'MonitorPositions');
    [~,bestMonitor] = max(monitorPositions(:,4)); % largest height
    bestMonitorPosition = monitorPositions(bestMonitor,:);
    
    if nargin < 8 || ~isnumeric(padding) || ~ismember(numel(padding),[1 2]) || ~all(isfinite(padding)) || any(padding < 0)
        padding = 0.1;
    end
    
    xPadding = padding(1);
    
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
    
    if nargin < 7 || ~all(isnumeric(secondsEitherSide(:))) || ~ismember(numel(secondsEitherSide),[1 2]) || ~all(isfinite(secondsEitherSide(:))) || any(secondsEitherSide(:) <= 0)
        secondsBefore = 1;
        secondsAfter = 1;
    elseif isscalar(secondsEitherSide)
        secondsBefore = secondsEitherSide;
        secondsAfter = secondsEitherSide;
    else
        secondsBefore = secondsEitherSide(1);
        secondsAfter = secondsEitherSide(2);
    end
    
    xlabel(dataAxis,'Time Relative to Current Frame');
    xlim(dataAxis,[-secondsBefore secondsAfter]);
    ylabel(dataAxis,'Normalised Signal');
    ylim(dataAxis,[-0.1 1.1]);
    set(dataAxis,'XLimMode','manual','YLimMode','manual');
    line(dataAxis,[0 0],[-0.1 1.1],'Color','k','LineStyle','--');
    hold(dataAxis,'on');
    
    fileCounter = 1;
    frameCounter = 0;
    framePeriod = 1/frameRate;
    samplesPerFrame = sampleRate/frameRate;
    samplesBefore = floor(secondsBefore*sampleRate);
    samplesAfter = ceil(secondsAfter*sampleRate);
    
    if nargin < 3
        [path, name, extension] = videoFiles{1};
        
        if isempty(extension)
            extension = '.avi';
        end
        
        outputFile = [path name '_with_data' extension];
    end
    
    writer = VideoWriter(outputFile);
    
    closeFile = onCleanup(@() close(writer));
    
    writer.FrameRate = frameRate;
    
    open(writer);
    
    while hasFrame(reader)
        loopStart = tic;
        
        if isinf(framesPerTrigger)
            frameIndex = frameCounter;
        else
            frameIndex = mod(frameCounter, framesPerTrigger);
        end
        
        if frameIndex == 0
            camTriggerIndex = frameCounter/framesPerTrigger+1;
            
            if camTriggerIndex > nTriggers
                warning('Expected (%d triggers) * (%d frames per trigger) = %d frames, but reached frame #%d.  Most likely some camera triggers were not recorded.', nTriggers, framesPerTrigger, nTriggers*framesPerTrigger, frameCounter+1);
            end
            
            camTrigger = camTriggers(camTriggerIndex);
        end
        
        if framesPerTrigger == 1
            currentSample = camTrigger;
        else
            currentSample = round(camTrigger+frameIndex*samplesPerFrame);
        end
        
        firstSampleBefore = max(1, currentSample-samplesBefore);
        lastSampleAfter = min(nSamples, currentSample+samplesAfter);
        samples = firstSampleBefore:lastSampleAfter;

        x = time(samples)-time(currentSample);
        y = data(samples,:);
        
        if frameCounter == 0
            dataHandles = plot(dataAxis, x, y);
        
            legend(dataHandles,{'Voltage' 'Triggered' 'Camera Triggered' 'LED Delaying' 'LED Flashing' 'Start Threshold' 'Stop Threshold'});
        else
            for jj = 1:numel(dataHandles)
                set(dataHandles(jj),'XData', x, 'YData', y(:,jj));
            end
        end
        
        frameCounter = frameCounter + 1;
        
        frame = readFrame(reader);
        
        image(videoAxis, frame);
        set(videoAxis,'XTick',[],'YTick',[]); % TODO : move this outside the loop
        
        writeVideo(writer, getframe(fig));
        
        loopTime = toc(loopStart);
        
        pause(max(0, framePeriod-loopTime));
        
        if ~hasFrame(reader) && fileCounter < numel(videoFiles)
            fileCounter = fileCounter + 1;
            reader = VideoReader(videoFiles{fileCounter}); %#ok<TNMLP>
        end
    end
    
    if camTriggerIndex < nTriggers
        warning('Expected (%d triggers) * (%d frames per trigger) = %d frames, but only saw %d frames.  Most likely the recording was stopped early.', nTriggers, framesPerTrigger, nTriggers*framesPerTrigger, frameCounter+1);
    elseif mod(frameCounter, framesPerTrigger) ~= 0
        warning('Frames per trigger %d does not exactly divide number of frames %d.  Either the recording was stopped early or some frames were dropped.  In the latter case, reconciling the recording with the Arduino output is impossible.', framesPerTrigger, frameCounter);
    end
end