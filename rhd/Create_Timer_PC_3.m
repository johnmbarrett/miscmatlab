function Create_Timer_PC_3(dataFolder,probeLayouts,params,isBandPass,isDeartifact,isOnline,isSaveFigure,isStimulusEncodedInTrigger,stimulusSequence,preStimulusBins,postStimulusBins)
    % TODO : can probably eventually move this up into processRHDFiles
    rhdFiles = dir('*.rhd');
    
    nStimuli = size(stimulusSequence,2);
    nChannels = numel(probeLayouts); % TODO : check
    
    derandomisedPSTH = zeros(preStimulusBins+postStimulusBins,nChannels,nStimuli);
    trialCount = zeros(1,nStimuli);
    trialsSoFar = 0;
    
    analogTail = zeros(nChannels,0);
    digitalTail = zeros(1,0);
    
    for hh = 1:numel(rhdFiles)
        tic;
        [analogData, digitalData, sampleRate] = Intan2Mat_3(rhdFile.name,isBandPass);
        
        analogData = [analogTail analogData]; %#ok<AGROW>
        digitalData = [digitalTail digitalData]; %#ok<AGROW>
        
        [psth,analogData] = binSpikes(analogData',sampleRate,isDeartifact);
        
        sampleRatekHz = sampleRate / 1000;

        % TODO : this is duplicated in Intan2Mat_5 - can probably move the
        % deartifacting outside
        stimulusMarkers = find(digitalData);
        paramCodeLength = (paramCodeDepth+2) * sampleRatekHz;
        stimulusMarkers(find(diff(stimulusMarkers) <= paramCodeLength)+1) = [];

        for ii = 1:numel(stimulusMarkers)   
            stimulusMarker = stimulusMarkers(ii);

            if isStimulusEncodedInTrigger
                paramCode = 0;
                for jj = 2:paramCodeDepth+1
                    if digitalData(1,stimulusMarker + jj*sampleRatekHz - sampleRatekHz/2) == 1
                        paramCode(1,1) = paramCode(1,1) + 2^(jj + 2);
                    end
                end

                stimulusID = find(stimulusSequence == paramCode);
            else
                stimulusID = stimulusSequence(mod(trialsSoFar-1,nStimuli)+1);
            end

            stimulusBin = floor(stimulusMarker/sampleRatekHz);

            trialPSTH = psth(stimulusBin-preStimulusBins:stimulusBin+postStimulusBins-1,:);
            trialsSoFar = trialsSoFar + 1;

            if isSaveTrialData == 1
                trialTrace = analogData(:,stimulusMarker-preStimulusBins*sampleRatekHz:stimulusMarker+postStimulusBins*sampleRatekHz)'; %#ok<NASGU>
                save([dataFolder '/TrialData/trial_' num2str(trialsSoFar) '_' num2str(stimulusID)],'trialTrace','trialPSTH');
            end

            derandomisedPSTH(:,:,stimulusID) = psth(:,:,stimulusID) + trialPSTH;
            trialCount(stimulusID) = trialCount(stimulusID) + 1;
        end
    
        analogTail = analogData(:,stimulusMarker+(paramCodeDepth+3)*sampleRateMS:end);
        digitalTail = digitalData(:,stimulusMarker+(paramCodeDepth+3)*sampleRateMS:end);
        
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
    
    Par_PSTH_ave = [params meanPSTH]; %#ok<NASGU>
    
    save([dataFolder '/DataMatrix/Par_PSTH_ave.mat'],'Par_PSTH_ave');

%     if ~isOnline % TODO : never
%         cd ([dataFolder '/TrialData']); % TODO : I don't like all this CD'ing around
%         Merge_Trial_1(probeLayouts,size(params,1)); % TODO
%         cd (dataFolder);
%     end
end