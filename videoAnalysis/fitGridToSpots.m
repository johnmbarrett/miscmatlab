function [grid,beta,CX,CY] = fitGridToSpots(images,rows,cols,varargin) % TODO : name value pairs
    parser = inputParser;
    parser.KeepUnmatched = true;
    parser.addRequired('images',@(X) iscellstr(X) || (isstruct(X) && isfield(X,'name')) || (iscell(X) && all(cellfun(@(x) isnumeric(x) && ismember(ndims(x),[2 3]) && all(isfinite(x(:))),X))) || (isnumeric(X) && ismember(ndims(X),[3 4]) && all(isfinite(X(:)))));
    
    isPositiveScalarInteger = @(x) isscalar(x) && isnumeric(x) && isfinite(x) && x > 0 && x == round(x);
    parser.addRequired('rows',isPositiveScalarInteger);
    parser.addRequired('cols',isPositiveScalarInteger);
    
    parser.addParameter('BackgroundSubtraction',false,@(x) isscalar(x) && islogical(x));
    parser.addParameter('BackgroundImage',0,@(x) isnumeric(x) && ismatrix(x) && all(isreal(x(:)) & isfinite(x(:))));
    parser.addParameter('ManualDetection',false,@(x) isscalar(x) && islogical(x));
    parser.addParameter('ThresholdMethod','absolute',@(x) ischar(x) && any(strcmpi(x,{'absolute' 'percentile'})));
    parser.addParameter('Threshold',Inf,@(x) isscalar(x) && isnumeric(x) && isfinite(x) && x >=0 && x <= 255);
    parser.parse(images,rows,cols,varargin{:});
    
    threshold = parser.Results.Threshold;
    isPercentileThreshold = strcmpi(parser.Results.ThresholdMethod,'percentile');
    
    if isPercentileThreshold
        percentileThreshold = min(threshold,100);
    end
    
    nImages = rows*cols;
    
    CX = cell(nImages,1);
    CY = cell(nImages,1);
    
    if parser.Results.ManualDetection
        fig = figure;
    end
    
    if iscell(images)
        images = images(1:nImages);
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
        
        if parser.Results.BackgroundSubtraction
            I = I - parser.Results.BackgroundImage;
        end
        
        if isPercentileThreshold
            threshold = prctile(I(:),percentileThreshold); % TODO : choose threshold?
        end

        if isfinite(threshold)
            CC = bwconncomp(I > threshold);
        else
            CC = bwconncomp(I == max(I(:)));
        end
        
        nBlobs = numel(CC.PixelIdxList);
        
        if ~parser.Results.ManualDetection
            [~,biggestBlobIndex] = max(cellfun(@numel,CC.PixelIdxList));
            
            blob = CC.PixelIdxList{biggestBlobIndex};
        
            CX{ii} = X(blob);
            CY{ii} = Y(blob);
            
            % TODO : expose an option to show this
%             J = zeros(size(I));
%             J(blob) = 1;
%             
%             imshow(J);
%             
%             drawnow;
            
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
    
    if parser.Results.ManualDetection
        close(fig);
    end
    
    N = cellfun(@numel,CX);
    
    assert(isequal(N,cellfun(@numel,CY)));
    
    R = arrayfun(@(n,r) r*ones(n,1),N,repmat((1:rows)',cols,1),'UniformOutput',false);
    C = arrayfun(@(n,c) c*ones(n,1),N,kron((1:cols)',ones(rows,1)),'UniformOutput',false);
    
    r = vertcat(R{:});
    c = vertcat(C{:});
    
    % In the image processing toolbox, columns (i.e. X) always come before
    % rows (i.e. Y).  Hence if we specify the predictors this way round, we
    % can multiply the fixed points by the grid params to get the moving
    % points to fit the alignment transform.
    beta = mvregress([ones(size(r)) c r],[vertcat(CX{:}) vertcat(CY{:})]);
    grid = [ones(nImages,1) kron((1:cols)',ones(rows,1)) repmat((1:rows)',cols,1)]*beta;
end