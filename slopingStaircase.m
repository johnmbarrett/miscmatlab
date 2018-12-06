function y = slopingStaircase(x,k,m)
    n = numel(k);

    if nargin == 2
        if ismember(mod(n,3),[0 1])
            p = ceil(2*n/3);
            m = k((p+1):end);
            k = k(1:p);
            
        else
            error('Sloping staircase must have a slope for every other knot');
        end
    end
    
    k = sort(k);
    
    n = numel(k);

    assert(numel(m) == floor(n/2),'Sloping staircase must have a slope for every other knot');
    
    y = zeros(size(x));
    y(x < k(1)) = 0;
    
    lastY = 0;
    
    for ii = 1:n-1
        idx = x >= k(ii) & x < k(ii+1);
        
        if ~any(idx)
            continue % TODO : warning?
        end
        
        if mod(ii,2) == 0
            y(idx) = lastY;
            continue
        end
        
        yi = lastY+m((ii+1)/2)*(x(idx)-k(ii));
        lastY = yi(end);
        
        y(idx) = yi;
    end
    
    idx = x >= k(end);
    
    if mod(ii,2) == 1
        y(idx) = lastY;
    else
        y(idx) = lastY+m(end)*(x(idx)-k(end));
    end
    
    if nargin < 4
        return
    end
end