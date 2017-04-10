function quickMMCalciumImagingAnalysis(frameRate,duration)
    [~,currentDir] = fileparts(pwd);
    
    info = imfinfo([currentDir '_MMStack_Pos0.ome.tif']);
    
    totalFrames = numel(info);
    I = zeros(info(1).Height,info(1).Width,totalFrames);
    
    for ii = 1:totalFrames
        tic;
        I(:,:,ii) = imread([currentDir '_MMStack_Pos0.ome.tif'],'Index',ii,'Info',info);
        toc;
    end
    
    J = bin(I,2);
    
    framesPerTrial = frameRate*duration;
    % skip first frame because it's always really bright
    [dff0,f0] = extractDeltaFF0(J,[2:framesPerTrial:totalFrames;frameRate:framesPerTrial:totalFrames]',[2:framesPerTrial:totalFrames;framesPerTrial:framesPerTrial:totalFrames]');  %#ok<ASGLU>
    
%     for ii = 1:totalFrames
%         dff0(:,:,ii) = medfilt2(dff0(:,:,ii));
%     end

    save([currentDir '_dff0.mat'],'dff0','f0');
    
    nTrials = totalFrames/framesPerTrial;
    makeMeanDeltaFF0Video(dff0,[ones(nTrials,1) repmat([0;1],nTrials/2,1)],[currentDir '_basic.avi'],{'Dummy' 'Stim On'},frameRate,@(x,y) [0.025+0.5*(x-1) 0.05 0.45 0.9],[0 0 900 300]);
end