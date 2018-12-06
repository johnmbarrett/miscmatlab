function [derandomisedPSTH,trialCount,trialsSoFar] = derandomiseSpikeData(psth,traces,digitalData,sampleRate,paramCodeDepth,isSaveTrialData,preStimulusBins,postStimulusBins,dataFolder,trialsSoFar,isStimulusEncodedInTrigger)

    nStimuli = size(stimulusSequence,2);
    sampleRateMS = sampleRate / 1000;
    
    trialCount = zeros(1,nStimuli);

    stimulusMarkers = find(digitalData);
    paramCodeLength = (paramCodeDepth+2) * sampleRateMS;
    stimulusMarkers(find(diff(stimulusMarkers) <= paramCodeLength)+1) = [];
    
    derandomisedPSTH = zeros(preStimulusBins+postStimulusBins,size(psth,2),nStimuli);

    for ii = 1:numel(stimulusMarkers)   
        stimulusMarker = stimulusMarkers(ii);

        if isStimulusEncodedInTrigger
            paramCode = 0;
            for jj = 2:paramCodeDepth+1
                if digitalData(1,stimulusMarker + jj*sampleRateMS - sampleRateMS/2) == 1
                    paramCode(1,1) = paramCode(1,1) + 2^(jj + 2);
                end
            end

            stimulusID = find(stimulusSequence == paramCode);
        else
            stimulusID = stimulusSequence(mod(trialsSoFar-1,nStimuli)+1);
        end

        stimulusBin = floor(stimulusMarker/sampleRateMS);

        trialPSTH = psth(stimulusBin-preStimulusBins:stimulusBin+postStimulusBins-1,:);
        trialsSoFar = trialsSoFar + 1;
        
        if isSaveTrialData == 1
            trialTrace = traces(:,stimulusMarker-preStimulusBins*sampleRateMS:stimulusMarker+postStimulusBins*sampleRateMS)'; %#ok<NASGU>
            save([dataFolder '/TrialData/trial_' num2str(trialsSoFar) '_' num2str(stimulusID)],'trialTrace','trialPSTH');
        end
        
        derandomisedPSTH(:,:,stimulusID) = psth(:,:,stimulusID) + trialPSTH;
        trialCount(stimulusID) = trialCount(stimulusID) + 1;
        
    end
    
    % TODO : figureout how to do this cleanly
%     AmpTl = traces(:,stimulusMarker+(paramCodeDepth+1+1+1)*sampleRateMS:end);
%     DinTl = digitalData(:,stimulusMarker+(paramCodeDepth+1+1+1)*sampleRateMS:end);
    %disp('Keep Tail done');

end