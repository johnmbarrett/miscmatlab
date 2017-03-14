function [F,dFF0,figs] = makeLaminarFlourescenceChangeProfile(stacks,mask,theta,useFrames,baselineFrames,trialFrames,conditions,videoFile)
    if theta > pi
        theta = theta-pi;
    end

    M = imrotate(mask,rad2deg(theta));
    [ym,xm] = ind2sub(size(M),find(M));
    
    xidx = min(xm):max(xm);
    yidx = min(ym):max(ym);

    if ~iscell(stacks)
        stacks = {stacks};
    end
    
    framesPerStack = cellfun(@(s) size(s,3),stacks);
    assert(std(framesPerStack) == 0); % TODO : not this
    
    if islogical(useFrames)
        assert(numel(useFrames) == framesPerStack(1));
        
        useFrames = find(useFrames);
    elseif isnumeric(useFrames)
        assert(all(useFrames > 0 & useFrames <= framesPerStack(1)));
    else
        useFrames = 1:framesPerStack(1);
    end
    
    nFrames = numel(useFrames);
    assert(nFrames <= framesPerStack(1));
    
    nStacks = numel(stacks);
    F = zeros(numel(yidx),numel(xidx),nStacks*nFrames);
    
    for ii = 1:nStacks
        for jj = 1:nFrames
            tic;
            I = stacks{ii}(:,:,useFrames(jj));
            I = imrotate(I,rad2deg(theta));
            F(:,:,nFrames*(ii-1)+jj) = I(yidx,xidx);
            toc;
        end
    end
    
    dFF0 = extractDeltaFF0(F,baselineFrames,trialFrames); % TODO : inconsistent specification of baseline & trial frames versus aCID
    
    figs = multiFactorPlot(squeeze(mean(dFF0,2)),conditions,@(ax,frame,~,~) image(ax,nanmean(frame,3),'CDataMapping','scaled'),'TrialDim',3,'SubjectDim',4);
    cax = prctile(dFF0(:),[5 95]);
    
    for ii = 1:numel(figs)
        as = get(figs(ii),'Children');
        
        for jj = 1:numel(as)
            caxis(as(jj),cax);
        end
    end
    
    if nargin < 8
        return
    end
    
    [uniqueConditions,~,conditionIndices] = unique(conditions,'rows');
    nConditions = size(uniqueConditions,1);
    nTrialsPerCondition = accumarray(conditionIndices,1,[nConditions 1]);
    
    dFF02 = zeros(size(dFF0,1),size(dFF0,2),size(dFF0,3),max(nTrialsPerCondition),nConditions);
    
    for ii = 1:nConditions
        dFF02(:,:,:,:,ii) = dFF0(:,:,:,conditionIndices == ii);
    end
    
    mdFF02 = squeeze(nanmean(nanmean(dFF02,2),4));
    sdFF02 = squeeze(nanstd(nanmean(dFF02,2),[],4));
    
    writer = VideoWriter(videoFile);
    writer.FrameRate = 1000/120; % TODO : specify
    open(writer);
    
    figure;
    x = linspace(0,1,size(dFF02,1));
    yy = [min(mdFF02(:)-sdFF02(:)) max(mdFF02(:)+sdFF02(:))];
    
    for ii = 1:size(mdFF02,2)
        clf;
        boundedline(x,squeeze(mdFF02(:,ii,:)),squeeze(sdFF02(:,ii,:)));
        xlabel('Normalised Depth');
        xlim([0 1]);
        ylabel('{\Delta}F/F{_0}');
        ylim(yy);
        writeVideo(writer,getframe(gcf));
    end
end