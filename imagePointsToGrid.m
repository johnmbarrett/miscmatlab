function [gridSquares,groups] = imagePointsToGrid(x,y,gridSize,imageSize)
% Usage: x and y are column vectors with the X and Y coordinates of each
% point of interest. Alternatively, x may be a two-column matrix of
% coordinates and y may be omitted. gridSize is a scalar M for an MxM grid
% or a two-element vector [M N] for an M-column, N-row grid (opposite to
% Matlab conventions but in line with normal graphical conventions).
% imageSize is a two-element vector giving the size of the image.
%
% Outputs: gridSquares is a column vector giving the index of which grid
% square the corresponding coordinate is in. Groups gives a cell array of
% vectors where the Nth vector gives the indices of the coordinates in the
% Nth grid square.

    if nargin == 3
        assert(size(x,2) == 2,'X and Y must be two column vectors or X can be a two-column vector');
        imageSize = gridSize;
        gridSize = y;
        y = x(:,2);
        x = x(:,1);
    end
    
    assert(isnumeric(imageSize) && isequal(size(imageSize),[1 2]),'imageSize must be a two-element row vector');

    if isscalar(gridSize)
        gridSize = [gridSize gridSize]; % if e.g. gridSize == 3 convert that to [3 3]
    elseif ~isequal(size(gridSize),[1 2]) || ~isnumeric(gridSize)
        error('Grid size must be a scalar or two-element row vector.');
    end
    
    % force x and y to be column vectors
    x = x(:);
    y = y(:);
    
    % convert from image coordinates to grid co-ordinates, e.g. if
    % imageSize is [800 600] and grid size [4 3] this divides [x y] by 200
    x = gridSize(1)*x/imageSize(1);
    y = gridSize(2)*y/imageSize(2);
    
    % ceil(a) gives the next integer larger than or equal to A (e.g. 0.5 
    % goes to 1, 1 stays as 1, 1.2 goes to 2, etc.; so rather than exactly 
    % where in the grid cell each point (x,y) is, this just tells us which 
    % cell it's in
    x = ceil(x);
    y = ceil(y);
    
    % the following is equivalent to [~,~,gridSquares] = unique([x y],'rows')
    % if and only if every grid square is occupied
    gridSquares = zeros(size(x));
    groups = cell(1,prod(gridSize));
    
    for ii = 1:gridSize(1)
        for jj = 1:gridSize(2)
            s = gridSize(2)*(ii-1)+jj; % row major order, so 1 is top left, 2 is below top left, gridSize(1)+1 is right of top left, and gridSize(1)*gridSize(2) is bottom right
            
            % find the rows where x equals ii and y equals jj, then assign
            % those rows in gridSquares the value s
            gridSquares(x == ii & y == jj) = s;
            
            % or find the indexes of those rows and put them in a cell
            % array
            groups{s} = find(x == ii & y == jj);
        end
    end
end