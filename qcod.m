function [q,p] = qcod(x,dim)
    if nargin < 1
        [x,nshifts] = shiftdim(x);
        dim = 1;
    end
        
    p = prctile(x,[25 75],dim);
    q = diff(p,[],dim)./sum(p,dim);
    
    if nargin < 1
        q = shiftdim(q,-nshifts);
    end
end
        