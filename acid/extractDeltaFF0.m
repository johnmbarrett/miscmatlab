function [dff0,f0] = extractDeltaFF0(stacks,baselineFrames,trialFrames)
    if ~iscell(stacks)
        stacks = {stacks};
    end
    
    sizes = cellfun(@size,stacks,'UniformOutput',false);
    sizes = vertcat(sizes{:});
    
    if size(sizes,2) < 3
        sizes(:,(size(sizes,2)+1):3) = 1;
    end

    assert(std(sizes(:,1)) == 0 && std(sizes(:,2)) == 0 && std(sizes(:,3)) == 0);
    
    assert(ismatrix(baselineFrames) && size(baselineFrames,2) == 2 && all(baselineFrames(:) >= 1 & baselineFrames(:) <= sum(sizes(:,3))));
    assert(ismatrix(trialFrames) && size(trialFrames,2) == 2 && all(trialFrames(:) >= 1 & trialFrames(:) <= sum(sizes(:,3))));
    assert(isequal(size(trialFrames),size(baselineFrames)));
        
    nTrials = size(baselineFrames,1);
    framesPerTrial = max(diff(trialFrames,[],2)+1);
    f0 = zeros(sizes(1,1),sizes(1,2),nTrials);
    dff0 = zeros(sizes(1,1),sizes(1,2),framesPerTrial,nTrials);
    cFrames = [0; cumsum(sizes(:,3))];
    
    for ii = 1:nTrials
        baselineStackIndices = arrayfun(@(f) find(f <= cFrames,1),baselineFrames(ii,1):baselineFrames(ii,2))-1;
        baselineFrameIndices = (baselineFrames(ii,1):baselineFrames(ii,2))-cFrames(baselineStackIndices)';
        nBaselineFrames = numel(baselineFrameIndices);
        
        uniqueStackIndices = unique(baselineStackIndices);
        
        for jj = 1:numel(uniqueStackIndices)
            tic;
            stackIndex = uniqueStackIndices(jj);
            f0(:,:,ii) = f0(:,:,ii) + sum(stacks{stackIndex}(:,:,baselineFrameIndices(baselineStackIndices == stackIndex)),3)/nBaselineFrames;
            toc;
        end
        
        trialStackIndices = arrayfun(@(f) find(f <= cFrames,1),trialFrames(ii,1):trialFrames(ii,2))-1;
        trialFrameIndices = (trialFrames(ii,1):trialFrames(ii,2))-cFrames(trialStackIndices)';
        assert(numel(trialFrameIndices) <= framesPerTrial);
        
        uniqueStackIndices = unique(trialStackIndices);
        
        framesSoFar = 0;
        for jj = 1:numel(uniqueStackIndices)
            tic;
            stackIndex = uniqueStackIndices(jj);
            fraw = double(stacks{stackIndex}(:,:,trialFrameIndices(trialStackIndices == stackIndex)));
            dff0(:,:,framesSoFar+(1:size(fraw,3)),ii) = bsxfun(@rdivide,fraw,f0(:,:,ii))-1;
            framesSoFar = framesSoFar + size(fraw,3);
            toc;
        end
    end
end