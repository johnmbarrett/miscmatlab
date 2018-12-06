function [amplifierData,digitalData] = readIntanFile(rhdFile,isBandPass,isDeartifact,isSaveTrialData,isStimulusEncodedInTrigger)
    [amplifierData, digitalData, sampleRate] = Intan2Mat_3(rhdFile.name,isBandPass);
%     Nchannel = evalin('base','Nchannel'); % TODO
    
    [spike,trAmp] = Bin_Spike_1(Amp',sampleRate,isDeartifact);  %%%% not the same as creattimer 2 ,transposed.
    
    if isStimulusEncodedInTrigger
        Sort_Data_PC_1(spike,trAmp',Din,sampleRate,isSaveTrialData);
    else
        Sort_Data_PC_2(spike,trAmp',Din,sampleRate,isSaveTrialData);
    end
end