% TODO : make more flexible and modular

inputFile = 'JB0049AAAA0251.mat';
outputFile = 'JB0049AAAA0251_corrected';

load(inputFile)
fraw = zeros(size(dff0));
for ii = 1:250
tic
fraw(:,:,ii,:) = squeeze(dff0(:,:,ii,:)+1).*f0;
toc
end
bg = mean(fraw(:,:,:,3:3:end),4);
foff = bsxfun(@minus,fraw(:,:,:,1:3:end),mean(bg(:,:,[1:40 48 end]),3));
fon = bsxfun(@minus,fraw(:,:,:,2:3:end),bg);
f0on = mean(fon(:,:,1:40,:),3); f0off = mean(foff(:,:,1:40,:),3);
dff0on = bsxfun(@rdivide,fon,f0on)-1;
dff0off = bsxfun(@rdivide,foff,f0off)-1;
save([outputFile '_corrected.mat'],'f0on','f0off','dff0on','dff0off','bg','-v7.3')
dff0on(isnan(dff0on)) = 0;
dff0off(isnan(dff0off)) = 0;
responses = extractROIResponses(cat(4,dff0off,dff0on),masks,[ones(10,1) kron([0;1],ones(5,1))],{'Dummy' 'LED On'},outputFile);
save([outputFile '_corrected.mat'],'-append','-v7.3','responses')