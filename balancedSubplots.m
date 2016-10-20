function [r,c] = balancedSubplots(n)
    r = floor(sqrt(n));
    c = ceil(n/r);
end