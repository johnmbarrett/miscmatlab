function [F,dFF0,figs] = makeLaminarFlourescenceChangeProfile(stacks,mask,theta,useFrames,baselineFrames,trialFrames,conditions)
    if theta > pi
    theta = theta-pi;
    end

    M = imrotate(mask,rad2deg(theta));
    [ym,xm] = ind2sub(size(M),find(M));
    
    xidx = min(xm):max(xm);
    yidx = min(ym):max(ym);

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
    cax = prctile(dFF0(:),[1 99]);
    
    for ii = 1:numel(figs)
        as = get(figs(ii),'Children');
        
        for jj = 1:numel(as)
            caxis(as(jj),cax);
        end
    end
end