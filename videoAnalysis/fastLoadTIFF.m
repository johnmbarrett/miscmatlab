function I = fastLoadTIFF(tiffFile)
    info = imfinfo(tiffFile);
    
    nFrames = numel(info);
    
    I = zeros(info(1).Height,info(1).Width,nFrames); % TODO : multi-channel TIFF
    
    for ii = 1:nFrames
        I(:,:,ii) = imread(tiffFile,'Index',ii,'Info',info);
    end
end