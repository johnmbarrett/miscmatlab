function [grid,beta] = fitGridToSpots(rows,cols,fileDir,blankImage,manualBlobDetection,threshold) % TODO : name value pairs
    if nargin < 6
        threshold = 254;
    end
    
    if nargin < 5
        manualBlobDetection = false;
    end
    
    if nargin < 4
        blankImage = 2;
    end
    
    firstImage = 3-blankImage;
    
    if nargin < 1
        rows = 12;
    end
    
    if nargin < 2
        cols = 12;
    end
    
    if nargin < 3
        fileDir = uigetdir(pwd,'Choose image folder...');
    end
    
    cd(fileDir);
    laserImages = dir('*.bmp');
    
    blankImage = imread(laserImages(blankImage).name); % TODO : is this always true?
    
    [~,si] = sort(cellfun(@(A) str2double(A{1}{1}),cellfun(@(s) regexp(s,'tt([0-9])+','tokens'),{laserImages.name},'UniformOutput',false))); % TODO : introduced method, also specify regex
    
    laserImages = laserImages(si);
    laserImages = laserImages(firstImage:2:end); % TODO : is this always true
    
    nImages = rows*cols;
    laserImages = laserImages(1:nImages);
    
    [Y,X] = ndgrid(1:size(blankImage,1),1:size(blankImage,2));
    
    CX = cell(nImages,1);
    CY = cell(nImages,1);
    
    if manualBlobDetection
        fig = figure;
    end
    
    for ii = 1:nImages
        I = imread(laserImages(ii).name);
        
%         threshold = prctile(I(:),98); % TODO : choose threshold?

        CC = bwconncomp(I > threshold);
        
        nBlobs = numel(CC.PixelIdxList);
        
        if ~manualBlobDetection
            [~,biggestBlobIndex] = max(cellfun(@numel,CC.PixelIdxList));
            
            blob = CC.PixelIdxList{biggestBlobIndex};
            
            CX{ii} = X(blob);
            CY{ii} = Y(blob);
            
            test = zeros(512,640);
            test(blob) = 1;
            imagesc(test)
            
            continue;
        end
        
        colours = reshape(distinguishable_colors(nBlobs),1,1,nBlobs,3);
        
        blobs = zeros([size(I) nBlobs 3]);
        
        for jj = 1:nBlobs
            B = zeros(size(I));
            B(CC.PixelIdxList{jj}) = 1;
            blobs(:,:,jj,:) = repmat(B,1,1,1,3);
        end
        
        blobs = squeeze(sum(bsxfun(@times,blobs,colours),3));
        
        imagesc(blobs);
        
        for jj = 1:nBlobs
            centreX = mean(X(CC.PixelIdxList{jj}));
            centreY = mean(Y(CC.PixelIdxList{jj}));
            text(centreX,centreY,sprintf('#%d',jj),'Color',1-colours(1,1,jj,:),'HorizontalAlignment','center','VerticalAlignment','middle');
        end
        
        title('Choose the blob!');
        blobIndex = [];
        
        while isempty(blobIndex)
            pt = impoint;
            pos = round(getPosition(pt));
            idx = sub2ind(size(I),pos(2),pos(1));
            
            blobIndex = find(cellfun(@(blob) ismember(idx,blob),CC.PixelIdxList),1);
        end
        
        blob = CC.PixelIdxList{blobIndex};
        
        CX{ii} = X(blob);
        CY{ii} = Y(blob);
    end
    
    if manualBlobDetection
        close(fig);
    end
    
    % TODO : always column-major starting from top left?
    R = arrayfun(@(C,r) r*ones(numel(C{1}),1),CY,kron((rows:-1:1)',ones(cols,1)),'UniformOutput',false);
    C = arrayfun(@(D,c) c*ones(numel(D{1}),1),CX,repmat((1:cols)',rows,1),'UniformOutput',false);
    
    r = vertcat(R{:});
    c = vertcat(C{:});
    
    beta = mvregress([ones(size(r)) c r],[vertcat(CX{:}) vertcat(CY{:})]);
    grid = [ones(nImages,1) repmat((1:cols)',rows,1) kron((1:rows)',ones(cols,1))]*beta;
    
    figure;
    
    imagesc(blankImage);
    colormap(gray);
    
    hold on;
    
    scatter(cellfun(@mean,CX),cellfun(@mean,CY));
    scatter(grid(:,1),grid(:,2));
    
    [~,lastDir] = fileparts(pwd);
    
    saveFile = [lastDir '_laser_grid'];
    
    save(saveFile,'grid','beta','CX','CY','rows','cols');
    saveas(gcf,saveFile,'fig');
end