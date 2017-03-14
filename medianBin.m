function B = medianBin(A,rows,cols)
    if nargin < 3
        assert(numel(rows) == 2,'Bin size must be specified as two scalars or a two element vector');
        cols = rows(2);
        rows = rows(1);
    else
        assert(isscalar(rows) & isscalar(cols),'Bin size must be specified as two scalars or a two element vector');
    end
    
    sizeA = size(A);
    sizeB = [ceil(sizeA(1:2)./[rows cols]) sizeA(3:end)];
    
    B = zeros(sizeB);
    colons = repmat({':'},ndims(A)-2);
    
    for ii = 1:sizeB(1)
        for jj = 1:sizeB(2)
            tic;
            subscript = [{rows*(ii-1)+(1:rows) cols*(jj-1)+(1:cols)} colons];
            B(ii,jj,colons{:}) = reshape(median(reshape(A(subscript{:}),[rows*cols sizeA(3:end)]),1),[1 1 sizeA(3:end)]);
            toc;
        end
    end
end