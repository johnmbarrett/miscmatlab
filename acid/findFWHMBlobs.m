function [blobs,xs,ys,ts] = findFWHMBlobs(V,maxBlobs,thresholdFactor)
    assert(ndims(V) == 3);
    sizeV = size(V);
    minV = min(V(:));

    blobs = cell(maxBlobs,1);
    xs = zeros(maxBlobs,1);
    ys = zeros(maxBlobs,1);
    ts = zeros(maxBlobs,1);

    function P = getPixelIdxList(B)
        P = cell(size(B.PixelIdxList));
        
        for kk = 1:numel(B.PixelIdxList)
            P{kk} = zeros(size(B.PixelIdxList{kk},1),2);
            [P{kk}(:,1),P{kk}(:,2)] = ind2sub(sizeV(1:2),B.PixelIdxList{kk});
        end
    end

    if nargin < 3
        thresholdFactor = 1/2;
    end
    
    for ii = 1:maxBlobs
        [maxF,maxI] = max(V(:));
        [y,x,t] = ind2sub(sizeV,maxI);
        ys(ii) = y;
        xs(ii) = x;
        ts(ii) = t;
        
        fwhm = V >= maxF*thresholdFactor;
        
        P = getPixelIdxList(bwconncomp(fwhm(:,:,t)));
        p = P{cellfun(@(p) ismember(y,p(:,1)) && ismember(x,p(:,2)),P)};
        n = size(p,1);
        
        blob = zeros(sizeV);
        blob(sub2ind(sizeV,p(:,1),p(:,2),t*ones(n,1))) = 1;
        V(sub2ind(sizeV,p(:,1),p(:,2),t*ones(n,1))) = minV;
        
        for jj = [(t-1):-1:1 (t+1):sizeV(3)]
            if jj == t-1 || jj == t+1
                p2 = p;
            end
            
            P = getPixelIdxList(bwconncomp(fwhm(:,:,jj)));
            
            if isempty(P)
                continue
            end
            
            overlap = cellfun(@(q) sum(ismember(q,p2,'rows')),P);
            
            [maxO,maxI] = max(overlap);
            
            if maxO == 0
                continue
            end
            
            p2 = P{maxI};
            n2 = size(p2,1);
            
            blob(sub2ind(sizeV,p2(:,1),p2(:,2),jj*ones(n2,1))) = 1;
            V(sub2ind(sizeV,p2(:,1),p2(:,2),jj*ones(n2,1))) = minV;
        end
        
        blobs{ii} = blob;
    end
end