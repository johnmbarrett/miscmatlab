targetBodyPart = 'forepaw';
targetSide = 'right';

idx = find(~isnan(BestBlob) & strcmpi(targetBodyPart,BodyPart) & strcmpi(targetSide,Side));

fixedImageIdxIdx = 3;
fixedImageIdx = idx(fixedImageIdxIdx);

switch Person{fixedImageIdx}
    case 'JB'
        cd(sprintf('Z:\\LACIE\\DATA\\John\\Videos\\sensory mapping\\%d\\stim %d',Date(fixedImageIdx),Expt(fixedImageIdx)));
    case 'XL'
        cd(sprintf('Z:\\LACIE\\DATA\\Xiaojian\\Video\\invivo epi imaging\\%d\\%d',Date(fixedImageIdx),Expt(fixedImageIdx)));
end

tiffs = loadFilesInNumericOrder('et*.tiff','et([0-9]+)');

if isempty(tiffs)
    tiffs = dir('*.tif');
    tiffs = {tiffs.name};
end

fixedImage = imread(tiffs{1},'Index',1);

figure;
imagesc(fixedImage);
daspect([1 1 1]);
colormap(gray);

%%

sz = size(fixedImage);
nBlobs = numel(idx);
registeredBlobs = zeros(sz(1),sz(2),nBlobs);
registeredBrains = nan(sz(1),sz(2),nBlobs);
registeredBrains(:,:,fixedImageIdxIdx) = fixedImage;

%%

[uniqueDates,~,dateIndices] = unique(Date(idx));
nDates = numel(uniqueDates);
exptsPerDate = accumarray(dateIndices,1,[nDates 1]);
tfs(find(Date(idx) == Date(fixedImageIdx))) = affine2d(eye(3)); %#ok<FNDSB>

%%
switch Person{idx(1)}
    case 'JB'
        cd(sprintf('Z:\\LACIE\\DATA\\John\\Videos\\sensory mapping\\%d\\stim %d',Date(idx(1)),Expt(idx(1))));
    case 'XL'
        cd(sprintf('Z:\\LACIE\\DATA\\Xiaojian\\Video\\invivo epi imaging\\%d\\%d',Date(idx(1)),Expt(idx(1))));
end

n = 1;
for ii = 1:nDates
    tiffs = loadFilesInNumericOrder('et*.tiff','et([0-9]+)');

    if isempty(tiffs)
        tiffs = dir('*.tif');
        tiffs = {tiffs.name};
    end

    movingImage = imread(tiffs{1},'Index',1);
        
    ref1 = imref2d(size(movingImage));
        
    if false && n ~= fixedImageIdxIdx
        registerImages(fixedImage,movingImage);

        uiwait(gcf);
    
        tfs(find(Date(idx) == Date(idx(n)))) = tf; %#ok<FNDSB>
        
        [warpedImage,ref2] = imwarp(movingImage,ref1,tfs(n));
        
        registeredBrains(round(ref2.YWorldLimits(1):(ref2.YWorldLimits(2)-1)),round(ref2.XWorldLimits(1):(ref2.XWorldLimits(2)-1)),1) = warpedImage; % TODO : what if it doesn't fit?
    end
    
    for jj = 1:exptsPerDate(ii)
        frameIdx = input(sprintf('Which is the best frame of expt %d stim %d blob %d? ',Date(idx(n)),Expt(idx(n)),BestBlob(idx(n))));

        blobFile = dir(sprintf('*%d*bleach_corrected_dff0_fwhm_blobs.mat',Expt(idx(n))));

        assert(numel(blobFile) == 1);

        load(blobFile.name);

        blob = blobs{BestBlob(idx(n))}(:,:,frameIdx);

        scaleFactor = size(movingImage)./size(blob);

        [warpedBlob,ref2] = imwarp(imwarp(blob,affine2d([scaleFactor(2) 0 0; 0 scaleFactor(1) 0; 0 0 1])),ref1,tfs(n));

        registeredBlobs(round(ref2.YWorldLimits(1):(ref2.YWorldLimits(2)-1)),round(ref2.XWorldLimits(1):(ref2.XWorldLimits(2)-1)),n) = warpedBlob; % TODO : what if it doesn't fit?
        
        n = n + 1;
        
        if n > numel(idx)
            break;
        end
        
        switch Person{idx(n)}
            case 'JB'
                cd(sprintf('Z:\\LACIE\\DATA\\John\\Videos\\sensory mapping\\%d\\stim %d',Date(idx(n)),Expt(idx(n))));
            case 'XL'
                cd(sprintf('Z:\\LACIE\\DATA\\Xiaojian\\Video\\invivo epi imaging\\%d\\%d',Date(idx(n)),Expt(idx(n))));
        end
    end
end