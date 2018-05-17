function multiPhaseWheelPlots(isPlotsToBeSaved,isTwoWheels,successStates,isLickometer)
    files = dir('*.BIN'); % TODO : order
    
    if isempty(files)
        files = dir('*.txt');
    end
    
    files = {files.name};

    nameRegex = '(.+)_session_([0-9]+)';
    tokens = cellfun(@(s) regexp(s,nameRegex,'tokens'),files,'UniformOutput',false);

    names = cellfun(@(A) A{1}{1},tokens,'UniformOutput',false);

    [uniqueNames,~,nameIndices] = unique(names);
    nNames = numel(uniqueNames);
    
    sessions = [nameIndices cellfun(@(A) str2double(A{1}{2}),tokens)'];
    sessionIndices = zeros(size(nameIndices));
    
    for ii = 1:nNames
        [~,sessionIndices(nameIndices == ii)] = sort(sessions(nameIndices == ii));
    end
    
    nSessions = max(sessionIndices);
    
    isOnePhasePerFile = nSessions > 1;
    
    [folderAbove,cageNumberString] = fileparts(pwd);
    
    saveFile = [cageNumberString '_multiphase_wheel_data.mat'];
    
%     if exist(saveFile,'file')
% %         save(saveFile,'-append','uniqueNames','cageNumberString');
%         return
%     end

    phaseColours = [0.8 1 0.8; 1 0.8 0.8; 0.8 0.8 1]; % bi, cw, ccw
    
    columns = {'timestamps' 'angle' 'angle' 'state' 'totalRewards'};
    
    if isLickometer
        columns(end+(1:3)) = {'rewardedWheel' 'null' 'lickometer'};
        columns = columns([1:3 5:8 4]);
        structSize = 32;
        structFormat = [4 4 4 4 4 4 4 1];
        isUnsigned = [true false(1,3) true(1,4)];
    else
        structSize = 20;
        structFormat = [4 4 4 1 2 2 2 1];
        isUnsigned = [true false(1,7)];
    end

    for ii = 1:numel(files)
        tic;
        if nargin > 1 && isTwoWheels
            if nargin < 3
                successStates = 6:9;
            end
            
            [timestamps,angle,state,~,successIndices,successTimes,learningCurve,~,~,~,~,~,totalRewards,licks] = loadRotencFile(files{ii},'Columns',columns,'StructSize',structSize,'StructFormat',structFormat,'StructIsUnsigned',isUnsigned,'SuccessStates',successStates);
            threshold = 110*ones(size(angle));
            cumulativeRewards = totalRewards; 
            cumulativeSuccesses = totalRewards;
            cumulativeFailures = zeros(size(totalRewards));
            phase = ones(size(timestamps));
            cuePeriod = nan(size(timestamps));
        else
            [timestamps,angle,state,threshold,successIndices,successTimes,learningCurve,phase,cuePeriod,cumulativeRewards,cumulativeSuccesses,cumulativeFailures,totalRewards] = loadRotencFile(files{ii});
        end
        toc;
        
        phase = abs(phase);
        
%         uniquePhases = unique(phase);
        [~,dateString] = fileparts(folderAbove);
        
        impossiblePhases = ~ismember(phase,0:3);
        
        if any(impossiblePhases)
            warning('Out of range phases detected, please check day %s cage %s mouse %s\n',dateString,cageNumberString,names{ii});
        end
        
        theEnd = find(state == 4,1)-1;
        
        if isempty(theEnd)
            theEnd = numel(phase);
        end
        
        phaseEnds = [find(diff(phase)); theEnd];
        phaseStarts = [1; phaseEnds(1:end-1)+1];
        
        implausiblePhases = isOnePhasePerFile & numel(phaseStarts) > 1 & phase ~= mode(phase);
        
        if any(implausiblePhases)
            warning('Multiple phases found in single-phase file, please check day %s cage %s mouse %s sessions %d\n',dateString,cageNumberString,names{ii},sessionIndices(ii));
        end

        if ~exist('nPhases','var')
            if ~isOnePhasePerFile
                nPhases = numel(phaseStarts);
            else
                nPhases = nSessions;
            end
            
            direction = nan(nPhases,nNames); % -1 = clockwise, 0 = bidirectional, +1 = anticlockwise
            phases = nan(nPhases,nNames);
            successRate = nan(nPhases,nNames);
            maxThreshold = nan(nPhases,nNames);
            learningIndex = nan(nPhases,nNames);
            firstRewardLatency = inf(nPhases,nNames);
            angleBias = nan(nPhases,nNames,size(angle,2));
            turnBias = nan(nPhases,nNames,size(angle,2));
            crossoverLatency = inf(nPhases,nNames);
            averageTurnDistance = nan(nPhases,nNames,size(angle,2));
            maxTurnDistance = nan(nPhases,nNames,size(angle,2));
            totalTurnDistance = nan(nPhases,nNames,size(angle,2));
            averageTurnSpeed = nan(nPhases,nNames,size(angle,2));
            maxTurnSpeed = nan(nPhases,nNames,size(angle,2));
            engagement = nan(nPhases,nNames);
            engagedSuccessRate = nan(nPhases,nNames);
            
            phaseData = struct(   ...
                'timestamps',           cell(nPhases,nNames), ...
                'angle',                cell(nPhases,nNames), ...
                'state',                cell(nPhases,nNames), ...
                'threshold',            cell(nPhases,nNames), ...
                'successIndices',       cell(nPhases,nNames), ...
                'successTimes',         cell(nPhases,nNames), ...
                'learningCurve',        cell(nPhases,nNames), ...
                'phase',                cell(nPhases,nNames), ...
                'cuePeriod',            cell(nPhases,nNames), ...
                'cumulativeRewards',    cell(nPhases,nNames), ...
                'cumulativeSuccesses',  cell(nPhases,nNames), ...
                'cumulativeFailures',   cell(nPhases,nNames), ...
                'successes',            cell(nPhases,nNames), ...
                'failures',             cell(nPhases,nNames), ...
                'totalRewards',         cell(nPhases,nNames), ...
                'relativeAngle',        cell(nPhases,nNames), ...
                'positiveThreshold',    cell(nPhases,nNames), ...
                'negativeThreshold',    cell(nPhases,nNames), ...
                'rewardPeriodStarts',   cell(nPhases,nNames), ...
                'rewardPeriodEnds',     cell(nPhases,nNames), ...
                'turnAngles',           cell(nPhases,nNames), ...
                'turnDurations',        cell(nPhases,nNames), ...
                'turnSpeeds',           cell(nPhases,nNames), ...
                'licks',                cell(nPhases,nNames)  ...
                );
        elseif ~isOnePhasePerFile && numel(phaseStarts) ~= nPhases
            fprintf('Check day %s cage %s mouse %s\n',dateString,cageNumberString,names{ii});
            return            
        end
    
        if isempty(timestamps)
            continue
        end

        rewardPeriodStarts = [1;find(state(1:end-1) ~= 1 & state(2:end) == 1)+1];

        rewardPeriodEnds = find(state(1:end-1) == 1 & state(2:end) ~= 1)+1;
        
        if isempty(rewardPeriodEnds) || rewardPeriodStarts(2) < rewardPeriodEnds(1) % self-initiated, so first rewardPeriod starting at sample 1 was wrong
            rewardPeriodStarts(1) = [];
        end
        
        if numel(rewardPeriodEnds) < numel(rewardPeriodStarts)
            rewardPeriodEnds(end+1,1) = numel(state); %#ok<AGROW>
        end
        
        assert((isempty(rewardPeriodStarts) && isempty(rewardPeriodEnds)) || all(rewardPeriodStarts(1:numel(rewardPeriodEnds)) <= rewardPeriodEnds));
        
        if isempty(rewardPeriodEnds)
            rewardPeriodEnds = numel(timestamps);
        end
        
        relativeAngle = angle;
        positiveThreshold = zeros(size(angle));
        negativeThreshold = zeros(size(angle));

        for jj = 1:numel(rewardPeriodStarts)
            relativeAngle(rewardPeriodStarts(jj):end,:) = relativeAngle(rewardPeriodStarts(jj):end,:)-relativeAngle(rewardPeriodStarts(jj),:);

            if jj < numel(rewardPeriodStarts)
                idx = rewardPeriodStarts(jj):(rewardPeriodStarts(jj+1)-1);
            else
                idx = rewardPeriodStarts(end):numel(timestamps);
            end

            angleAtBeginningOfRewardPeriod = angle(rewardPeriodStarts(jj),:);
            positiveThreshold(idx,:) = bsxfun(@plus,angleAtBeginningOfRewardPeriod,threshold(idx,:));
            negativeThreshold(idx,:) = bsxfun(@minus,angleAtBeginningOfRewardPeriod,threshold(idx,:));
        end
        
        %     if numel(rewardPeriodEnds) < numel(rewardPeriodStarts)
    %         rewardPeriodEnds(end+1) = numel(timestamps); %#ok<SAGROW>
    %     end

    %     assert(numel(rewardPeriodEnds) == numel(rewardPeriodStarts) && all(rewardPeriodStarts < rewardPeriodEnds));
    
        successes = cumulativeSuccesses;
        failures = cumulativeFailures;
        
        if isOnePhasePerFile
            jjj = sessionIndices(ii);
        else
            jjj = 1:nPhases;
        end
        
        goodPhases = find(~impossiblePhases & ~implausiblePhases);
        
        for jj = jjj
            if isOnePhasePerFile
                phaseIndices = goodPhases;
            else
                phaseIndices = goodPhases(phaseStarts(jj):phaseEnds(jj));
            end
            
            tic;
            timestampsInPhase = timestamps(phaseIndices);
            phaseData(jj,nameIndices(ii)).timestamps = timestampsInPhase;
            
            angleInPhase = angle(phaseIndices,:);
            phaseData(jj,nameIndices(ii)).angle = angleInPhase;
            phaseData(jj,nameIndices(ii)).state = state(phaseIndices);
            phaseData(jj,nameIndices(ii)).threshold = threshold(phaseIndices,:);
            phaseData(jj,nameIndices(ii)).phase = phase(phaseIndices);
            phaseData(jj,nameIndices(ii)).cuePeriod = cuePeriod(phaseIndices);
            phaseData(jj,nameIndices(ii)).cumulativeRewards = cumulativeRewards(phaseIndices);
            
            phaseData(jj,nameIndices(ii)).cumulativeSuccesses = cumulativeSuccesses(phaseIndices);
            phaseData(jj,nameIndices(ii)).cumulativeFailures = cumulativeFailures(phaseIndices);
            
            if isOnePhasePerFile
                phaseData(jj,nameIndices(ii)).successes = cumulativeSuccesses(phaseIndices);
                phaseData(jj,nameIndices(ii)).failures = cumulativeFailures(phaseIndices);
                
                if jj > 1
                    phaseData(jj,nameIndices(ii)).cumulativeSuccesses = phaseData(jj,nameIndices(ii)).cumulativeSuccesses + phaseData(jj-1,nameIndices(ii)).cumulativeSuccesses(end);
                    phaseData(jj,nameIndices(ii)).cumulativeFailures = phaseData(jj,nameIndices(ii)).cumulativeFailures + phaseData(jj-1,nameIndices(ii)).cumulativeFailures(end);
                end
            elseif jj < nPhases
               successes((phaseIndices(end)+1):end) = successes((phaseIndices(end)+1):end) - successes(phaseIndices(end)); 
               failures((phaseIndices(end)+1):end) = failures((phaseIndices(end)+1):end) - failures(phaseIndices(end));
               
                phaseData(jj,nameIndices(ii)).successes = successes(phaseIndices);
                phaseData(jj,nameIndices(ii)).failures = failures(phaseIndices);
            end
            
            learningIndex(jj,nameIndices(ii)) = (successes(phaseIndices(end))-failures(phaseIndices(end)))/(successes(phaseIndices(end))+failures(phaseIndices(end)));
            
            if isnan(learningIndex(jj,nameIndices(ii)))
                learningIndex(jj,nameIndices(ii)) = 0;
            end
            
            phaseData(jj,nameIndices(ii)).successes = successes(phaseIndices);
            phaseData(jj,nameIndices(ii)).failures = failures(phaseIndices);
            
            phaseData(jj,nameIndices(ii)).totalRewards = totalRewards(phaseIndices);

            isSuccessInPhase = successIndices >= phaseIndices(1) & successIndices <= phaseIndices(end);
            
            successIndicesInPhase = successIndices(isSuccessInPhase);
            phaseData(jj,nameIndices(ii)).successIndices = successIndicesInPhase;
            
            successTimesInPhase = successTimes(isSuccessInPhase);
            phaseData(jj,nameIndices(ii)).successTimes = successTimesInPhase;
            phaseData(jj,nameIndices(ii)).learningCurve = learningCurve(isSuccessInPhase);

            isRewardPeriodStartInPhase = rewardPeriodStarts >= phaseIndices(1) & rewardPeriodStarts <= phaseIndices(end);
            phaseData(jj,nameIndices(ii)).rewardPeriodStarts = rewardPeriodStarts(isRewardPeriodStartInPhase);
            phaseData(jj,nameIndices(ii)).rewardPeriodEnds = rewardPeriodEnds(rewardPeriodEnds >= phaseIndices(1) & rewardPeriodEnds <= phaseIndices(end));
        
            phaseData(jj,nameIndices(ii)).relativeAngle = relativeAngle(phaseIndices,:);
            phaseData(jj,nameIndices(ii)).positiveThreshold = positiveThreshold(phaseIndices,:);
            phaseData(jj,nameIndices(ii)).negativeThreshold = negativeThreshold(phaseIndices,:);
        
            maxTurnDistance(jj,nameIndices(ii),:) = max(abs(relativeAngle(phaseIndices,:)));

            timeInPhase = diff(timestampsInPhase([1 end]));
            successRate(jj,nameIndices(ii)) = numel(successIndicesInPhase)/timeInPhase;
            
            maxThreshold(jj,nameIndices(ii)) = max(threshold(phaseIndices));
        
            if ~isempty(successTimesInPhase)
                firstRewardLatency(jj,nameIndices(ii)) = successTimesInPhase(1)-timestampsInPhase(1);
            end

            dAngle = diff(angleInPhase);
            totalTurnDistance(jj,nameIndices(ii),:) = sum(abs(dAngle));
%             averageTurnSpeed(sessions(ii),nameIndices(ii)) = totalTurnDistance(sessions(ii),nameIndices(ii))/timestamps(end);
            angleBias(jj,nameIndices(ii)) = (sum(dAngle(dAngle > 0)) - sum(-dAngle(dAngle < 0)))/totalTurnDistance(jj,nameIndices(ii));
        
            turnAngles = angle(rewardPeriodEnds(isRewardPeriodStartInPhase),:)-angle(rewardPeriodStarts(isRewardPeriodStartInPhase),:);
            turnDurations = timestamps(rewardPeriodEnds(isRewardPeriodStartInPhase))-timestamps(rewardPeriodStarts(isRewardPeriodStartInPhase)); % TODO : this overestimates the turn durations for the first turn of each phase
            turnSpeeds = abs(turnAngles)./turnDurations;
        
            phaseData(jj,nameIndices(ii)).turnAngles = turnAngles;
            phaseData(jj,nameIndices(ii)).turnDurations = turnDurations;
            phaseData(jj,nameIndices(ii)).turnSpeeds = turnSpeeds;
        
            if isempty(turnAngles)
                averageTurnDistance(jj,nameIndices(ii),:) = 0;
                averageTurnSpeed(jj,nameIndices(ii),:) = 0;
                maxTurnSpeed(jj,nameIndices(ii),:) = 0;
            else
                averageTurnDistance(jj,nameIndices(ii),:) = median(turnAngles);
                averageTurnSpeed(jj,nameIndices(ii),:) = median(turnSpeeds);
                maxTurnSpeed(jj,nameIndices(ii),:) = max(turnSpeeds);
            end
        
            dTime = diff(timestampsInPhase);
        
            engagedTime = sum(dTime(any(dAngle ~= 0,2)));
            engagement(jj,nameIndices(ii)) = engagedTime/timeInPhase;
            engagedSuccessRate(jj,nameIndices(ii)) = numel(successIndicesInPhase)/engagedTime;
            
            if isOnePhasePerFile
                thePhase = mode(phase);
            else
                thePhase = phase(phaseStarts(jj));
            end
            
            phases(jj,nameIndices(ii)) = thePhase;
            direction(jj,nameIndices(ii)) = 1.5*thePhase^2-5.5*thePhase+4;
            
            if thePhase > 1
                turnBias(jj,nameIndices(ii)) = (2*thePhase-5)*(cumulativeSuccesses(phaseIndices(end))-cumulativeFailures(phaseIndices(end)))/(cumulativeSuccesses(phaseIndices(end))+cumulativeFailures(phaseIndices(end)));

                % TODO : should reset cumulativeSuccesses and Failures to
                % zero at the beginning of each phase for this analysis
                crossover = phaseIndices(find(successes(phaseIndices) <= failures(phaseIndices),1,'last'))+1;

                if isempty(crossover)
                    crossoverLatency(jj,nameIndices(ii)) = 0;
                elseif crossover <= numel(successes)
                    crossoverLatency(jj,nameIndices(ii)) = timestamps(crossover)-timestampsInPhase(1);
                end
            else
                turnBias(jj,nameIndices(ii),:) = (sum(relativeAngle(successIndicesInPhase,:) > 0)-sum(relativeAngle(successIndicesInPhase,:) < 0))/numel(successIndicesInPhase);
            end
            
            phaseData(jj,nameIndices(ii)).licks = licks(phaseIndices);
            toc;
        end
    end

    for ii = 1:nNames
        tic;
        figure;
        
        datas = {                                               ...
            {                                                   ...
                vertcat(phaseData(:,ii).angle)                  ...
                vertcat(phaseData(:,ii).positiveThreshold)      ...
                vertcat(phaseData(:,ii).negativeThreshold)      ...
            } {                                                 ...
                vertcat(phaseData(:,ii).relativeAngle)          ...
                vertcat(phaseData(:,ii).threshold)              ...
               -vertcat(phaseData(:,ii).threshold)              ...
            } {                                                 ...
                vertcat(phaseData(:,ii).cumulativeFailures)     ...
                vertcat(phaseData(:,ii).cumulativeSuccesses)    ...
            } {                                                 ...
                vertcat(phaseData(:,ii).failures)               ...
                vertcat(phaseData(:,ii).successes)              ...
            }                                                   ...
        };
    
        legends = {{'Wheel' 'CCW Threshold' 'CW Threshold'} {'Wheel' 'CCW Threshold' 'CW Threshold'} {'Unrewarded Turns' 'Rewarded Turns'} {'Unrewarded Turns' 'Rewarded Turns'}};
        ylabels = {'Angle (degrees)' 'Relative Angle (degrees)' '# Turns (Cumulative)' '# Turns (Per Phase)'};

        for kk = 1:4
            subplot(2,2,kk);
            hold on;
            
            lineHandles = gobjects(0,1);
            
            % TODO : this works for multiphase files but isn't optimal
            t = {phaseData(:,ii).timestamps};
            
            if isOnePhasePerFile
                for jj = 2:size(phaseData,1)
                    if isempty(t{jj})
                        continue
                    end
                    
                    t{jj} = t{jj} + t{find(~cellfun(@isempty,t(1:(jj-1))),1,'last')}(end);
                end
            end
            
            for jj = 1:numel(datas{kk})
                lineHandles = [lineHandles; plot(vertcat(t{:}),datas{kk}{jj})]; %#ok<AGROW>
            end
            
        %     line(repmat(timestamps(rewardPeriodStarts)',2,1),repmat(ylim',1,numel(rewardPeriodStarts)),'Color','k','LineStyle','--');

            yy = ylim;

            for jj = 1:nPhases
                if isempty(t{jj})
                    continue
                end
                
                fill(t{jj}([1 end end 1]),yy([1 1 2 2]),phaseColours(phases(jj,ii),:),'EdgeColor','none');
            end

            fillHandles = gobjects(3,1);

            for jj = 1:3
                fillHandles(jj) = fill(NaN,NaN,phaseColours(jj,:),'EdgeColor','none');
            end

            uistack(lineHandles(:)','top');

            xlabel('Time (s)');
            xlim([0 t{find(~cellfun(@isempty,t),1,'last')}(end)]);
            ylabel(ylabels{kk});
%             legend([lineHandles; fillHandles],[legends{kk} {'Bidirectional' 'Deasil' 'Widdershins'}],'Location','Best');
        end
        
        name = uniqueNames{ii};
        overtitle(sprintf('%s%s multi-phase session',upper(name(1)),name(2:end)));

        tic;
        if nargin > 0 && isPlotsToBeSaved
            jbsavefig('%s_multiphase_plots',name);
        end
        toc;
        
        continue

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
        toc;
    end
    
    %%
    
    tic;
    save(saveFile,'uniqueNames','cageNumberString','direction','phases','maxThreshold','learningIndex','maxTurnDistance','totalTurnDistance','averageTurnDistance','averageTurnSpeed','maxTurnSpeed','phaseData','successRate','firstRewardLatency','angleBias','turnBias','crossoverLatency','engagement','engagedSuccessRate','direction','phases');
    toc;
    
    datas = {successRate maxThreshold learningIndex firstRewardLatency angleBias turnBias crossoverLatency maxTurnDistance totalTurnDistance averageTurnSpeed maxTurnSpeed engagement engagedSuccessRate};
    ylabels = {'Rewards per Second' 'Max Threshold' 'Learning Index' 'First Reward Latency (s)' 'Angular Bias' 'Turn Bias' 'Crossover Latency (s)' 'Max Turn Distance (°)' 'Total Turn Distance (°)' 'Average Turn Speed (°/s)' 'Max Turn Speed (°/s)' 'Percent Time Engaged' 'Rewards per Engaged Second'};
    directionLabels = {'Bi' 'CW' 'CCW'};

    for ii = 1:2 %:numel(datas)
        tic;
        figure
        plot(datas{ii},'Marker','o');
        legend(uniqueNames,'Location','Best');
        set(gca,'XTick',1:nPhases);
        xlim([0.5 nPhases+0.5]);
        xlabel('Phase #');
        ylabel(ylabels{ii});
        jbsavefig('%s_%s_multiphase',cageNumberString,strrep(regexprep(lower(ylabels{ii}),' \(.*\)',''),' ','_'));
        
        toc;
        continue
        
        figure
        hold on
        colours = get(gca,'ColorOrder');
        [sortedPhases,sortIndices] = sort(phases(:,1));
        hs = gobjects(size(datas{ii},2),1);
        for jj = 1:sortedPhases(end)
            for kk = 1:size(datas{ii},2)
                hs(kk) = plot(find(sortedPhases == jj),datas{ii}(sortIndices(sortedPhases == jj),kk),'Color',colours(kk,:),'Marker','o');
            end
            
            if jj == 1
                legend(hs,uniqueNames,'Location','Best');
            end
        end
        xlim([0.5 size(phases,1)+0.5]);
        yy = ylim;
        phaseTransitions = find(diff(sortedPhases'));
        line(repmat(phaseTransitions+0.5,2,1),repmat(yy',1,numel(phaseTransitions)),'Color','k','LineStyle','--');
        for jj = 1:3
            text(mean(find(sortedPhases == jj)),1.05*yy(2),directionLabels{jj},'HorizontalAlignment','center');
        end
        set(gca,'XTick',[]);
        ylabel(ylabels{ii});
        toc;
    end
end