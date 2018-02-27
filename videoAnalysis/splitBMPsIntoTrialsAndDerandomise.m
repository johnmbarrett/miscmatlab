function splitBMPsIntoTrialsAndDerandomise(imageStackFolder,mask,parameterFile,locationFile,offset,threshold,isFramesPerTrialFuzzy)
    if ~exist(imageStackFolder,'dir')
        warning('Folder %s does not exist.  Ignoring...\n',imageStackFolder);
    end

    if nargin < 5
        offset = 0;
    end
    
    if nargin < 6
        threshold = 254;
    end
    
    % TODO : we actually parse the params twice (once for front view, once
    % for left view).  the time/space overhead compared to the actual
    % motion tracking is small though so fuck it
    if ischar(parameterFile) && exist(parameterFile,'file')
        params = xml2struct(parameterFile);
    end
    
    isLocationArgumentProvided = nargin > 3 && ischar(locationFile);
    
    isLocationFileProvided = isLocationArgumentProvided && exist(locationFile,'file');
    
    if isLocationArgumentProvided && ~isLocationFileProvided
        switch locationFile
            case 'new'
                % using Xiaojian's new experiment GUI
                laserParams = extractMatrixFromXML(params.LVData.Cluster.Array{1});
                laserOrder = extractMatrixFromXML(params.LVData.Cluster.Array{2});
            case 'manual'
                laserParams = parameterFile(:,1:7);
                laserOrder = parameterFile(:,8);
            otherwise
                error('What in tarnation is going on here?');
        end
            
        locationOrder = laserOrder; %#ok<NASGU> % TODO : no???
        locations = laserParams(:,5:6); %#ok<NASGU>
        stimOrder = laserOrder;
        piezoParams = 1; %#ok<NASGU>
        piezoOrder = 1; %#ok<NASGU>
    else
        if isLocationFileProvided
            locations = importdata(locationFile)';
        end

        if isstruct(params.LVData.Cluster.Cluster{3}.Array{3}.I32)
            if isLocationFileProvided
                locationOrder = 1:size(locations,1);
            else
                locationOrder = 1;
            end
        else
            locationOrder = cellfun(@(I32) str2double(I32.Val.Text),params.LVData.Cluster.Cluster{3}.Array{3}.I32);

            if isLocationFileProvided
                assert(numel(locationOrder) == size(locations,1),'Mismatch between number of stimulus locations specified in location file and parameter file');
            end
        end

        if isfield(params.LVData.Cluster,'Array') && isfield(params.LVData.Cluster.Array,'DBL') && iscell(params.LVData.Cluster.Array.DBL)
            piezoParams = cellfun(@(DBL) str2double(DBL.Val.Text),params.LVData.Cluster.Array.DBL);
            piezoParams = reshape(piezoParams,str2double(params.LVData.Cluster.Array.Dimsize{2}.Text),str2double(params.LVData.Cluster.Array.Dimsize{1}.Text))';

            [piezoParams,~,piezoOrder] = unique(piezoParams,'rows'); %#ok<ASGLU>
        else
            piezoParams = zeros(1,4); %#ok<NASGU>
            piezoOrder = 1;
        end

        laserParams = locations; %#ok<NASGU> % TODO : this doesn't work for parametric maps for the old GUI but that probably doesn't matter any more
        laserOrder = locationOrder; % see above
        stimOrder = repmat(laserOrder(:),numel(piezoOrder),1)+kron(numel(laserOrder)*(piezoOrder-1),ones(numel(laserOrder),1));
    end
    
    assert(numel(unique(stimOrder)) == numel(stimOrder),'Some location & piezo parameter combinations missing: check parameter file.');

    cd(imageStackFolder);
    
    if ~exist('.\analysis','dir')
        mkdir('analysis');
    end
    
    save('analysis\parsed_params','locations','locationOrder','piezoParams','piezoOrder','laserParams','laserOrder','stimOrder');

    tic;
    bmps = loadFilesInNumericOrder('*.bmp','tt([0-9]+)');
    nBMPs = numel(bmps);
    fprintf('Retrieved image list in %f seconds\n',toc);
    
    if nBMPs == 0
        warning('No images found for folder %s.  Ignoring...\n',imageStackFolder);
        return
    end
    
    useCircularROI = isscalar(mask);
    if useCircularROI
        maskRadius2 = mask^2;
    end
    
    % TODO : fix the WMIL tracker if I can
%     I = imread(bmps{1});
%     imshow(I);
%     bodyPartROIs = chooseMultipleROIs(@imfreehand);
%     roiPositions = zeros(numel(bodyPartROIs),4);
%     
%     for ii = 1:numel(bodyPartROIs)
%         roiMask = createMask(bodyPartROIs(ii));
%         pos = regionprops(roiMask,'BoundingBox');
%         roiPositions(ii,:) = pos.BoundingBox;
% 
%         [img{ii},iH{ii},trparams(ii),lRate(ii),M(ii),numSel(ii),posx{ii},negx{ii},ftr(ii),showTracking(ii)] = initialiseWMILTracker(bmps{1},roiPositions(ii,:)); %#ok<AGROW>
%     end
    
%     allCoords = zeros(numel(bmps),4,numel(bodyPartROIs));
%     allCoords(1,:,:) = roiPositions';

    luminanceCalcStart = tic;
    l = zeros(numel(bmps),1);
    for ii = 1:numel(bmps)
        tic;
        I = imread(bmps{ii});
        
        if useCircularROI
            [~,maxX] = max(mean(I(:,2:end-1),1)); % there seems to be a weird edge effect
            [~,maxY] = max(mean(I(2:end-1,:),2));
            
            [Y,X] = ndgrid(1:size(I,1),1:size(I,2));
            
            mask = (X-(maxX+1)).^2+(Y-(maxY+1)).^2 < maskRadius2;
        end
        
        l(ii) = mean(I(mask));
        
        if ii == 1
            continue
        end
        
%         for jj = 1:numel(bodyPartROIs)
%             [allCoords(ii,:,jj),posx{jj},negx{jj},img{jj},iH{jj}] = WMILTrack(I,img{jj},iH{jj},allCoords(ii-1,:,jj),posx{jj},negx{jj},ftr(jj),trparams(jj),lRate(jj),M(jj),numSel(jj),jj == 2,showTracking(jj));
%         end
        toc;
    end
    
%     T = allCoords;
%     
%     for ii = 1:2
%         T(:,ii,:) = T(:,ii,:) + T(:,ii+2,:)/2;
%     end
%     
%     T(:,3:4,:) = [];
    
    fprintf('Calculated ROI luminance in %f seconds\n',toc(luminanceCalcStart));

    trialStarts = find(diff(l > threshold) < 0)-offset;
    
    if isempty(trialStarts)
        error('No trial onsets detected, mask location may be wrong.');
    end

    framesPerTrial = diff(trialStarts);
    modalFramesPerTrial = mode(framesPerTrial);
    firstBad = find(framesPerTrial(2:end) ~= modalFramesPerTrial,1)+1; % skip checking 1st trial because the 1st image is often lost
    
    nStimuli = numel(stimOrder);
    
    if nargin < 7
        isFramesPerTrialFuzzy = false;
    end
    
    if ~isempty(firstBad) && ~isFramesPerTrialFuzzy
        nBlocks = floor((firstBad-1)/nStimuli);
        
        msg = sprintf('Lost track of trial starts at trial #%d.  That leaves %d blocks of definitely good trials.',firstBad,nBlocks);
        
        warning('%s  Ignoring the rest...\n',msg);
        
        fout = fopen(sprintf('%s\\bad.txt',imageStackFolder),'w');
        
        fprintf(fout,'Check this folder again: %s\n',msg);
        
        fclose(fout);
        
        trialStarts = trialStarts(1:(firstBad-1));
    else
        nBlocks = floor(numel(trialStarts)/nStimuli);
    end
    
    maxTrials = nBlocks*nStimuli;
    
%     trajectories = cell(nStimuli,nBlocks);
    
    for ii = 1:nStimuli
        trialIndices = ii:nStimuli:maxTrials;
        
        VT = cell(1,nBlocks);
        
        tic;
        for jj = 1:nBlocks
            trialIndex = trialIndices(jj);
            firstImage = trialStarts(trialIndex);
            
            if trialIndex == numel(trialStarts)
                if isempty(firstBad) || isFramesPerTrialFuzzy
                    lastImage = nBMPs;
                else
                    lastImage = firstImage+modalFramesPerTrial-1; % guaranteed to be right, otherwise this trial would be firstBad
                end
            else
                lastImage = trialStarts(trialIndex+1)-1;
            end
            
            imageIndices = firstImage:lastImage;
            nFrames = numel(imageIndices);
            VT{jj} = uint8(zeros([size(I) nFrames])); % TODO : what if the bit depth changes
            
            for kk = 1:nFrames
                VT{jj}(:,:,kk) = mean(imread(bmps{imageIndices(kk)}),3);
            end
            
%             trajectories{stimOrder(ii)+1,jj} = T(imageIndices,:,:);
        end
        fprintf('Loaded images for stim %d/%d in %f seconds\n',ii,nStimuli,toc);
        
        tic;
        vtFile = sprintf('analysis\\VT%d.mat',stimOrder(ii));
        
        varInfo = whos('VT');
        
        if varInfo.bytes > 2^31-1
            save(vtFile,'-v7.3','VT');
        else
            save(vtFile,'VT');
        end
        
        fprintf('Saved %s in %f seconds\n',vtFile,toc);
    end
    
%     save('analysis\wmil_trajectories.mat','trajectories','roiPositions');
end