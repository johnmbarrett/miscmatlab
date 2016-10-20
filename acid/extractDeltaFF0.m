function [dff0,f0] = extractDeltaFF0(stacks,baselineFrames,trialFrames,ledOnFrames)
    if ~iscell(stacks)
        stacks = {stacks};
    end
    
    sizes = cellfun(@size,stacks,'UniformOutput',false);
    sizes = vertcat(sizes{:});

    assert(std(sizes(:,1)) == 0 && std(sizes(:,2)) == 0 && std(sizes(:,3)) == 0);
    
    if nargin < 4
        ledOnFrames = true(sizes(1,3),1);
    else
        assert(sizes(1,3) == numel(ledOnFrames));
    end
    
    assert(ismatrix(baselineFrames) && size(baselineFrames,2) == 2 && all(baselineFrames(:) >= 1 & baselineFrames(:) <= sum(sizes(:,3))));
    assert(ismatrix(trialFrames) && size(trialFrames,2) == 2 && all(trialFrames(:) >= 1 & trialFrames(:) <= sum(sizes(:,3))));
    assert(isequal(size(trialFrames),size(baselineFrames)));
        
    nStacks = numel(stacks);
    nTrials = size(baselineFrames,1);
    framesPerTrial = nStacks*sum(ledOnFrames)/nTrials;
    f0 = zeros(sizes(1,1),sizes(1,2),nTrials);
    dff0 = zeros(sizes(1,1),sizes(1,2),framesPerTrial,nTrials);
    cFrames = [0; cumsum(sizes(:,3))];
    
    for ii = 1:nTrials
        startStack = find(baselineFrames(ii,1) <= cFrames,1)-1;
        endStack = find(baselineFrames(ii,2) <= cFrames,1)-1;
        
        assert(startStack == endStack,'Baseline can not cross stack boundary');
        
        baselineIndices = (baselineFrames(ii,1):baselineFrames(ii,2))-cFrames(startStack);
        
        f0(:,:,ii) = mean(stacks{startStack}(:,:,baselineIndices),3);
        
        trialIndices = (trialFrames(ii,1):trialFrames(ii,2))-cFrames(startStack);
        assert(numel(trialIndices) == framesPerTrial);
        
        dff0(:,:,:,ii) = bsxfun(@rdivide,double(stacks{startStack}(:,:,trialIndices)),f0(:,:,ii))-1;
    end
end