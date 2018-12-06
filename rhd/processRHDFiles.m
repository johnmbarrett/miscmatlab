function processRHDFiles(dataFolder,parameterFile,channelsPerProbe,probeVersions) % TODO : pull out all the other parameters
    % HEAVILY adapted from Xiaojian's EXP_GU_1

    %%%%   Sort the data based on the Marker in Din channel. The first bit
    %%%%   is the marker of the start of stimulus, the bits following
    %%%%   represent the parameter code.

    trialDuration = 500;
    paramCodeBitDepth = 16; 
    isStimulusEncodedInTrigger = false; % TODO : fix this true; % set to false for older recordings

    % channelsPerProbe = [32;32];
    % probeVersions = [1;1];
    
    
    % TODO : expose all params as name-value pairs
    if nargin < 3
        channelsPerProbe = [32;32;32];
    end
    
    if nargin < 4
        probeVersions = [2;1;2];
    end
    
    % channelsPerProbe = [32;32;32;32;32];
    % probeVersions = [1;1;1;1;2];
    if nargin < 1 || ~ischar(dataFolder) || isempty(parameterFile)
        dataFolder = uigetdir('C:\IntanData','Intan Folder to Read:');
    end
    
    cd(dataFolder);
    
    if nargin < 2
        parameterFile = '';
    end

    [params,stimulusSequence] = readParameterFile(parameterFile);

    isBandPass = true;
    % TODO : these are named this way to make Intan2Mat_3 work, but should
    % eventually be named something sensible and passed through in a normal way
    %%
    evalin('base','BandPass_Low = 800');
    evalin('base','BandPass_High = 6000');
    %%
    isDeartifact = true;
    isPCADeartifact = false;
    isOnline = false; % online analysis is not supported at present

    isSaveFigure = false;          %%%% save figure (formerly f_SaveFig)

    % TODO : I think these are for online analysis, which I'm too lazy to
    % reimplement right now
    % binWidth = 1;           %%% ms (formerly spikebin)
    % Showbin =  1 ;          %%% ms ?? 
    % Mask = 0;              %%% ms ??
    % Offset = 1;            %%% ms ??
    % 
    % Figure(1,:) = {[10],0,1,25,200,[1],[100],[10],0,1,[0 25 50 225],200,[0],[100]}; %% ???

    if isOnline
        preStimulusBins = 260;
        postStimulusBins = 40;
        % TODO : ArrangeSubFigure_NP_1;
        % TODO : timers for offline analysis don't make sense, move the timer
        % setup in here
        %WC = 100;                    %%% wait cycle for online analysis
        fprintf(1, 'In Online Analysis Mode ! \n');
    else
        preStimulusBins = 100;
        postStimulusBins = 400;
        fprintf(1, 'In Offline Analysis Mode ! \n');
        trialDataFolder = '/TrialData'; % formerly SaveTrialFolder
        mkdir([dataFolder trialDataFolder]);
    end

    if isSaveFigure == 1
        mkdir([dataFolder '/Figures']);
    end

    probeLayouts = cell2mat(arrayfun(@(n,v,c) getProbeLayout(n,v)+c,channelsPerProbe,probeVersions,[0;cumsum(channelsPerProbe(1:end-1))],'UniformOutput',false));

    rhdFiles = dir('*.rhd');

    nStimuli = size(params,1);
    nChannels = numel(probeLayouts);

    derandomisedPSTH = zeros(preStimulusBins+postStimulusBins,nChannels,nStimuli);
    trialCount = zeros(1,nStimuli);
    trialsSoFar = 0;

    analogTail = zeros(0,nChannels);
    digitalTail = zeros(0,1);

    for hh = 1:numel(rhdFiles)-1 % Xiaojian's version has a bug where it doesn't process the last file
        tic;
        [analogData, digitalData, sampleRate] = Intan2Mat_3(rhdFiles(hh).name,isBandPass);
        analogData = analogData';
        digitalData = digitalData';

        analogData = [analogTail; analogData]; %#ok<AGROW>
        digitalData = [digitalTail; digitalData]; %#ok<AGROW>

        if ~isPCADeartifact
            [psth,analogData] = binSpikes(analogData,sampleRate,isDeartifact);
        end

        sampleRatekHz = sampleRate / 1000;

        stimulusMarkers = find(digitalData(1:end-(postStimulusBins*sampleRatekHz)));
        paramCodeLength = (paramCodeBitDepth+2) * sampleRatekHz;
        stimulusMarkers(find(diff(stimulusMarkers) <= paramCodeLength)+1) = [];

        for ii = 1:numel(stimulusMarkers)   
            stimulusMarker = stimulusMarkers(ii);

            if isStimulusEncodedInTrigger
                paramCode = 0;
                for jj = 2:paramCodeBitDepth+1
                    if digitalData(stimulusMarker + jj*sampleRatekHz - sampleRatekHz/2) == 1
                        paramCode(1,1) = paramCode(1,1) + 2^(jj + 2);
                    end
                end

                stimulusIndex = find(stimulusSequence == paramCode);
            else
                stimulusIndex = stimulusSequence(mod(trialsSoFar,nStimuli)+1)+1; % stimulus IDs start from zeros
            end

            stimulusBin = floor(stimulusMarker/sampleRatekHz);

            if stimulusBin+postStimulusBins-1 > size(psth,1) % trial spans a recording boundary
                stimulusMarker = stimulusMarkers(ii-1);
                break
            end

            if ~isPCADeartifact
                trialPSTH = psth(stimulusBin-preStimulusBins:stimulusBin+postStimulusBins-1,:);
            end

            trialsSoFar = trialsSoFar + 1;

            if ~isOnline || isPCADeartifact
                trialTrace = analogData(stimulusMarker-preStimulusBins*sampleRatekHz:stimulusMarker+postStimulusBins*sampleRatekHz,:);

                if isPCADeartifact
                    x = trialTrace(preStimulusBins*sampleRatekHz+(-1000:1000),:);
                    [c,s] = pca(x);
                    k = find(max(s) >= 100,1,'last'); %find(cumsum(e) > 99.99,1);
    %                 z = s(:,1:k)*c(:,1:k)';
                    y = s(:,(k+1):end)*c(:,(k+1):end)';
    %                 figure(69); %nice
    %                 subplot(1,3,1); plot(x);
    %                 subplot(1,3,2); plot(z);
    %                 title(sprintf('k = %d',k));
    %                 subplot(1,3,3); plot(y);
                    trialTrace(preStimulusBins*sampleRatekHz+(-1000:1000),:) = y;
                end

                trialPSTH = binSpikes(trialTrace(1:end-1,:),sampleRate,false);

                if ~isOnline
                    save([dataFolder trialDataFolder '/trial_' num2str(trialsSoFar) '_' num2str(stimulusIndex)],'trialTrace','trialPSTH');
                end
            end

            derandomisedPSTH(:,:,stimulusIndex) = derandomisedPSTH(:,:,stimulusIndex) + trialPSTH;
            trialCount(stimulusIndex) = trialCount(stimulusIndex) + 1;
        end

        analogTail = analogData(stimulusMarker+(paramCodeBitDepth+3)*sampleRatekHz:end,:);
        digitalTail = digitalData(stimulusMarker+(paramCodeBitDepth+3)*sampleRatekHz:end,:);

    %         if isOnline % TODO : never
    %             FigShow_NP_1(probeLayouts,hh,isSaveFigure);
    %         end

        fprintf(1, 'Data Process Done!   %0.1f seconds\n', toc);
    end

    matrixFolder = [dataFolder '/DataMatrix'];
    mkdir(matrixFolder);
    cd(matrixFolder);

    params = mat2cell(params,ones(size(params,1),1),size(params,2));

    meanPSTH = bsxfun(@rdivide,derandomisedPSTH,reshape(trialCount,1,1,[]));
    meanPSTH = meanPSTH(:,probeLayouts,:);
    meanPSTH = squeeze(mat2cell(meanPSTH,size(meanPSTH,1),size(meanPSTH,2),ones(size(meanPSTH,3),1)));

    Par_PSTH_ave = [params meanPSTH];

    save([dataFolder '/DataMatrix/Par_PSTH_ave.mat'],'Par_PSTH_ave');

    cd(dataFolder);

    trialFiles = loadFilesInNumericOrder([dataFolder trialDataFolder '/trial*.mat'],'trial_([0-9]+)');

    trialFilesPerStimulus = repmat({{}},nStimuli,1);

    for ii = 1:numel(trialFiles)
        tic;

        trialFileParts = strsplit(trialFiles{ii},{'_' '.'});
        stimulusIndex = str2double(trialFileParts{3});

        trialFilesPerStimulus{stimulusIndex}{end+1} = trialFiles{ii};

        toc;
    end

    assert(isequal(cellfun(@numel,trialFilesPerStimulus),trialCount'));

    for ii = 1:nStimuli
        tic;

        StiTrlTrace = zeros((preStimulusBins+postStimulusBins)*sampleRate/1000+1,nChannels,trialCount(ii));
        StiTrlPSTH = zeros(preStimulusBins+postStimulusBins,nChannels,trialCount(ii));

        for jj = 1:numel(trialFilesPerStimulus{ii})
            load([dataFolder trialDataFolder '/' trialFilesPerStimulus{ii}{jj}]);

            StiTrlTrace(:,:,jj) = trialTrace(:,probeLayouts);
            StiTrlPSTH(:,:,jj) = trialPSTH(:,probeLayouts);
        end

        save(sprintf('%s%s\\Sti_%d_t.mat',dataFolder,trialDataFolder,ii),'StiTrlTrace');
        save(sprintf('%s%s\\Sti_%d_p.mat',dataFolder,trialDataFolder,ii),'StiTrlPSTH');

        toc;
    end

    %     if ~isOnline % TODO : never
    %         cd ([dataFolder '/TrialData']); % TODO : I don't like all this CD'ing around
    %         Merge_Trial_1(probeLayouts,size(params,1)); % TODO
    %         cd (dataFolder);
    %     end
end