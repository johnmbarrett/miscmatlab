function Fcorrected = artifactSubtraction(Fraw,trialFrames,stimFrames,stimOnTrials,excitationOffTrials,outputFile) % TODO : multiple stacks
    sizes = size(Fraw);
    
    excitationOffTrialIndices = find(excitationOffTrials);
    nExcitationOffTrials = numel(excitationOffTrialIndices);
    nStimOnAndExcitationOffTrials = sum(stimOnTrials(excitationOffTrials));
    
    background = zeros(sizes(1),sizes(2));
    stimArtifact = zeros([size(background) numel(stimFrames)]);
    
    for ii = 1:nExcitationOffTrials
        trialIndex = excitationOffTrialIndices(ii);
        isStimOnTrial = stimOnTrials(trialIndex);
        frameIndices = trialFrames(trialIndex,1):trialFrames(trialIndex,2);
        background = background + mean(Fraw(:,:,frameIndices(setdiff(1:numel(frameIndices),stimFrames))),3)/nExcitationOffTrials;
        
        if isStimOnTrial
            stimArtifact = stimArtifact + Fraw(:,:,frameIndices(stimFrames))/nStimOnAndExcitationOffTrials;
        end
    end
    
    stimArtifact = bsxfun(@minus,stimArtifact,background);
    
    excitationOnTrialIndices = find(~excitationOffTrials);
    framesPerTrial = diff(trialFrames(excitationOnTrialIndices,:),[],2)+1;
    nExcitationOnTrials = numel(trialFrames(excitationOnTrialIndices));
    Fcorrected = zeros(sizes(1),sizes(2),max(framesPerTrial),nExcitationOnTrials);
    
    for ii = 1:nExcitationOnTrials
        trialIndex = excitationOnTrialIndices(ii);
        frameIndices = trialFrames(trialIndex,1):trialFrames(trialIndex,2);
        
        Fcorrected(:,:,:,ii) = bsxfun(@minus,double(Fraw(:,:,frameIndices)),background);
        
        if stimOnTrials(trialIndex)
            Fcorrected(:,:,stimFrames,ii) = Fcorrected(:,:,stimFrames,ii)-stimArtifact;
        end
    end
    
    if nargin < 6
        return
    end
    
    save(outputFile,'Fcorrected','-v7.3');
end

% OLD VERSION using previously extracted DFF0

% inputFile = 'JB0049AAAA0251.mat';
% outputFile = 'JB0049AAAA0251_corrected';
% 
% load(inputFile)
% fraw = zeros(size(dff0));
% for ii = 1:250
% tic
% fraw(:,:,ii,:) = squeeze(dff0(:,:,ii,:)+1).*f0;
% toc
% end
% bg = mean(fraw(:,:,:,3:3:end),4);
% foff = bsxfun(@minus,fraw(:,:,:,1:3:end),mean(bg(:,:,[1:40 48 end]),3));
% fon = bsxfun(@minus,fraw(:,:,:,2:3:end),bg);
% f0on = mean(fon(:,:,1:40,:),3); f0off = mean(foff(:,:,1:40,:),3);
% dff0on = bsxfun(@rdivide,fon,f0on)-1;
% dff0off = bsxfun(@rdivide,foff,f0off)-1;
% save([outputFile '_corrected.mat'],'f0on','f0off','dff0on','dff0off','bg','-v7.3')
% dff0on(isnan(dff0on)) = 0;
% dff0off(isnan(dff0off)) = 0;
% responses = extractROIResponses(cat(4,dff0off,dff0on),masks,[ones(10,1) kron([0;1],ones(5,1))],{'Dummy' 'LED On'},outputFile);
% save([outputFile '_corrected.mat'],'-append','-v7.3','responses')