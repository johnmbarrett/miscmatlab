topDir = 'Z:\LACIE\DATA\John\ephys\sensory stim\';
experiments = readtable([topDir 'all sensory imaging.xlsx']);
%%
isGoodForepawStim = strcmp(experiments.BodyPart,'Forepaw') & ~strcmp(experiments.StimSide,experiments.ImageSide) & cellfun(@isempty,experiments.Pharma);

experiments = experiments(isGoodForepawStim,:);
%%
[uniqueDates,~,dateIndices] = unique(experiments.Date);
%%
baselineFrames = [0 0];

nExperiments = size(experiments,1);

peakImages = zeros(48,64,nExperiments);
brainImages = zeros(48,64,nExperiments);

wb = waitbar(0,'Reticulating splines...');

for ii = 1:numel(uniqueDates)
    cd(sprintf('%s\\%s',topDir,datestr(uniqueDates(ii),'yyyymmdd')));
    
    if exist('.\fpafi','dir')
        cd('fpafi');
    end
    
    for jj = find(dateIndices == ii)'
        stimPrefix = sprintf('stim%d',experiments.Stim(jj));
        framesPerSecond = experiments.FPS(jj);
        framesPerSweep = framesPerSecond*experiments.SweepLength(jj);
        nSweeps = experiments.x_Sweeps(jj);
        baselineFrames(2) = framesPerSweep/2;
        baselineFrames(1) = baselineFrames(2)-framesPerSecond+1;
        nStimuli = experiments.x_Stimuli(jj);
        subtractStyle = experiments.SubtractStyle{jj}(1);
        temporalBinning = 1;
        
        [dff0,V,fig] = fluorescentHotspotDetector(stimPrefix,framesPerSweep,nSweeps,baselineFrames,nStimuli,subtractStyle,temporalBinning);
        close(fig);
        
        brainImages(:,:,jj) = V(:,:,1);
        
        mdff0 = mean(dff0,5);
        sdff0 = squeeze(sum(sum(mdff0(:,:,(baselineFrames(2)+1):end,:))));
        [~,maxI] = max(sdff0(:));
        [maxT,maxS] = ind2sub(size(sdff0),maxI);
        
        peakImage = mdff0(:,:,maxT+baselineFrames(2),maxS);
        
        if std(peakImage(:)) == 0
            peakImage = zeros(size(peakImage));
        else
            peakImage = (peakImage-min(peakImage(:)))/(max(peakImage(:))-min(peakImage(:)));
        end
        
        peakImages(:,:,jj) = peakImage;
        
        waitbar(jj/nExperiments,wb);
    end
end

close(wb);

%%

cd(topDir);
save('forepaw.mat','brainImages','peakImages');

%%

tfs(1) = makeAffineTransformation(0,0,1,0);

for ii = nExperiments
    figure
    set(gcf,'Position',[2561 281 1920 1083]);
    colormap(gray)
    
    indices = [ii 1 ii-1 find(dateIndices == dateIndices(ii),1)];
    titles = {sprintf('%s Stim %d',datestr(experiments.Date(ii),'yyyy-mm-dd'),experiments.Stim(ii)) '1. First ever brain image' '2. Previous brain image' '3. First brain image of the day'};
    
    for jj = 1:4
        subplot(2,2,jj);
        imagesc(brainImages(:,:,indices(jj)));
        daspect([1 1 1]);
        title(titles{jj});
    end
    
    selection = NaN;
    
    while ~isnumeric(selection) || ~isscalar(selection) || ~isfinite(selection) || selection ~= round(selection) || selection < 1 || selection > 3
        selection = input('Register against? (Enter 1-3) ');
    end
    
    close(gcf);
    
    index = indices(selection+1);
    
    tfs(ii) = registerImages(brainImages(:,:,index),brainImages(:,:,ii)); %#ok<SAGROW>
    
    if index > 1
        tfs(ii) = affine2d(tfs(ii).T*tfs(index).T); %#ok<SAGROW>
    end
end

%%
twoXImageIndices = find(strcmp(experiments.Lens,'2X'))';

%%

isGood = false(size(twoXImageIndices));

figure

for ii = twoXImageIndices
    imagesc(peakImages(:,:,ii));
    isGood(ii) = strncmpi(input('Good? ','s'),'y',1);
end

%%

goodImageIndices = twoXImageIndices(isGood);

bigPeakImage = zeros(size(peakImages,1)*5,size(peakImages,2)*5);
weights = zeros(size(bigPeakImage));

ref1 = imref2d(size(peakImages(:,:,1)),[2 3]*size(peakImages,2)+0.5,[2 3]*size(peakImages,1)+0.5);

for ii = goodImageIndices
    tic;
    [warpedImage,ref2] = imwarp(peakImages(:,:,ii),ref1,tfs(ii));
    
    x = (ref2.XWorldLimits(1)+0.5):(ref2.XWorldLimits(2)-0.5);
    y = (ref2.YWorldLimits(1)+0.5):(ref2.YWorldLimits(2)-0.5);
    
    bigPeakImage(y,x) = bigPeakImage(y,x)+warpedImage;
    weights(y,x) = weights(y,x)+1;
    toc;
end

bigPeakImage = bigPeakImage./weights;

%%

save('forepaw.mat','-append','tfs','isGood','bigPeakImage');

%%

figure
colormap(gray)
imagesc(brainImages(:,:,1));
daspect([1 1 1]);
bregma = drawpoint;
bregmaPixels = get(bregma,'Position') + fliplr(size(brainImages(:,:,1))*2);

colormap(parula)
imagesc(bigPeakImage);
flS1Pixels = zeros(2,2);

for ii = 1:2
    flS1 = drawpoint;
    flS1Pixels(ii,:) = get(flS1,'Position');
end

%%

flS1PixelsRelativeToBregma = bsxfun(@minus,flS1Pixels,bregmaPixels);
flS1PixelsRelativeToBregma(:,2) = abs(flS1PixelsRelativeToBregma(:,2));

%%

load('Z:\LACIE\DATA\John\Videos\calibration\blackfly\20181029\calibration.mat','pxpmm');
pxpmm = pxpmm/16;
flS1mm = mean(flS1PixelsRelativeToBregma/pxpmm);

%%

cd(topDir);

saveas(gcf,'forepaw','png');
saveas(gcf,'forepaw','fig');
save('forepaw.mat','-append','bregmaPixels','flS1Pixels','flS1mm');