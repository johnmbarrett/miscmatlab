function basicWheelPlots(isPlotsToBeSaved)
    files = dir('*.txt'); % TODO : order
    files = {files.name};

    nameRegex = '^(.+)_session_([0-9]+)';
    tokens = cellfun(@(s) regexp(s,nameRegex,'tokens'),files,'UniformOutput',false);

    names = cellfun(@(A) A{1}{1},tokens,'UniformOutput',false);
    sessions = cellfun(@(A) str2double(A{1}{2}),tokens);

    [uniqueNames,~,nameIndices] = unique(names);
    nNames = numel(uniqueNames);
    nSessions = max(sessions);
    
    [folderAbove,cageNumberString] = fileparts(pwd);
    
    saveFile = [cageNumberString '_basic_wheel_data.mat'];
    
%     if exist(saveFile,'file')
% %         save(saveFile,'-append','uniqueNames','cageNumberString');
%         return
%     end

    direction = nan(nSessions,nNames); % -1 = clockwise, 0 = bidirectional, +1 = anticlockwise
    successRate = nan(nSessions,nNames);
    firstRewardLatency = inf(nSessions,nNames);
    angleBias = nan(nSessions,nNames);
    turnBias = nan(nSessions,nNames);
    crossoverLatency = inf(nSessions,nNames);
    maxTurnDistance = nan(nSessions,nNames);
    totalTurnDistance = nan(nSessions,nNames);
    averageTurnSpeed = nan(nSessions,nNames);
    maxTurnSpeed = nan(nSessions,nNames);
    engagement = nan(nSessions,nNames);
    engagedSuccessRate = nan(nSessions,nNames);
    
    sessionData = struct(   ...
        'timestamps',           cell(nSessions,nNames), ...
        'angle',                cell(nSessions,nNames), ...
        'state',                cell(nSessions,nNames), ...
        'threshold',            cell(nSessions,nNames), ...
        'successIndices',       cell(nSessions,nNames), ...
        'successTimes',         cell(nSessions,nNames), ...
        'learningCurve',        cell(nSessions,nNames), ...
        'phase',                cell(nSessions,nNames), ...
        'cuePeriod',            cell(nSessions,nNames), ...
        'cumulativeRewards',    cell(nSessions,nNames), ...
        'cumulativeSuccesses',  cell(nSessions,nNames), ...
        'cumulativeFailures',   cell(nSessions,nNames), ...
        'totalRewards',         cell(nSessions,nNames), ...
        'relativeAngle',        cell(nSessions,nNames), ...
        'positiveThreshold',    cell(nSessions,nNames), ...
        'negativeThreshold',    cell(nSessions,nNames), ...
        'rewardPeriodStarts',   cell(nSessions,nNames), ...
        'rewardPeriodEnds',     cell(nSessions,nNames), ...
        'turnAngles',           cell(nSessions,nNames), ...
        'turnDurations',        cell(nSessions,nNames), ...
        'turnSpeeds',           cell(nSessions,nNames)  ...
        );

    for ii = 1:numel(files)
        tic;
        [timestamps,angle,state,threshold,successIndices,successTimes,learningCurve,phase,cuePeriod,cumulativeRewards,cumulativeSuccesses,cumulativeFailures,totalRewards] = loadRotencFile(files{ii});
        toc;
        
        tic;
        sessionData(sessions(ii),nameIndices(ii)).timestamps = timestamps;
        sessionData(sessions(ii),nameIndices(ii)).angle = angle;
        sessionData(sessions(ii),nameIndices(ii)).state = state;
        sessionData(sessions(ii),nameIndices(ii)).threshold = threshold;
        sessionData(sessions(ii),nameIndices(ii)).successIndices = successIndices;
        sessionData(sessions(ii),nameIndices(ii)).successTimes = successTimes;
        sessionData(sessions(ii),nameIndices(ii)).learningCurve = learningCurve;
        sessionData(sessions(ii),nameIndices(ii)).phase = phase;
        sessionData(sessions(ii),nameIndices(ii)).cuePeriod = cuePeriod;
        sessionData(sessions(ii),nameIndices(ii)).cumulativeRewards = cumulativeRewards;
        sessionData(sessions(ii),nameIndices(ii)).cumulativeSuccesses = cumulativeSuccesses;
        sessionData(sessions(ii),nameIndices(ii)).cumulativeFailures = cumulativeFailures;
        sessionData(sessions(ii),nameIndices(ii)).totalRewards = totalRewards;

        if isempty(timestamps)
            continue
        end

        rewardPeriodStarts = [1;find(state(1:end-1) ~= 1 & state(2:end) == 1)+1];

        rewardPeriodEnds = find(state(1:end-1) == 1 & state(2:end) ~= 1)+1;
        
        if isempty(rewardPeriodEnds)
            rewardPeriodEnds = numel(timestamps);
        end
        
        sessionData(sessions(ii),nameIndices(ii)).rewardPeriodStarts = rewardPeriodStarts;
        sessionData(sessions(ii),nameIndices(ii)).rewardPeriodEnds = rewardPeriodEnds;

    %     if numel(rewardPeriodEnds) < numel(rewardPeriodStarts)
    %         rewardPeriodEnds(end+1) = numel(timestamps); %#ok<SAGROW>
    %     end

    %     assert(numel(rewardPeriodEnds) == numel(rewardPeriodStarts) && all(rewardPeriodStarts < rewardPeriodEnds));
        assert(all(rewardPeriodStarts(1:numel(rewardPeriodEnds)) < rewardPeriodEnds));

        relativeAngle = angle;
        positiveThreshold = zeros(size(angle));
        negativeThreshold = zeros(size(angle));

        for jj = 1:numel(rewardPeriodStarts)
            relativeAngle(rewardPeriodStarts(jj):end) = relativeAngle(rewardPeriodStarts(jj):end)-relativeAngle(rewardPeriodStarts(jj));

            if jj < numel(rewardPeriodStarts)
                idx = rewardPeriodStarts(jj):(rewardPeriodStarts(jj+1)-1);
            else
                idx = rewardPeriodStarts(end):numel(timestamps);
            end

            angleAtBeginningOfRewardPeriod = angle(rewardPeriodStarts(jj));
            positiveThreshold(idx) = angleAtBeginningOfRewardPeriod + threshold(idx);
            negativeThreshold(idx) = angleAtBeginningOfRewardPeriod - threshold(idx);
        end
        
        sessionData(sessions(ii),nameIndices(ii)).relativeAngle = relativeAngle;
        sessionData(sessions(ii),nameIndices(ii)).positiveThreshold = positiveThreshold;
        sessionData(sessions(ii),nameIndices(ii)).negativeThreshold = negativeThreshold;
        
        maxTurnDistance(sessions(ii),nameIndices(ii)) = max(abs(relativeAngle));

        successRate(sessions(ii),nameIndices(ii)) = numel(successIndices)/timestamps(end);
        
        if ~isempty(successTimes)
            firstRewardLatency(sessions(ii),nameIndices(ii)) = successTimes(1);
        end

        dAngle = diff(angle);
        totalTurnDistance(sessions(ii),nameIndices(ii)) = sum(abs(dAngle));
%         averageTurnSpeed(sessions(ii),nameIndices(ii)) = totalTurnDistance(sessions(ii),nameIndices(ii))/timestamps(end);
        angleBias(sessions(ii),nameIndices(ii)) = (sum(dAngle(dAngle > 0)) - sum(-dAngle(dAngle < 0)))/totalTurnDistance(sessions(ii),nameIndices(ii));
        
        turnAngles = angle(rewardPeriodEnds)-angle(rewardPeriodStarts(1:numel(rewardPeriodEnds)));
        turnDurations = timestamps(rewardPeriodEnds)-timestamps(rewardPeriodStarts(1:numel(rewardPeriodEnds)));
        turnSpeeds = abs(turnAngles)./turnDurations;
        
        sessionData(sessions(ii),nameIndices(ii)).turnAngles = turnAngles;
        sessionData(sessions(ii),nameIndices(ii)).turnDurations = turnDurations;
        sessionData(sessions(ii),nameIndices(ii)).turnSpeeds = turnSpeeds;
        
        averageTurnSpeed(sessions(ii),nameIndices(ii)) = median(turnSpeeds);
        maxTurnSpeed(sessions(ii),nameIndices(ii)) = max(turnSpeeds);
        
        dTime = diff(timestamps);
        
        engagedTime = sum(dTime(dAngle ~= 0));
        engagement(sessions(ii),nameIndices(ii)) = engagedTime/timestamps(end);
        engagedSuccessRate(sessions(ii),nameIndices(ii)) = numel(successIndices)/engagedTime;
        toc;

        tic;
        figure;

        subplot(2,2,1);
        plot(timestamps,angle,timestamps,positiveThreshold,timestamps,negativeThreshold);
    %     hold on;
    %     line(repmat(timestamps(rewardPeriodStarts)',2,1),repmat(ylim',1,numel(rewardPeriodStarts)),'Color','k','LineStyle','--');
        legend({'Wheel' '+ve Threshold' '-ve Threshold'},'Location','Best');
        xlabel('Time (s)');
        xlim([0 timestamps(end)]);
        ylabel('Angle (degrees)');

        subplot(2,2,2);
        plot(timestamps,relativeAngle,timestamps,threshold,timestamps,-threshold);
        legend({'Wheel' '+ve Threshold' '-ve Threshold'},'Location','Best');
        xlabel('Time (s)');
        xlim([0 timestamps(end)]);
        ylabel('Relative Angle (degrees)');

        thePhase = unique(phase);

        if ~isscalar(thePhase)
            [~,dateString] = fileparts(folderAbove);
            fprintf('Check day %s cage %s mouse %s session %d\n',dateString,cageNumberString,names{ii},sessions(ii));
            return
        end
        
        direction(sessions(ii),nameIndices(ii)) = 1.5*thePhase^2-5.5*thePhase+4;

        isUnilateral = thePhase > 1;

        subplot(2,2,3);

        if isUnilateral
            plot(timestamps,[cumulativeFailures cumulativeSuccesses]);
            legend({'Unrewarded Turns' 'Rewarded Turns'},'Location','Best');
            xlabel('Time (s)');
            xlim([0 timestamps(end)]);
            ylabel('# Above-Threshold Turns');

            turnBias(sessions(ii),nameIndices(ii)) = (2*thePhase-5)*(cumulativeSuccesses(end)-cumulativeFailures(end))/(cumulativeSuccesses(end)+cumulativeFailures(end));

            crossover = find(cumulativeSuccesses <= cumulativeFailures,1,'last')+1;

            if isempty(crossover)
                crossoverLatency(sessions(ii),nameIndices(ii)) = 0;
            elseif crossover <= numel(cumulativeSuccesses)
                crossoverLatency(sessions(ii),nameIndices(ii)) = timestamps(crossover);
            end
        else
            plot(successTimes,learningCurve);
            xlabel('Time (s)');
            xlim([0 timestamps(end)]);
            ylabel('# Rewards');

            turnBias(sessions(ii),nameIndices(ii)) = (sum(relativeAngle(successIndices) > 0)-sum(relativeAngle(successIndices) < 0))/numel(successIndices);
        end

        t = -0.5:0.001:0.5;
        x = nan(numel(t),numel(rewardPeriodEnds));

        for jj = 1:size(x,2)
            tdash = timestamps(rewardPeriodEnds(jj))+t;

            badIdx = tdash <= timestamps(rewardPeriodStarts(jj));

            if jj < numel(rewardPeriodEnds)
                badIdx = badIdx | tdash >= timestamps(rewardPeriodEnds(jj+1));
            end

            x(~badIdx,jj) = interp1(timestamps,(angle-angle(rewardPeriodStarts(jj)))/threshold(rewardPeriodEnds(jj)-1),tdash(~badIdx));
        end

        isGood = ismember(rewardPeriodEnds-1,successIndices);
        ax = subplot(2,2,4);
        colours = get(ax,'ColorOrder');
        
        if any(isGood)
            plot(t,x(:,isGood),'Color',colours(2,:));
        end

        if ~all(isGood)
            hold on;
            plot(t,x(:,~isGood),'Color',colours(1,:));
        end

        line([0 0],ylim,'Color','k','LineStyle','--');
        xlabel('Time relative to threshold crossing (s)');
        ylabel('Angle relative to threshold (degrees)');

        name = names{ii};
        fakeAxis = subplot('Position',[0.5 0.975 0 0]);
        set(fakeAxis,'Visible','off');
        plot(fakeAxis,0,0);
        text(0,0,sprintf('%s%s session #%d',upper(name(1)),name(2:end),sessions(ii)),'FontSize',16,'FontWeight','bold','HorizontalAlignment','center','Parent',fakeAxis,'VerticalAlignment','middle');
        toc;

        tic;
        if nargin > 0 && isPlotsToBeSaved
            jbsavefig('%s%s_session_%d_basic_plots',upper(name(1)),name(2:end),sessions(ii));
        end
        toc;
    end
    %%
    
    tic;
    save(saveFile,'uniqueNames','cageNumberString','maxTurnDistance','totalTurnDistance','averageTurnSpeed','maxTurnSpeed','sessionData','successRate','firstRewardLatency','angleBias','turnBias','crossoverLatency','engagement','engagedSuccessRate');
    toc;
    
    datas = {successRate firstRewardLatency angleBias turnBias crossoverLatency maxTurnDistance totalTurnDistance averageTurnSpeed maxTurnSpeed engagement engagedSuccessRate};
    ylabels = {'Rewards per Second' 'First Reward Latency (s)' 'Angular Bias' 'Turn Bias' 'Crossover Latency (s)' 'Max Turn Distance (°)' 'Total Turn Distance (°)' 'Average Turn Speed (°/s)' 'Max Turn Speed (°/s)' 'Percent Time Engaged' 'Rewards per Engaged Second'};

    for ii = 1:numel(datas)
        tic;
        figure
        plot(datas{ii},'Marker','o');
        legend(uniqueNames,'Location','Best');
        set(gca,'XTick',1:nSessions);
        xlim([0.5 nSessions+0.5]);
        xlabel('Session #');
        ylabel(ylabels{ii});
        jbsavefig('%s_%s',cageNumberString,strrep(regexprep(lower(ylabels{ii}),' \(.*\)',''),' ','_'));
        toc;
    end
end