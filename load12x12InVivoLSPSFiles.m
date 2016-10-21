files = dir('*.mat');
files = {files.name};
fileIndices = cellfun(@(A) ternaryfun(isempty(A),@() NaN,@() str2double(A{1}{1})),cellfun(@(file) regexp(file,'VT([0-9]+)\.mat','tokens'),files,'UniformOutput',false));
files(fileIndices(~isnan(fileIndices))+1) = files(~isnan(fileIndices));
files = files(1:145);

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