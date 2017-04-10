function makeFWHMBlobsVideo(blobs,outputPrefix)
    if nargin < 2
        [~,outputPrefix] = fileparts(pwd);
    end
    
    fig = figure;
    
    for ii = 1:numel(blobs)
        clf;
        
        writer = VideoWriter(sprintf('%s_fwhm_blob_%d',outputPrefix,ii)); %#ok<TNMLP>
        open(writer); % TODO : frame rate
        
        blob = blobs{ii};
        
        for jj = 1:size(blob,3);
            imagesc(blobs{ii}(:,:,jj));
            daspect([1 1 1]);
            caxis([0 1]);
            writeVideo(writer,getframe(fig));
        end
        
        close(writer);
    end
    
    close(fig);
end