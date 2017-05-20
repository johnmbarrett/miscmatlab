function splitBMPsIntoTrialsAndDerandomise(imageStackFolder,mask,parameterFile,locationFile,offset,threshold)
    if nargin < 5
        offset = 0;
    end
    
    if nargin < 6
        threshold = 254;
    end
    
    isLocationFileProvided = nargin > 3 && ischar(locationFile) && exist(locationFile,'file');
    
    if isLocationFileProvided
        locations = importdata(locationFile)';
    end
    
    params = xml2struct(parameterFile);
    
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
    
    stimOrder = repmat(locationOrder(:),numel(piezoOrder),1)+kron(numel(locationOrder)*(piezoOrder-1),ones(numel(locationOrder),1));
    
    assert(numel(unique(stimOrder)) == numel(stimOrder),'Some location & piezo parameter combinations missing: check parameter file.');

    cd(imageStackFolder);
    
    save('parsed_params','locations','locationOrder','piezoParams','piezoOrder','stimOrder');

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

    framesPerTrial = diff(trialStarts);
    modalFramesPerTrial = mode(framesPerTrial);
    firstBad = find(framesPerTrial(2:end) ~= modalFramesPerTrial,1)+1; % skip checking 1st trial because the 1st image is often lost
    
    nStimuli = numel(stimOrder);
    
    if ~isempty(firstBad)
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
    
    for ii = 1:nStimuli
        trialIndices = ii:nStimuli:maxTrials;
        
        VT = cell(1,nBlocks);
        
        tic;
        for jj = 1:nBlocks
            trialIndex = trialIndices(jj);
            firstImage = trialStarts(trialIndex);
            
            if trialIndex == numel(trialStarts)
                if isempty(firstBad)
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