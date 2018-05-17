function lickInitiatedAnalysis(isTrialBased)
    [~,day] = fileparts(fileparts(pwd));
    [~,cage] = fileparts(pwd);
    file = sprintf('%s_multiphase_wheel_data.mat',cage);

    if ~exist(file,'file')
        error('Exist, the file does not.');
    end
    
    A = load(file); %#ok<NASGU>
    
    file = strrep(file,'.mat','_2.mat');
    
    save(file,'-struct','A','-v7.3');
    
    load(file); %#ok<LOAD>

    %%

    boutStartTimes = cell(size(phaseData));
    boutEndTimes = cell(size(phaseData));
    boutLengths = cell(size(phaseData));
    interBoutIntervals = cell(size(phaseData));
    percentEngagedTime = nan(size(phaseData));
    successesPerBout = cell(size(phaseData));
    nSuccessesPerBout = cell(size(phaseData));
    firstSuccessLatencyPerBout = cell(size(phaseData));
    nSuccessfulTrials = nan(size(phaseData));
    percentSuccessfulTrials = nan(size(phaseData));
    lickTimes = cell(size(phaseData));
    licksPerBout = cell(size(phaseData));
    nLicksPerBout = cell(size(phaseData));
    secondLickLatencyPerBout = cell(size(phaseData));
    licksPerSuccessPerBout = cell(size(phaseData));
    lickSuccessCorrelation = nan(size(phaseData));
    wastedLicks = nan(size(phaseData));
    percentWastedLicks = nan(size(phaseData));
    
    for ii = 1:numel(phaseData)
        tic;
        
        if isempty(phaseData(ii).timestamps)
            continue
        end
        
        boutStarts = phaseData(ii).state(1:end-1) == 13 & phaseData(ii).state(2:end) < 13;
        boutEnds = phaseData(ii).state(1:end-1) < 13 & phaseData(ii).state(2:end) >= 13;

        boutStartTimes{ii} = phaseData(ii).timestamps(boutStarts);
        boutEndTimes{ii} = phaseData(ii).timestamps(boutEnds);

        if numel(boutStartTimes{ii}) > numel(boutEndTimes{ii})
            boutStartTimes{ii}(end) = [];
        end

        boutLengths{ii} = (boutEndTimes{ii} - boutStartTimes{ii}) - 10*(~isTrialBased);
        interBoutIntervals{ii} = (boutStartTimes{ii}(2:end) - boutEndTimes{ii}(1:end-1)) - 10*(~isTrialBased);

        if phaseData(ii).state(end) < 14
            endTime = phaseData(ii).timestamps(end);
        else
            endTime = timestamps(find(phaseData(ii).state == 14,1));
        end

        engagedTime = sum(boutLengths{ii});
        percentEngagedTime(ii) = 100*engagedTime/(endTime-phaseData(ii).timestamps(1));

        successesPerBout{ii} = arrayfun(@(s,e) phaseData(ii).successTimes(phaseData(ii).successTimes >= s & phaseData(ii).successTimes < e)-s,boutStartTimes{ii},boutEndTimes{ii},'UniformOutput',false);
        nSuccessesPerBout{ii} = cellfun(@numel,successesPerBout{ii});
        firstSuccessLatencyPerBout{ii} = cellfun(@(t) ternaryfun(isempty(t),@() Inf,@() t(1)),successesPerBout{ii});

        successfulTrials = nSuccessesPerBout{ii} > 0;
        nSuccessfulTrials(ii) = sum(successfulTrials);
        percentSuccessfulTrials(ii) = 100*nSuccessfulTrials(ii)/numel(boutStartTimes{ii});

        lickIndices = [false;diff(phaseData(ii).licks) > 0];
        lickTimes{ii} = phaseData(ii).timestamps(lickIndices);
        licksPerBout{ii} = arrayfun(@(s,e) lickTimes{ii}(lickTimes{ii} >= s & lickTimes{ii} < e)-s,boutStartTimes{ii},boutEndTimes{ii},'UniformOutput',false);
        nLicksPerBout{ii} = cellfun(@numel,licksPerBout{ii});
        secondLickLatencyPerBout{ii} = cellfun(@(t) ternaryfun(numel(t) < 2,@() Inf,@() t(2)),licksPerBout{ii}); % the first lick latency is always zero because that's what starts the bout
        
        [session,mouseIndex] = ind2sub(size(phaseData),ii);
        theTitle = sprintf('Day %s cage %s mouse %s session %d',day,cage,uniqueNames{mouseIndex},session); %#ok<IDISVAR,USENS>

        figure;
        plot([firstSuccessLatencyPerBout{ii} secondLickLatencyPerBout{ii}],'Marker','o');
        legend({'First Reward' 'Second Lick'});
        title(theTitle);
        xlabel('Trial #');
        ylabel('Latency (s)');

        figure;
        plot([nSuccessesPerBout{ii} nLicksPerBout{ii}],'Marker','o');
        legend({'Successes' 'Licks'});
        title(theTitle);
        xlabel('Trial #');
        ylabel('#');

        licksPerSuccessPerBout{ii} = nLicksPerBout{ii}./nSuccessesPerBout{ii};
        lickSuccessCorrelation(ii) = corr(nLicksPerBout{ii},nSuccessesPerBout{ii}).^2;

        
        wastedLicks(ii) = sum(lickIndices(phaseData(ii).state >= 13));
        percentWastedLicks(ii) = 100*wastedLicks(ii)/sum(lickIndices);

        figure;
        hold on;

        colours = 'rb';

        for jj = 1:numel(boutStartTimes{ii})
            boutIndices = phaseData(ii).timestamps > boutStartTimes{ii}(jj)-5-5*(~isTrialBased) & phaseData(ii).timestamps < boutEndTimes{ii}(jj) - 10*(~isTrialBased);
            boutStartIndex = phaseData(ii).timestamps == boutStartTimes{ii}(jj);

            for kk = 1:2
                plot(phaseData(ii).timestamps(boutIndices)-boutStartTimes{ii}(jj),phaseData(ii).angle(boutIndices,kk)-phaseData(ii).angle(boutStartIndex,kk),'Color',colours(kk));
            end
        end
        
        legend({'Left Wheel' 'Right Wheel'});

        line([0 0],ylim,'Color','k','LineStyle','--');
        
        title(theTitle);

        xlim([-5-5*(~isTrialBased) max(boutLengths{ii})]);

        xlabel('Time from bout onset (s)');
        ylabel('Angle relative to start of bout onset (degrees)');
        
        toc;
    end
    
    nBouts = cellfun(@numel,boutLengths); %#ok<NASGU>
    medianInterBoutInterval = cellfun(@median,interBoutIntervals); %#ok<NASGU>
    
    save(file,'-append','boutStartTimes','boutEndTimes','boutLengths','percentEngagedTime','successesPerBout','nSuccessesPerBout','firstSuccessLatencyPerBout','nSuccessfulTrials','percentSuccessfulTrials','lickTimes','licksPerBout','nLicksPerBout','secondLickLatencyPerBout','licksPerSuccessPerBout','lickSuccessCorrelation','wastedLicks','percentWastedLicks','interBoutIntervals','medianInterBoutInterval','nBouts');
end