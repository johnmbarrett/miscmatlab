function selfInitiatedWheelPlots(file)
    [timestamps,angle,state,~,successIndices,~,~,~,cuePeriod,~,cumulativeSuccesses,cumulativeFailures,totalRewards] = loadRotencFile(file);
    
    figure
    subplot(3,1,1);
    plot(timestamps/60,angle);
    xlabel('Time (min)');
    ylabel('Angle (degrees)');
    
    subplot(3,1,2);
    plot(timestamps/60,cumulativeFailures,timestamps/60,cumulativeSuccesses);
    
    legend({'Unrewards' 'Rewards'},'Location','NorthWest');
    xlabel('Time (min)');
    
    subplot(3,1,3);
    plot(timestamps/60,totalRewards);
    xlabel('Time (min');
    ylabel('Cumulative Rewards'); % TODO : cumulative unrewards
    
    overtitle(file);
    
    rewardPeriodStarts = find(state(2:end) == 1 & state(1:end-1) == 3)+1;
    timeoutStarts = find(state(2:end) == 3 & state(1:end-1) ~= 3)+1;
    rewardAvailableStarts = arrayfun(@(ii) find(timestamps >= timestamps(ii)+cuePeriod(1)/1000,1),[1; timeoutStarts]);
    rewardAvailableStarts = rewardAvailableStarts(1:numel(rewardPeriodStarts));
    
    if numel(timeoutStarts) == numel(rewardPeriodStarts)-1
        rewardPeriodStarts(end) = [];
        rewardAvailableStarts(end) = [];
    elseif numel(timeoutStarts) ~= numel(rewardPeriodStarts)
        error('This shouldn''t happen');
    end
    
    if any(any(diff([rewardAvailableStarts rewardPeriodStarts timeoutStarts],[],2) < 0))
        warning('Something has gone very wrong with file %s',file);
        return
    end
    
    rewardPeriodEnds = timeoutStarts-1;
    timeoutEnds = [rewardAvailableStarts(2:end)-1; find(timestamps <= timestamps(timeoutStarts(end))+cuePeriod(1)/1000,1,'last')]; % TODO : cuePeriod always constant?
    
    assert(all(timeoutEnds > timeoutStarts),'The timeout can not end before it has begun.');
    
    nTrials = numel(rewardPeriodStarts);
    colours = jet(nTrials);
    
    figure;
    
    for ii = 1:nTrials
        subplot(2,1,1)
        hold on;
        
        t0 = timestamps(rewardPeriodStarts(ii));
        a0 = angle(rewardPeriodStarts(ii));
        
        trialIndices = rewardAvailableStarts(ii):timeoutEnds(ii);
        t = timestamps(trialIndices)-t0;
        
        plot(t,angle(trialIndices)-a0,'Color',colours(ii,:));
        
        subplot(2,1,2);
        hold on;
        
        plot(t,cumulativeFailures(trialIndices),t,cumulativeSuccesses(trialIndices),'Color',colours(ii,:));
    end
    
    ylabels = {'Relative angle (degrees)' '(Un)rewards'};
    
    for ii = 1:2
        subplot(2,1,ii);
        line(repmat([timestamps(rewardPeriodStarts(end))-t0 timestamps(timeoutStarts(end))-t0],2,1),repmat(ylim',1,2),'Color','k','LineStyle','--');
        xlim([-cuePeriod(1)/1000 timestamps(timeoutEnds(end))-t0]);
        xlabel('Time from reward period start (s)');
        ylabel(ylabels{ii});
    end
    
    overtitle(file);
    
    unrewards = cumulativeFailures(timeoutEnds);
    rewards = cumulativeSuccesses(rewardPeriodEnds);
    
    initiationLatency = timestamps(rewardPeriodStarts)-timestamps(rewardAvailableStarts);
    firstRewardLatency = arrayfun(@(r,s) ternaryfun(r == 0,@Inf,@() timestamps(find(successIndices >= s,1))),rewards,rewardPeriodStarts);
    
    usefulEffort = arrayfun(@(s,e) sum(abs(diff(angle(s:e)))),rewardPeriodStarts,rewardPeriodEnds);
    wastedEffort = arrayfun(@(s,e) sum(abs(diff(angle(s:e)))),timeoutStarts,timeoutEnds);
    
    rewardIndex = (rewards-unrewards)./(rewards+unrewards);
    effortIndex = (usefulEffort-wastedEffort)./(usefulEffort+wastedEffort);
    
    datas = {unrewards initiationLatency wastedEffort rewardIndex; rewards firstRewardLatency usefulEffort effortIndex};
    legends = {{'Unrewards' 'Rewards'} {'Initiation Latency' 'First Reward Latency'} {'Wasted Effort' 'Useful Effort'} {'Reward Index' 'Effort Index'}};
    ylabels = {'' 'Time (s)' 'Turn distance (degrees)' ''};
    
    figure
    for ii = 1:4
        subplot(2,2,ii);
        hold on;
        plot(datas{1,ii},'Marker','o');
        plot(datas{2,ii},'Marker','o');
        legend(legends{ii},'Location','Best');
        xlabel('Trial #');
        xlim([0.5 nTrials+0.5]);
        ylabel(ylabels{ii});
    end
    
    overtitle(file);
end