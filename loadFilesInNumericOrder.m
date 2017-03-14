function [files,fileIndices,sortIndices] = loadFilesInNumericOrder(dirString,indexRegex)
    files = dir(dirString);
    files = {files.name};
    
    fileIndices = cellfun(@(A) ternaryfun(isempty(A),@() NaN,@() str2double(A{1}{1})),cellfun(@(file) regexp(file,indexRegex,'tokens'),files,'UniformOutput',false));
    files(isnan(fileIndices)) = [];
    fileIndices(isnan(fileIndices)) = [];
    
    [fileIndices,sortIndices] = sort(fileIndices);
    files = files(sortIndices);
end

% mapping from index to location:-
%
%                    left
%
%           +-+-+-+-+-+-+-+-+-+-+-+-+
%        0  | | | | | | | | | | | | |  11
%           +-+-+-+-+-+-+-+-+-+-+-+-+
%        12 | | | | | | | | | | | | |  24
%           +-+-+-+-+-+-+-+-+-+-+-+-+
%         .  . . . . . . . . . . . .  .
% caudal  .  . . . . . . . . . . . .  .   rostral
%         .  . . . . . . . . . . . .  .
%           +-+-+-+-+-+-+-+-+-+-+-+-+
%       133 | | | | | | | | | | | | | 144
%           +-+-+-+-+-+-+-+-+-+-+-+-+
%
%                    right
%   
% 145 = thalamus
%
% hence to plot at 145 vector A as a motor map with left & right in the
% correct locations and rostral at the top is:
% 
% imagesc(flipud(reshape(A(1:144),[12 12])))