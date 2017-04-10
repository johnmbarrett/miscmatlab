function fwhmBlobAnalysis(file)
    load([file '.mat']);
    
    if size(dff0,1) > 100 %#ok<NODEF>
        dff0 = bin(dff0,ceil(size(dff0,1)/100)); % TODO : specify binning
    end
    
    % if there's an even number of trials, 1:2:(end-1) is equivalent to
    % 1:2:end.  if odd, 1:2:end-1 drops the last control trial.
    dff02 = cat(5,dff0(:,:,:,1:2:(end-1)),dff0(:,:,:,2:2:end));
    dff03 = zeros(size(dff02));
    
    for ii = 1:size(dff02,3)
        for jj = 1:size(dff02,4)
            for kk = 1:size(dff02,5)
                dff03(:,:,ii,jj,kk) = medfilt2(dff02(:,:,ii,jj,kk));
            end
        end
    end
    
    mdff0 = squeeze(mean(dff03,4));
    
    [maxF,maxI] = max(mdff0(:)); %#ok<ASGLU>
    [y,x,t,c] = ind2sub(size(mdff0),maxI); %#ok<ASGLU>
    
    figure;
    surf(mdff0(:,:,t,c));
    saveas(gcf,[file '_max_intensity'],'fig'); % TODO : better name control
    
    [blobs,xs,ys,ts] = findFWHMBlobs(mdff0(:,:,:,2),5,1/2); %#ok<ASGLU>
    makeFWHMBlobsVideo(blobs,[file '_bleach_corrected']);
    save([file '_fwhm_blobs.mat'],'mdff0','maxF','maxI','y','x','t','c','ys','xs','ts','blobs');
end