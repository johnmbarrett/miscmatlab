function [grid,beta] = fitGridToSpots(images,rows,cols,varargin) % TODO : name value pairs
    parser = inputParser;
    parser.addRequired('images',@(X) (iscell(X) && (all(cellfun(@ischar,X)) || (isstruct(X) && isfield(X,'name')) || all(cellfun(@(x) isnumeric(x) && ismember(ndims(x),[2 3]) && all(isfinite(x(:))),X)))) || (isnumeric(x) && ismember(ndims(x),[3 4]) && all(isfinite(X(:)))));
    
    isPositiveScalarInteger = @(x) isscalar(x) && isnumeric(x) && isfinite(x) && x > 0 && x == round(x);
    parser.addRequired('rows',isPositiveScalarInteger);
    parser.addRequired('cols',isPositiveScalarInteger);
    
    parser.addParameter('ManualDetection',false,@(x) isscalar(x) && islogical(x));
    parser.addParameter('ThresholdMethod','absolute',@(x) ischar(x) && any(strcmpi(x,{'absolute' 'percentile'})));
    parser.addParameter('Threshold',254,@(x) isscalar(x) && isnumeric(x) && isfinite(x) && x >=0 && x <= 255);
    parser.parse(images,rows,cols,varargin{:});
    
    threshold = parser.Results.Threshold;
    isPercentileThreshold = strcmpi(parser.Results.ThresholdMethod,'percentile');
    
    if isPercentileThreshold && threshold > 100
        threshold = 100;
    end
    
    nImages = rows*cols;
    
    CX = cell(nImages,1);
    CY = cell(nImages,1);
    
    if manualBlobDetection
        fig = figure;
    end
    
    if iscell(images)
        images = images{1:nImages};
        sizeI = size(imread(images{1}));
    elseif isstruct(images)
        images = images(1:nImages);
        sizeI = size(imread(images(1).name));
    else
        index = repmat({':'},1,ndims(images)-1);
        index{end+1} = 1:nImages;
        images = images(index{:});
        sizeI = size(images);
    end
    
    [Y,X] = ndgrid(1:sizeI(1),1:sizeI(2));
    
    for ii = 1:nImages
        if iscell(images)
            image = images{ii};
            
            if ischar(image)
                I = imread(image);
            else
                index = repmat({':'},1,ndims(image)-1);
                index{end+1} = ii; %#ok<AGROW>
                I = image(index{:});
            end
        elseif isstruct(images)
            I = imread(images(ii).name);
        else
            index{end} = ii;
            I = images(index{:});
        end
        
        if isPercentileThreshold
            threshold = prctile(I(:),threshold); % TODO : choose threshold?
        end

        CC = bwconncomp(I > threshold);
        
        nBlobs = numel(CC.PixelIdxList);
        
        if ~parser.Results.ManualDetection
            [~,biggestBlobIndex] = max(cellfun(@numel,CC.PixelIdxList));
            
            blob = CC.PixelIdxList{biggestBlobIndex};
            
            CX{ii} = X(blob);
            CY{ii} = Y(blob);
            
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
end