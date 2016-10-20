function plotVideoData(videoDataFile,hdf5File,laserChannel,varargin)
    if nargin < 2 || ~ischar(videoDataFile) || ~exist(videoDataFile,'file')
        videoDataFile = uigetfile({'*.mat','MAT Files (*.mat)'},'Choose video data file...');
        
        if videoDataFile == 0
            return
        end
    end
    
    if nargin < 2 || ~ischar(hdf5File) || ~exist(hdf5File,'file')
        hdf5File = uigetfile({'*.h5','HDF5 Files (*.hdf5)'},'Choose Wavesurfer data file...');
        
        if hdf5File == 0
            return
        end
    end
    
    data = ws.loadDataFile(hdf5File);
    
    analogChannelNames = data.header.Acquisition.AnalogChannelNames;

    nAnalogChannels = numel(analogChannelNames);
    
    if nargin < 3 || ~isscalar(laserChannel) || ~isnumeric(laserChannel) || ~ismember(laserChannel,1:nAnalogChannels)
        laserChannel = NaN;
    
        fprintf('Choose laser trigger channel:\n\n');
        
        arrayfun(@(n,c) fprintf('\t(%d) %s\n',n,c{1}),1:nAnalogChannels,analogChannelNames');
        
        fprintf('\n');
        
        while ~isscalar(laserChannel) || ~isnumeric(laserChannel) || ~ismember(laserChannel,1:nAnalogChannels)
            laserChannel = input(sprintf('Enter a channel number (1-%d): ',nAnalogChannels));
        end
    end
    
    load(videoDataFile);
    
    nSweeps = max(pixelSweeps);
    
    sweepStarts = arrayfun(@(n) data.(sprintf('sweep_%04d',n)).timestamp,(1:nSweeps)');
    
    laserCommand = data.sweep_0001.analogScans(:,laserChannel);
    
    laserEdges = diff(laserCommand > 2.5);
    
    laserOnIndices = laserEdges == 1;
    laserOffIndices = laserEdges == -1;
    
    sampleRate = data.header.Acquisition.SampleRate;
    samplePeriod = 1/sampleRate;
    nSamples = numel(laserCommand);
    time = samplePeriod:samplePeriod:nSamples*samplePeriod;
    
    laserOnTimes = time(laserOnIndices)';
    
    parser = inputParser;
    parser.addParameter('useTriggerOffTimes',true,@(x) islogical(x) && isscalar(x));
    parser.addParameter('pulseWidth',0,@(x) isnumeric(x) && isfinite(x) && all(x(:) >= 0) && (isscalar(x) || isequal(size(x),size(laserOnTimes))));
    parser.addParameter('conditions',[],@(x) isempty(x) || ((isnumeric(x) || iscell(x)) && size(x,1) == numel(sweepStarts)));
    parser.addParameter('varNames',[],@(x) isempty(x) || iscellstr(x));
    parser.parse(varargin{:});
    
    if parser.Results.useTriggerOffTimes
        laserOffTimes = time(laserOffIndices)';
    else
        laserOffTimes = laserOnTimes + parser.Results.pulseWidth;
    end
    
    conditions = parser.Results.conditions;
    
    if isempty(conditions)
        conditions = zeros(numel(laserOnTimes),1);
    end
    
    varNames = parser.Results.varNames;
    nVars = size(conditions,2);
    
    if isempty(varNames)
        varNames = arrayfun(@(n) sprintf('Var %d',n),1:size(conditions,2),'UniformOutput',false);
    else
        assert(numel(varNames) == nVars,'Number of variable numbers must match the number of columns in the conditions parameter');
    end
    
    uniqueConditions = cell(1,nVars);
    conditionIndices = zeros(size(conditions));
    
    for ii = 1:nVars
        [uniqueConditions{ii},~,conditionIndices(:,ii)] = unique(conditions(:,ii));
    end
    
    nConditions = cellfun(@numel,uniqueConditions,'UniformOutput',false);
    cConditions = cumsum([nConditions{3:end}]);
    
    figs = zeros(nConditions{3:end});
    nFigs = numel(figs);
    
    for ii = 1:nFigs
        figs(ii) = figure;
    end
    
    rows = nConditions{1};
    cols = nConditions{2};
    interpolatedPixelData = nan(nSamples,nSweeps,nConditions{:});
    
    for ii = 1:max(pixelSweeps)
        conditionIndex = num2cell(conditionIndices(ii,:));
        figure(figs(conditionIndex{3:end}));
        subplot(rows,cols,conditionIndex{2}+cols*(conditionIndex{1}-1));
        hold on;
        title(sprintf('%s = %d, %s = %d',varNames{1},uniqueConditions{1}(conditionIndex{1}),varNames{2},uniqueConditions{2}(conditionIndex{2})));
        t = pixelTimes(pixelSweeps == ii)-sweepStarts(ii);
        v = pixelValues(pixelSweeps == ii); %#ok<NODEF>
        plot(t,v,'Color',[0.5 0.5 0.5]);
        interpolatedPixelData(:,ii,conditionIndex{:}) = interp1(t,v,time);
    end
    
    for ii = 1:nFigs
        if nFigs > 1
            superTitleFormatString = '%s = %d';
            superTitleFormatArgs = {varNames{1} conditions(1,3)};
            
            for jj = 2:prod(conditionIndices{3:end})
                colIndex = find(cConditions <= jj,1);
                rowIndex = jj-sum([nConditions{3:(colIndex+2-1)}]);
                superTitleFormatString = sprintf('%s, %%s = %%d',superTitleFormatString);
                superTitleFormatArgs(end+(1:2)) = {varNames{jj} conditions(rowIndex,colIndex)};
            end    
            
            suptitle(superTitleFormatString,superTitleFormatArgs{:});
        end
        
        for jj = 1:rows
            for kk = 1:cols
                subplot(rows,cols,kk+cols*(jj-1));
                uistack(fill([laserOnTimes laserOffTimes laserOffTimes laserOnTimes]',repmat([0;0;255;255],1,numel(laserOnTimes)),[0.8 0.8 1],'EdgeColor','none'),'bottom');
                plot(time,nanmean(interpolatedPixelData(:,:,jj,kk,ii),2),'Color','k','LineWidth',2);
        
            if std(pixelValues(:)) > 0
                ylim([min(pixelValues(:)) max(pixelValues(:))]);
            end
            end
        end
    end
end