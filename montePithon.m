function p = montePithon(n,outputFile)
    if nargin < 1
        n = 1;
    end
    
    x = 2*rand(n,1)-1;
    y = 2*rand(n,1)-1;
    p = 4*sum(x.^2+y.^2<=1)/n;
    
    if nargin < 2
        outputFile = 'pi.mat';
    end
    
    save(outputFile,'p');
end