function program = recon(weeks,sets,offset)
    if nargin < 3
        offset = 9;
    end
    
    if nargin < 2
        sets = 5;
    end

    program = zeros(weeks,sets);
    
    program(:,1) = floor(2*((1:weeks)'+offset)/3);
    
    for ii = 2:sets
        program(:,ii) = floor(((1:weeks)'+offset+10-ii-3*(ii>2))/3);
    end
end