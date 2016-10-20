%%% Load the image stack of the video, 
%param(Stinulus Number, Image Height, Image Width, Frames Per Capture,
%Trials).

function [imageStack,params] = loadLXJStack(filename) %,varargin)
    if nargin < 1 || ~ischar(filename)
        [filename,filepath,~] = uigetfile('.lxj','Select the data file');
        cd(filepath);
    end
    
    params = getLXJParams(filename);

    arraySize = params(2:end);
    totalBytes = prod(arraySize);
    
%     if nargin < 2
%         pointers = 0;
%         bytesToRead = totalBytes;
%         subArraySizes = {arraySize};
%     else
%         [points,bytesToRead,subArraySizes] = parseSubscript(arraySize,varargin);
%     end

    fileID = fopen(filename);
    tic;
    A = fread(fileID,totalBytes,'uint8');
    toc;
    fclose(fileID);

    imageStack = reshape(A,arraySize);
end

% TODO : finish writing this
% function [pointers,bytesToRead,subArraySizes] = parseSubscript(arraySize,varargin)
%     assert(numel(varargin) <= numel(arraySize));
%     
%     varargin((numel(varargin)+1):numel(arraySize)) = repmat({1},1,numel(arraySize)-numel(varargin));
%     
%     isColon = cellfun(@(A) isequal(A,':'),varargin);
%     assert(all(iscolon | arrayfun(@(A,sz) A{1}(:) > 0 & A{1} <= sz,varargin,sz)));
%     
%     colons = find(isColon);
%     
%     for ii = 1:numel(colons)
%         varargin{colons(ii)} = 1:arraySize(colons(ii));
%     end
%     
%     planes = varargin{3};
%     trials = varargin{4};
%     
%     framesToRead = repmat(planes(:),numel(trials),1)+kron((trials(:)-1)*arraySize(3),ones(numel(planes),1));
%     
%     contiguousFrameIndices = find(diff(framesToRead) == 1)+1;
%     nonContiguousFrameIndices = setdiff(1:numel(framesToRead),contiguousFrameIndices);
%     
%     nonContiguousFrames = framesToRead(nonContigousFrameIndices);
%     
%     pointers = (nonContiguousFrames-1)*prod(arraySize(1:2));
%     
%     bytesToRead = zeros(size(
%     for ii = 1:numel(nonContiguousFrames)-1
%         bytesToRead = sum(framesToRead > nonContiguousFrames
%     end
% end
