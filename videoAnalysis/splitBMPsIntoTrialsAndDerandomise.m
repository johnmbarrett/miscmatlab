function splitBMPsIntoTrialsAndDerandomise(imageStackFolder,mask,parameterFile,offset,threshold)
    if nargin < 4
        offset = 0;
    end
    
    if nargin < 5
        threshold = 254;
    end
    
    params = xml2struct(parameterFile);
    stimOrder = cellfun(@(I32) str2double(I32.Val.Text),params.LVData.Cluster.Cluster{3}.Array{3}.I32);

    cd(imageStackFolder);

    tic;
    bmps = loadFilesInNumericOrder('*.bmp','tt([0-9]+)');
    nBMPs = numel(bmps);
    fprintf('Retrieved image list in %f seconds\n',toc);
    
    useCircularROI = isscalar(mask);
    if useCircularROI
        maskRadius2 = mask^2;
    end

    tic;
    l = zeros(numel(bmps),1);
    for ii = 1:numel(bmps)
        I = imread(bmps{ii});
        
        if useCircularROI
            [~,maxX] = max(mean(I(:,2:end-1),1)); % there seems to be a weird edge effect
            [~,maxY] = max(mean(I(2:end-1,:),2));
            
            [Y,X] = ndgrid(1:size(I,1),1:size(I,2));
            
            mask = (X-(maxX+1)).^2+(Y-(maxY+1)).^2 < maskRadius2;
        end
        
        l(ii) = mean(I(mask));
    end
    fprintf('Calculated ROI luminance in %f seconds\n',toc);

    trialStarts = find(diff(l > threshold) < 0)-offset;
    nTrials = numel(trialStarts);

    dbStatus = dbstatus;
    dbstop if error;
    assert(nTrials == ceil(nBMPs/median(diff(trialStarts))),'THIS SHOULD NEVER HAPPEN');
    dbstop(dbStatus);
    
    nStimuli = numel(stimOrder);
    nBlocks = floor(nTrials/nStimuli);
    maxTrials = nBlocks*nStimuli;
    
    for ii = 1:nStimuli
        trialIndices = ii:nStimuli:maxTrials;
        
        VT = cell(1,nBlocks);
        
        tic;
        for jj = 1:nBlocks
            trialIndex = trialIndices(jj);
            firstImage = trialStarts(trialIndex);
            
            if trialIndex == nTrials
                lastImage = nBMPs;
            else
                lastImage = trialStarts(trialIndex+1)-1;
            end
            
            imageIndices = firstImage:lastImage;
            nFrames = numel(imageIndices);
            VT{jj} = uint8(zeros([size(I) nFrames])); % TODO : what if the bit depth changes
            
            for kk = 1:nFrames
                VT{jj}(:,:,kk) = imread(bmps{imageIndices(kk)});
            end
        end
        fprintf('Loaded images for stim %d/%d in %f seconds\n',ii,nStimuli,toc);
        
        tic;
        vtFile = sprintf('VT%d.mat',stimOrder(ii));
        save(vtFile,'VT');
        fprintf('Saved %s in %f seconds\n',vtFile,toc);
    end
end