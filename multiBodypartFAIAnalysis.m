topDir = 'Z:\LACIE\DATA\John\ephys\sensory stim\';
experimentSpreadsheet = [topDir 'all sensory imaging.xlsx'];
allExperiments = readtable(experimentSpreadsheet);

isGoodStim = ...
...%     strcmp(experiments.BodyPart,'Forepaw') & ...
    ~strcmp(allExperiments.StimSide,allExperiments.ImageSide) & ...
    cellfun(@isempty,allExperiments.Pharma) & ...
    strcmp(allExperiments.Modality,'FAI') & ...
    strcmp(allExperiments.Lens,'2X') & ...
    strcmp(allExperiments.Good,'Y') & ...
    ismember(cellfun(@str2double,allExperiments.Amp),1) & ...
    cellfun(@str2double,allExperiments.Duration) == 1;

experimentIndices = find(isGoodStim);
experiments = allExperiments(isGoodStim,:);

[uniqueDates,~,dateIndices] = unique(experiments.Date);
%%

% baselineFrames = [0 0];

nExperiments = size(experiments,1);

% peakImages = zeros(48,64,nExperiments);
bregmaImageIndices = find(ismember(allExperiments.Date,uniqueDates) & allExperiments.ContainsBregma == 1 & allExperiments.MovedFOV == 1);
useReferenceImageIndices = arrayfun(@(date) find(allExperiments.Date == date,1),setdiff(uniqueDates,allExperiments.Date(bregmaImageIndices)));
bregmaImageIndices = [bregmaImageIndices; useReferenceImageIndices];
nBregmaImages = numel(bregmaImageIndices);
bregmaImages = zeros(768,1024,nBregmaImages);
stimBrainImages = zeros(768,1024,nExperiments);
goodHulls = cell(1,nExperiments);
mdff0 = zeros(48,64,100,nExperiments);

%%
wb = waitbar(0,'Reticulating splines...');

nn = 0;
for ii = 1:numel(uniqueDates)
    cd(sprintf('%s\\%s',topDir,datestr(uniqueDates(ii),'yyyymmdd')));
    
    if exist('.\fpafi','dir')
        cd('fpafi');
    end
    
%     load('stim1_binned.mat','V');
    
%     for jj = find(allExperiments.Date == uniqueDates(ii) & allExperiments.MovedFOV ~= 0)'
%         stim = allExperiments.Stim(jj);
%         load(sprintf('stim%d_binned.mat',stim),'V');
%         
%         figure
%         imagesc(V(:,:,1));
%         colormap(gray);
%         daspect([1 1 1]);
%         title(sprintf('Date %s stim %d',datestr(uniqueDates(ii),'yyyy-mm-dd'),stim));
%     end

    dailyBregmaImageIndices = bregmaImageIndices(allExperiments.Date(bregmaImageIndices) == uniqueDates(ii))';
    
    assert(~isempty(dailyBregmaImageIndices),'This shouldn''t happen');
    
    for jj = dailyBregmaImageIndices
        nn = nn + 1;
        
        if ismember(jj,useReferenceImageIndices)
            if exist('.\bregma image.tiff','file')
                bregmaImage = imread('.\bregma image.tiff');
            end
        else
%             load(sprintf('stim%d_binned.mat',allExperiments.Stim(jj)),'V');
%             bregmaImage = V(:,:,1);

            avis = dir(sprintf('stim%d-*-0000.avi',allExperiments.Stim(jj)));
            
            assert(numel(avis) == 1);
            
            r = VideoReader(avis(1).name);
            
            bregmaImage = mean(double(readFrame(r)),3);
        end
        
        bregmaImages(:,:,nn) = bregmaImage;
    end
    
    for jj = find(dateIndices == ii)'
        stimPrefix = sprintf('stim%d',experiments.Stim(jj));
        
%         load(sprintf('%s_binned.mat',stimPrefix),'V');
%         framesPerSecond = experiments.FPS(jj);
%         framesPerSweep = framesPerSecond*experiments.SweepLength(jj);
%         nSweeps = experiments.x_Sweeps(jj);
%         baselineFrames(2) = framesPerSweep/2;
%         baselineFrames(1) = baselineFrames(2)-framesPerSecond+1;
%         nStimuli = experiments.x_Stimuli(jj);
%         subtractStyle = experiments.SubtractStyle{jj}(1);
%         temporalBinning = 1;
%         
%         [dff0,V,fig] = fluorescentHotspotDetector(stimPrefix,framesPerSweep,nSweeps,baselineFrames,nStimuli,subtractStyle,temporalBinning);
%         close(fig);

        avis = dir(sprintf('%s-*-0000.avi',stimPrefix));
            
        assert(numel(avis) == 1);

        r = VideoReader(avis(1).name);

        stimBrainImages(:,:,jj) = mean(double(readFrame(r)),3);
        
%         mdff0 = mean(dff0,5);
%         sdff0 = squeeze(sum(sum(mdff0(:,:,(baselineFrames(2)+1):end,:))));
%         [~,maxI] = max(sdff0(:));
%         [maxT,maxS] = ind2sub(size(sdff0),maxI);
%         
%         peakImage = mdff0(:,:,maxT+baselineFrames(2),maxS);
%         
%         if std(peakImage(:)) == 0
%             peakImage = zeros(size(peakImage));
%         else
%             peakImage = (peakImage-min(peakImage(:)))/(max(peakImage(:))-min(peakImage(:)));
%         end
%         
%         peakImages(:,:,jj) = peakImage;

        load(sprintf('%s_analysed.mat',stimPrefix),'dff0','hulls');
        
        if strncmpi(experiments.SubtractStyle(jj),'a',1) % TODO : first stim subtract style
            dff0 = dff0(:,:,:,2:2:end);
        end
        
        mdff0(:,:,:,jj) = mean(dff0,4); % TODO : stimuli?
        goodHulls{jj} = hulls{70};
        
        waitbar(jj/nExperiments,wb);
    end
end

close(wb);
%%
[bodyParts,~,bodyPartIndices] = unique(experiments.BodyPart);
nBodyParts = numel(bodyParts);
nPerBodyPart = accumarray(bodyPartIndices,1,size(bodyParts));
colours = distinguishable_colors(nBodyParts);

figure
colormap(gray);

[rows,cols] = subplots(nExperiments);

for ii = 1:nExperiments
    subplot(rows,cols,ii);
    imagesc(stimBrainImages(:,:,ii));
    daspect([1 1 1]);
    hold on;
    M = kron(mdff0(:,:,70,ii),ones(16,16));
    minDFF0 = min(M(:));
    maxDFF0 = max(M(:));
    imagesc(cat(3,ones(size(M)),zeros(size(M)),zeros(size(M))),'AlphaData',0.5*(M-minDFF0)/(maxDFF0-minDFF0));
%     fill(goodHulls{ii}(:,1),goodHulls{ii}(:,2),[0 0 0],'EdgeColor',colours(bodyPartIndices(ii),:),'FaceColor','none');
end

%%

% figure
% imagesc(stimBrainImages(:,:,end));
% I = zeros(768,1024,3);
% uniqueDates = uniqueDates; %#ok<ASGSL> fix bizarre matlab error that stops this block being run
% 
% goodBodyParts = {'Forepaw' 'Hindpaw' 'Whiskers'};
% 
% for ii = 1:3
%     J = kron(mdff0(:,:,80,experiments.Date == uniqueDates(end) & strcmp(experiments.BodyPart,goodBodyParts{ii})),ones(16,16));
%     J = (J-min(J(:)))/(max(J(:))-min(J(:)));
%     I(:,:,ii) = J*(1+(ii==1));
% end
% 
% hold on;
% imagesc(I,'AlphaData',0.5);

%%

bregmas = zeros(nBregmaImages,2); % TODO : hokey
figure;
colormap(gray);

for ii = 1:nBregmaImages
    bregmaImageIndex = bregmaImageIndices(ii);
    
    if ~isnan(allExperiments.BregmaX(bregmaImageIndex)) && ~isnan(allExperiments.BregmaY(bregmaImageIndex))
        bregmas(ii,:) = [allExperiments.BregmaX(bregmaImageIndex) allExperiments.BregmaY(bregmaImageIndex)];
        continue
    end
    
    imagesc(bregmaImages(:,:,ii));
    daspect([1 1 1]);
    h = drawpoint;
    bregmas(ii,:) = get(h,'Position');
    delete(h);
    xlswrite(experimentSpreadsheet,bregmas(ii,:),'Sheet1',sprintf('X%d:Y%d',bregmaImageIndex+1,bregmaImageIndex+1));
end

close(gcf);

%%

allBregmaImages = zeros(2048,2048,2);
allBregmaWeights = zeros(size(allBregmaImages));

flipMatrices = repmat(eye(3),1,1,nBregmaImages,2);

isFlip = strcmp(allExperiments.ImageSide(bregmaImageIndices),'Left'); % TODO : doesn't necessarily hold for stims that use a referenceImage
flipMatrices(2,2,isFlip,2) = -1;

for ii = 1:nBregmaImages
    for jj = 1:2
        tf = makeAffineTransformation(-bregmas(ii,1),-bregmas(ii,2),1,0);
        tf = affine2d(tf.T*flipMatrices(:,:,ii,jj));
        bregmaImage = bregmaImages(:,:,ii);
        [warpedImage,ref] = imwarp(bregmaImage,imref2d(size(bregmaImage)),tf);
        x = round(ref.XWorldLimits(1)+(0:1023)+1024);
        y = round(ref.YWorldLimits(1)+(0:767)+1024);
        allBregmaImages(y,x,jj) = allBregmaImages(y,x,jj) + warpedImage;
        allBregmaWeights(y,x,jj) = allBregmaWeights(y,x,jj) + 1;
    end
end

allBregmaImages = allBregmaImages./allBregmaWeights;

as = gobjects(1,2);

for ii = 1:2
    figure;
    as(ii) = axes;
    imagesc(allBregmaImages(:,:,ii),'AlphaData',logical(allBregmaWeights(:,:,ii)));
    colormap(gray);
    daspect([1 1 1]);
    hold(as(ii),'on');
end

%%

cd(topDir);

for ii = 1:nBregmaImages
    tic;
    imwrite(uint16(bregmaImages(:,:,ii)),sprintf('bregma_image_%s.tif',datestr(allExperiments.Date(bregmaImageIndices(ii)),'yyyymmdd')));
    toc;
end

%%

experimentTFs = repmat(makeAffineTransformation(0,0,1,0),nExperiments,1);  

% [optimizer,metric] = imregconfig('multimodal');

lastMovedFOV = NaN;

% TODO : no need to do it for every stim -- make use of the MovedFOV field to only make a new transform when we move the FOV
for ii = 1:nExperiments
    tic;
    if ~isempty(experiments.BregmaOffset{ii})
        offset = str2num(experiments.BregmaOffset{ii}); %#ok<ST2NM>
        experimentTFs(ii) = makeAffineTransformation(offset(1),offset(2),1,0);
        lastMovedFOV = ii;
        continue
    end

    if ~isnan(lastMovedFOV) && all(allExperiments.MovedFOV((experimentIndices(lastMovedFOV)+1):experimentIndices(ii)) == 0)
        experimentTFs(ii) = experimentTFs(lastMovedFOV);
        continue
    end
    
    lastMovedFOV = ii;
    
    imwrite(uint16(stimBrainImages(:,:,ii)),sprintf('stim_brain_image_%s_stim_%02d.tif',datestr(experiments.Date(ii),'yyyymmdd'),experiments.Stim(ii)));
    
    toc;
    
    continue
    
%     if experiments.ContainsBregma(ii) == 1
%         continue
%     end
    
    dailyBregmaImageIndices = find(allExperiments.MovedFOV == 1 & allExperiments.ContainsBregma == 1 & allExperiments.Date == uniqueDates(dateIndices(ii)) & allExperiments.Stim <= experiments.Stim(ii),1,'last');
    
    if isempty(dailyBregmaImageIndices)
        bregmaImageIndex = bregmaImageIndices == find(allExperiments.Date == uniqueDates(dateIndices(ii)),1);
    elseif numel(dailyBregmaImageIndices) > 1
        error('Something very bad has happened.');
    else
        bregmaImageIndex = bregmaImageIndices == dailyBregmaImageIndices;
    end

    registerAgainst = bregmaImages(:,:,bregmaImageIndex);
    
    if isempty(registerAgainst)
        error('I''m not entirely sure what happened here.');
    end
    
    experimentTFs(ii) = registerImages(registerAgainst,stimBrainImages(:,:,ii));

    xlswrite(experimentSpreadsheet,{sprintf('[%d %d]',experimentTFs(ii).T(3,1),experimentTFs(ii).T(3,2))},'Sheet1',sprintf('W%d',experimentIndices(ii)+1));

%     experimentTFs(ii) = imregtform(stimBrainImages(:,:,ii),registerAgainst,'translation',optimizer,metric);
%     
%     stimRegistered = imwarp(stimBrainImages(:,:,ii),experimentTFs(ii),'OutputView',imref2d(size(registerAgainst)));
%     
%     imshowpair(registerAgainst,stimRegistered);
%     
%     input('...');

%      registrationEstimator(stimBrainImages(:,:,ii),registerAgainst);
%      
%      uiwait;
end



%%

mdff0reg = nan(128,128,size(mdff0,3),nExperiments);

figure;
colormap(gray);

for ii = 1:nExperiments
    tic;
    if isequal(experimentTFs.T,eye(3))
        continue
    end
    
    subplot(rows,cols,ii);
    
    % TODO : duplicated code
    dailyBregmaImageIndices = find(allExperiments.MovedFOV == 1 & allExperiments.ContainsBregma == 1 & allExperiments.Date == uniqueDates(dateIndices(ii)) & allExperiments.Stim <= experiments.Stim(ii),1,'last');
    
    if isempty(dailyBregmaImageIndices)
        bregmaImageIndex = bregmaImageIndices == find(allExperiments.Date == uniqueDates(dateIndices(ii)),1);
    elseif numel(dailyBregmaImageIndices) > 1
        error('Something very bad has happened.');
    else
        bregmaImageIndex = bregmaImageIndices == dailyBregmaImageIndices;
    end
   
    tf = makeAffineTransformation(-bregmas(bregmaImageIndex,1),-bregmas(bregmaImageIndex,2),1,0);
    toc;
    
    tic;
    I = zeros(2048,2048);
    
    [~,ref] = imwarp(bregmaImages(:,:,bregmaImageIndex),imref2d(size(bregmaImages(:,:,bregmaImageIndex))),tf);
    x = round(ref.XWorldLimits(1)+(0:1023)+1024);
    y = round(ref.YWorldLimits(1)+(0:767)+1024);
    
    I(y,x) = bregmaImages(:,:,bregmaImageIndex);
    imagesc(I);
    daspect([1 1 1]);
    hold on;
    
    if experiments.ContainsBregma(ii) == 0
        tf = affine2d(tf.T*experimentTFs(ii).T);
    end
    toc;
    
    tic;
    Msmall = zeros(768,1024,100);
    
    for jj = 1:100
        Msmall(:,:,jj) = kron(mdff0(:,:,jj,ii),ones(16,16));
    end
    toc;
    
    tic;
    [Mwarp,ref] = imwarp(Msmall,imref2d(size(Msmall)),tf);
    toc;
    
    tic;
    Mbig = zeros(2048,2048,100);
    x = round(ref.XWorldLimits(1)+(0:1023)+1024);
    y = round(ref.YWorldLimits(1)+(0:767)+1024);
    Mbig(y,x,:) = Mwarp;
    
    mdff0reg(:,:,:,ii) = bin(Mbig,16);
    tic;
    
    tic;
    [x,y] = transformPointsForward(tf,goodHulls{ii}(:,1)*16,goodHulls{ii}(:,2)*16);
    
    plot(x+1024,y+1024,'Color',colours(bodyPartIndices(ii),:));
    
    for jj = 1:2
        [u,v] = transformPointsForward(affine2d(flipMatrices(:,:,bregmaImageIndex,jj)),x,y);
        plot(as(jj),u+1024,v+1024,'Color',colours(bodyPartIndices(ii),:));
    end
    
    toc;
end

%%

figure;

cc = [Inf -Inf];
    
for ii = 1:nExperiments
    subplot(rows,cols,ii);
    imagesc(mean(mdff0(:,:,61:70,ii),3));
    daspect([1 1 1]);
    cc(1) = min(cc(1),min(caxis));
    cc(2) = max(cc(2),max(caxis));
    title(sprintf('%s stim %d (%s)',datestr(experiments.Date(ii),'yyyy-mm-dd'),experiments.Stim(ii),experiments.BodyPart{ii}));
end

for ii = 1:nExperiments
    subplot(rows,cols,ii);
    caxis(cc)
end

%%

figure;

for ii = 1:nExperiments
    subplot(rows,cols,ii);
    imagesc(nanmean(mdff0reg(:,:,61:70,ii),3),'AlphaData',~isnan(nanmean(mdff0reg(:,:,71:80,ii),3)));
    daspect([1 1 1]);
    caxis(cc);
end

%%

figure;

for ii = 1:nExperiments
    subplot(rows,cols,ii);
    imagesc(nanmean(mdff0reg(:,:,41:60,ii),3),'AlphaData',~isnan(nanmean(mdff0reg(:,:,41:60,ii),3)));
    daspect([1 1 1]);
    caxis(cc);
end

%%

mdff0bp = zeros(128,128,100,nBodyParts);
ndff0bp = zeros(128,128,100,nBodyParts);
zdff0bp = zeros(128,128,100,nBodyParts);

for ii = 1:nBodyParts
    mdff0ii = mdff0reg(:,:,:,bodyPartIndices == ii);
    
    mdff0bp(:,:,:,ii) = nanmean(mdff0ii,4);
    
    minDFF0 = min(min(min(mdff0ii)));
    maxDFF0 = max(max(max(mdff0ii)));
    
    ndff0bp(:,:,:,ii) = nanmean(bsxfun(@rdivide,bsxfun(@minus,mdff0ii,minDFF0),maxDFF0-minDFF0),4);
    
    muDFF0 = reshape(nanmean(reshape(mdff0ii,[],size(mdff0ii,4))),size(minDFF0));
    sigmaDFF0 = reshape(nanstd(reshape(mdff0ii,[],size(mdff0ii,4))),size(minDFF0));
    
    zdff0bp(:,:,:,ii) = nanmean(bsxfun(@rdivide,bsxfun(@minus,mdff0ii,muDFF0),sigmaDFF0),4);
end

%%

load('Z:\LACIE\DATA\John\Videos\calibration\blackfly\20181029\calibration.mat','pxpmm');
pxpmm = pxpmm/16;

%%

figure;

cc = [Inf -Inf];

for ii = 1:nBodyParts
    subplot(2,3,ii);
    x = ((1:128)-64)/pxpmm;
    y = ((1:128)-64)/pxpmm;
    I = mean(mdff0bp(:,:,71:80,ii),3);
    imagesc(x,y,I);
    daspect([1 1 1]);
    title(bodyParts{ii});
    cc(1) = min(cc(1),min(caxis));
    cc(2) = max(cc(2),max(caxis));
end

for ii = 1:nBodyParts
    subplot(2,3,ii);
    caxis(cc);
end

%%

C = squeeze(mean(mdff0bp(:,:,71:80,[1 2 5]),3));
C = (C-min(C(:)))/(max(C(:))-min(C(:)));
subplot(2,3,6);
imagesc(C);
daspect([1 1 1]);

%%

% figure;

for ii = 1:nBodyParts
    subplot(2,3,ii);
    I = (mean(mdff0bp(:,:,71:80,ii),3)-mean(mdff0bp(:,:,41:60,ii),3));%./std(mdff0bp(:,:,41:60,ii),[],3);
    imagesc(I);
    daspect([1 1 1]);
    title(bodyParts{ii});
    caxis([0 max(I(:))]);
end

%%

figure;

J = mean(reshape(mdff0bp(:,:,41:60,:),128,128,20*nBodyParts),3);
locations = zeros(nBodyParts,2);
bodyPartHulls = cell(1,nBodyParts);
bodyPartCentroids = zeros(nBodyParts,2);

for ii = 1:nBodyParts
    subplot(2,3,ii);
    I = mean(mdff0bp(:,:,71:80,ii),3);
    
    CC = bwconncomp(I > J);
    CC.NumObjects = 1;
    [~,maxBlobIndex] = max(cellfun(@numel,CC.PixelIdxList));
    CC.PixelIdxList = CC.PixelIdxList(maxBlobIndex);
    
    B = false(size(I));
    B(CC.PixelIdxList{1}) = true;
    
    imagesc(B);
    daspect([1 1 1]);
    title(bodyParts{ii});
    
    hullProps = regionprops(B,I,'BoundingBox','ConvexHull','ConvexImage');
    
    bodyPartHulls{ii} = hullProps.ConvexHull;
    
    C = false(size(I));
    C(round(hullProps.BoundingBox(2)+(1:hullProps.BoundingBox(4))-1),round(hullProps.BoundingBox(1)+(1:hullProps.BoundingBox(3))-1)) = hullProps.ConvexImage;
    
    centroidProps = regionprops(C,I,'WeightedCentroid');
    
    bodyPartCentroids(ii,:) = centroidProps.WeightedCentroid;
    
    hold on;
    plot(hullProps.ConvexHull(:,1),hullProps.ConvexHull(:,2),'Color','r');
    plot(centroidProps.WeightedCentroid(1),centroidProps.WeightedCentroid(2),'Color','r','Marker','*');
    
    locations(ii,:) = centroidProps.WeightedCentroid-64;
end

locationsMM = locations/pxpmm;

%%

subplot(2,3,6);
imagesc(repmat(allBregmaImages(:,:,1),1,1,3)/65536);
daspect([1 1 1]);

hold on;

hs = gobjects(nBodyParts+1,1);

for ii = 1:nBodyParts
    hs(ii) = plot(bodyPartHulls{ii}(:,1)*16,bodyPartHulls{ii}(:,2)*16,'Color',colours(ii,:));
    plot(bodyPartCentroids(ii,1)*16,bodyPartCentroids(ii,2)*16,'Color',colours(ii,:),'Marker','*');
end

hs(end) = plot(1024,1024,'Color','k','Marker','+');

legend(hs,[bodyParts; {'Bregma'}],'Location','SouthEast');