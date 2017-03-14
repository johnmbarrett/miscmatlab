function offlineMotionTracking(videoFile,roiFile,outputFile)
    load(videoFile);
    load(roiFile);
    
    nTrials = numel(VT); %#ok<USENS>
    trajectories = cell(nTrials,1);
    
    tic;
    for ii = 1:numel(VT)
        trajectories{ii} = basicMotionTracking(VT{ii},'ROIs',rois,'UpdateTemplate',false,'VideoOutputFile',NaN);
    end
    toc;
    
    save(outputFile,'trajectories');
end