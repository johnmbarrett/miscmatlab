function C = bin(A,b)    
    sizeA = size(A);
    C = zeros([sizeA(1:2)/b sizeA(3:end)]);
    n = b^2;
    
    if ndims(A) <= 2
        nFrames = 1;
    else
        nFrames = prod(sizeA(3:end));
    end
    
    for kk = 1:nFrames
        for ii = 1:b
            for jj = 1:b
                C(:,:,kk) = C(:,:,kk) + double(A(ii:b:end,jj:b:end,kk))/n;
            end
        end
    end
end