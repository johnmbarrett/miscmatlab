function [yfit,k,m,r,a,b] = fitSlopingStaircase(x,y,n,useEstimatedSlopes,a)
    if isscalar(n)
        k = linspace(min(x),max(x),n+2);
        k = k(2:end-1)';
        m = ones(floor(n/2),1);
        p = [k;m];
    elseif isvector(n)
        if nargin > 3 && useEstimatedSlopes
            k = n;
            starts = ismember(x,k(1:2:end-1));
            ends = ismember(x,k(2:2:end));
            m = (y(ends)-y(starts))./(x(ends)-x(starts));
            n = [k;m];
        end
        
        assert(ismember(mod(numel(n),3),[0 1]),'There must be one slope for every other knot');
        p = n;
    else
        error('Knots must be a scalar or a vector');
    end
    
    if nargin < 5
        m = m*a;
    end
    
    y0 = median(y(1:max(1,sum(find(x < k(1),1,'last')))));
    y = y-y0;
    
    function r2 = slopingStaircaseR2(params)
        r2 = (y-slopingStaircase(x,params)).^2./(y.^2);
        r2(isinf(r2)) = 1;
        r2(isnan(r2)) = 0;
        r2 = sum(r2);
    end
    
    options = optimset(optimset(@fminsearch),'Display','iter','MaxIter',1e100,'MaxFunEvals',1e5*numel(p));
    
    [p,r] = fminsearch(@slopingStaircaseR2,p,options);
    
    yfit = slopingStaircase(x,p)+y0;
    
    if nargout < 2
        return
    elseif nargout == 2
        k = p;
    else
        q = ceil(2*n/3);
        k = p(1:q);
        m = p((q+1):end-2);
        a = p(end-1);
        b = p(end);
    end
end