function [yfit,k,m,r] = fitSlopingStaircase(x,y,n)
    if isvector(n)
        assert(ismember(mod(numel(n),3),[0 1]),'There must be one slope for every other knot');
        p = n;
    else
        k = linspace(min(x),max(x),n+2);
        k = k(2:end-1)';
        m = ones(floor(n/2),1);
        p = [k;m];
    end
    
    fun = @(params) (y-slopingStaircase(x,params)).^2/(y.^2);
    
    options = optimset(optimset(@fminsearch),'Display','iter');
    
    [p,r] = fminsearch(fun,p,options);
    
    yfit = slopingStaircase(x,p);
    
    if nargout < 2
        return
    elseif nargout == 2
        k = p;
    else
        q = ceil(2*n/3);
        k = p(1:q);
        m = p((q+1):end);
    end
end