[files,fileIndices,sortIndices] = loadFilesInNumericOrder('*.mat','VT([0-9]+)\.mat');

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