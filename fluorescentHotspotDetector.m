function [ddff0,V,fig] = fluorescentHotspotDetector(filePrefixes,framesPerTrial,nTrials,baselineFrames,frameRate,nStimuli,subtractStyle,temporalBinning,isDeoscillated,fovMoves,medianFilterSize)
    if nargin < 6
        nStimuli = 1;
        subtractStyle = 'alternating';
    elseif nargin < 7
        if nStimuli == 1
            subtractStyle = 'alternating';
        elseif nStimuli == 2
            subtractStyle = 'firstStimulus';
        else
            subtractStyle = 'none';
        end
    end
    
    if nargin < 8
        temporalBinning = 1;
    end
    
    if nargin < 9
        isDeoscillated = false;
    end
    
    if nargin < 10
        fovMoves = 1;
    end
    
    if nargin < 11
        medianFilterSize = [1 1];
    end
    
    if ischar(filePrefixes)
        filePrefixes = {filePrefixes};
    elseif isstruct(filePrefixes)
        
        assert(iscellstr(filePrefixes));
    end

    nFiles = numel(filePrefixes);
    
    for hh = 1:nFiles
        filePrefix = filePrefixes{hh};
        
        binnedDataFile = [filePrefix '_binned.mat'];

        if exist(binnedDataFile,'file')
            tic;
            load(binnedDataFile,'V');

            if exist('nFrames','var')
                assert(nFrames == size(V,3),'Multifile analysis requires that each file have the same frame rate, sweep length, number of stimuli, and subtract style.');
            else
                nFrames = size(V,3);
            end
            toc;
        else
            videoFiles = loadFilesInNumericOrder([filePrefix '*_new.avi'],'-([0-9]+)_new\.avi');

            if isempty(videoFiles)
                videoFiles = loadFilesInNumericOrder([filePrefix '*.avi'],'-([0-9]+)\.avi');
            end

            nFrames = framesPerTrial*nTrials;

            % TODO : detect size
            V = zeros(48,64,nFrames);

            nn = 0;
            for ii = 1:numel(videoFiles)
                r = VideoReader(videoFiles{ii}); %#ok<TNMLP>

                while hasFrame(r) && nn < nFrames
                    tic;
                    nn = nn + 1;
                    V(:,:,nn) = bin(squeeze(mean(double(readFrame(r)),3)),16);
                    toc;
                end
            end

            save(binnedDataFile,'V');
        end
        
        if hh == 1
            Vall = V;
        else
            Vall = cat(4,Vall,V);
        end
    end
    
    V = Vall;
    V = squeeze(mean(reshape(V,48,64,temporalBinning,nFrames/temporalBinning,nFiles),3));
    
    if prod(medianFilterSize) > 1
        V = pagefun(@(A) colfilt(A,medianFilterSize,'sliding',@median),V);
    end
    
    framesPerTrial = framesPerTrial/temporalBinning;
    baselineFrames = ceil(baselineFrames/temporalBinning);
    frameRate = frameRate/temporalBinning;
    
    W = squeeze(V(:,:,1,fovMoves));
    
    V = reshape(V,48,64,framesPerTrial*nTrials*nFiles);
    
    if isscalar(baselineFrames)
        baselineFrames = [1 baselineFrames];
    end
    
    dff0 = extractDeltaFF0(V,bsxfun(@plus,framesPerTrial*(0:nTrials*nFiles-1)',baselineFrames),bsxfun(@plus,framesPerTrial*(0:nTrials*nFiles-1)',[1 framesPerTrial]));
    dff0(isnan(dff0)) = 0;
    
    switch subtractStyle(1)
        case 'a' % Alternating: every other trial is a no stim trial, so subtract it from the following stim trial
            dff02 = reshape(dff0,48,64,framesPerTrial,2,nStimuli,nTrials/(2*nStimuli),nFiles);
            
            if isDeoscillated % TODO : deoscillation for first stim subtract style
                sV = squeeze(sum(sum(V)));
                dsV = abs(diff(reshape(sV,framesPerTrial,nTrials*nFiles)));
                bad = squeeze(any(any(any(reshape(dsV,framesPerTrial-1,2*nStimuli,nTrials/(2*nStimuli),nFiles) >= 48*64/2)),4)); % this throws away for more stimuli than we need, but otherwise we'll have an uneven number of trials per stimulus/file
                
                dff02 = dff02(:,:,:,:,:,~bad,:);
                dff03 = dff02(:,:,11:(framesPerTrial-10),:,:,:,:);
                sdff0 = squeeze(sum(sum(dff02)));
                
                nTrials = nTrials-sum(bad(:))*nStimuli*2;
                n = nTrials*nFiles/(2*nStimuli);
                dt = zeros(n,1);

                for ii = 1:n
                    x = sdff0(:,1,ii);
                    y = sdff0(:,2,ii);
                    [r,l] = xcorr(x,y,10);
                    [~,idx] = max(r);
                    dt(ii) = l(idx);
                    dff03(:,:,:,1,:,ii) = dff02(:,:,(11:(framesPerTrial-10))+dt(ii),1,:,ii);
                end
                
                framesPerTrial = framesPerTrial-20;
                baselineFrames = baselineFrames-10;
                
                dff02 = dff03;
            end
            
            ddff0 = reshape(permute(diff(dff02,[],4),[1 2 3 5 7 6 4]),48,64,framesPerTrial,nStimuli*nFiles,nTrials/(2*nStimuli));
        case 'f' % First stim: first stimulus in a block a no stim trial, so subtract it from every other trial in that block
            dff02 = reshape(dff0,48,64,framesPerTrial,nStimuli,nTrials/nStimuli,nFiles);
            ddff0 = bsxfun(@minus,dff02(:,:,:,2:end,:,:),dff02(:,:,:,1,:,:)); %squeeze(diff(dff0,[],4));
            ddff0 = reshape(permute(ddff0,[1 2 3 4 6 5]),48,64,framesPerTrial,nStimuli*nFiles,nTrials/nStimuli);
            nStimuli = nStimuli-1;
        case 'n' % No subtraction: ronseal
            ddff0 = reshape(permute(reshape(dff0,48,64,framesPerTrial,nStimuli,nTrials/nStimuli,nFiles),[1 2 3 4 6 5]),48,64,framesPerTrial,nStimuli*nFiles,nTrials/nStimuli);
    end
    
    clear('dff02');
    
    nStimuli = nStimuli*nFiles;
    
    mddff0 = mean(ddff0,5); %squeeze(mean(ddff0,4));
    
    smddff0 = squeeze(sum(sum(mddff0)));
    
    [maxPerImage,maxIndices] = max(reshape(mddff0,[],framesPerTrial,nStimuli)); 
    
    if isvector(maxPerImage) || isscalar(maxPerImage)
        % for some incomprehensible reason squeezning a column vector
        % doesn't give you a row vector
        maxPerImage = maxPerImage(:);
        maxIndices = maxIndices(:);
    else
        maxPerImage = squeeze(maxPerImage);
        maxIndices = squeeze(maxIndices);
    end
    
    [maxY,maxX] = ind2sub(size(mddff0(:,:,1)),maxIndices);
    
    maxPerStimulus = permute(max(maxPerImage((baselineFrames(2)+1):end,:)),[1 3 4 2]);
    minPerStimulus = min(min(min(mddff0)));
    
    if false
        threshold = maxPerStimulus/2;
    elseif false
        threshold = maxPerStimulus/2+minPerStimulus/2;
    elseif false
        threshold = permute(mean(reshape(mddff0,[],framesPerTrial,nStimuli))+2*std(reshape(mddff0,[],framesPerTrial,nStimuli)),[1 4 2 3]);
    elseif true
        baseline = reshape(mddff0(:,:,baselineFrames(1):baselineFrames(2),:),[],nStimuli);
        threshold = permute(mean(baseline)+3*std(baseline),[1 3 4 2]);
    end
    
    mddff0Thresholded = bsxfun(@gt,mddff0,threshold);
    
    blobs = cell(framesPerTrial,nStimuli);
    hulls = cell(framesPerTrial,nStimuli);
    masks = cell(framesPerTrial,nStimuli);
    
    areas = nan(framesPerTrial,nStimuli);
    centroidBinary = nan(framesPerTrial,2,nStimuli);
    centroidWeighted = nan(framesPerTrial,2,nStimuli);
    
    for ii = 1:framesPerTrial
        for jj = 1:nStimuli
            B = bwconncomp(mddff0Thresholded(:,:,ii,jj));
            masks{ii,jj} = false(size(mddff0Thresholded(:,:,ii,jj)));

            if B.NumObjects == 0
                blobs{ii,jj} = zeros(0,2);
                hulls{ii,jj} = zeros(0,2);
                masks{ii,jj} = false(size(V(:,:,1)));
                
                continue
            end

            [~,biggestBlobIndex] = max(cellfun(@numel,B.PixelIdxList));
            
            biggestBlob = B;
            
            biggestBlob.NumObjects = 1;
            biggestBlob.PixelIdxList = B.PixelIdxList(biggestBlobIndex);

            [y,x] = ind2sub(size(mddff0Thresholded(:,:,ii,jj)),biggestBlob.PixelIdxList{1});

            blobs{ii,jj} = [x y];
            
            props = regionprops(biggestBlob,mddff0(:,:,ii,jj),'BoundingBox','Centroid','WeightedCentroid','ConvexHull','ConvexArea','ConvexImage');

%             try
            hull = props.ConvexHull; %convhull(x,y);
            
            if isempty(hull)
                hulls{ii,jj} = zeros(0,2);
            else
                hulls{ii,jj} = hull;
            end
            
            masks{ii,jj}(round(props.BoundingBox(2)+(1:props.BoundingBox(4))-1),round(props.BoundingBox(1)+(1:props.BoundingBox(3))-1)) = props.ConvexImage;
            
%             catch e %#ok<NASGU> TODO : check if it's a convhull error and swallow else rethrow
%                 hulls{ii,jj} = [];
%             end
            
            areas(ii,jj) = props.ConvexArea;
            
            centroidBinary(ii,:,jj) = props.Centroid;
            centroidWeighted(ii,:,jj) = props.WeightedCentroid;
        end
    end
    
    for ii = 1:nFiles
        tic;
        stimuliPerFile = nStimuli/nFiles;
        
        fileStruct = struct([]);
        fileStruct(1).dff0 = dff0(:,:,:,((ii-1)*nTrials+1):ii*nTrials);
        
        fileIndices = ((ii-1)*stimuliPerFile+1):ii*stimuliPerFile;
        
        fileStruct(1).ddff0 = ddff0(:,:,:,fileIndices,:);
        fileStruct(1).mddff0 = mddff0(:,:,:,fileIndices);
        fileStruct(1).mddff0Thresholded = mddff0Thresholded(:,:,:,fileIndices);
        fileStruct(1).smddff0 = smddff0(:,fileIndices);
        
        fileStruct(1).blobs = blobs(:,fileIndices);
        fileStruct(1).hulls = hulls(:,fileIndices);
        fileStruct(1).masks = masks(:,fileIndices);
        fileStruct(1).areas = areas(:,fileIndices);
        fileStruct(1).centroidBinary = centroidBinary(:,:,fileIndices);
        fileStruct(1).centroidWeighted = centroidWeighted(:,:,fileIndices);
        fileStruct(1).maxXY = [maxX(:,fileIndices) maxY(:,fileIndices)];
        
        save([filePrefixes{ii} '_analysed.mat'],'-struct','fileStruct');
        toc;
    end
    
%     if ~isSubtract
%         x = repmat(1:framesPerTrial,1,nStimuli)';
%         y = smddff0(:);
%         p = polyfit(x,y,2);
%     end
%     
%     mddff0 = bsxfun(@minus,mddff0,permute(bsxfun(@minus,polyval(p,1:60)',smddff0),[3 4 1 2]));
%     
%     smddff0 = squeeze(sum(sum(mddff0)));
    
    fig = fluorescenceVideoBrowser(W,mddff0,baselineFrames,frameRate,fovMoves,mddff0Thresholded,smddff0,hulls,masks,centroidBinary,centroidWeighted,maxX,maxY);
end