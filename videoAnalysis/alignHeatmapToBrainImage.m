function [figs,tf,warpedMaps,refs] = alignHeatmapToBrainImage(map,brainImage,gridParams)
    rows = size(map,1);
    cols = size(map,2);
    
    if isa(gridParams,'affine2d')
        tf = gridParams;
        grid = transformPointsForward(tf,kron((1:rows)',ones(cols,1)),repmat((1:cols)',rows,1)); % TODO : check
    else
        movingPoints = [0 0; 0 rows+1; cols+1 0; cols+1 rows+1];
        fixedPoints = [1 -1 cols+2; 1 rows cols+2; 1 -1 1; 1 rows 1]*gridParams;
        tf = fitgeotrans(movingPoints,fixedPoints,'affine');
        grid = [ones(rows*cols,1) kron((1:rows)',ones(cols,1)) repmat((1:cols)',rows,1)]*gridParams;
    end
    
    [~,currentFolder] = fileparts(pwd);
    save(sprintf('%s_heatmap_alignment_transform.mat',currentFolder),'tf');
    
    if ischar(brainImage)
        brainImage = imread(brainImage);
    end
    
    brainImage = repmat(double(brainImage)/255,1,1,3);
    cmap = jet(256); % TODO : jet3
    cmap(1,:) = 0;
    
    figs = gobjects(size(map,3),1);
    
    warpedMaps = cell(size(map,3),1);
    refs = cell(size(map,3),1);

    for ii = 1:size(map,3)
        paddedMap = [zeros(1,cols+2); zeros(rows,1) map(:,:,ii) zeros(rows,1); zeros(1,cols+2)];
        [warpedMap,ref] = imwarp(paddedMap(:,:,1),imref2d(size(paddedMap(:,:,1))),tf,'nearest');
        warpedMaps{ii} = warpedMap;
        refs{ii} = ref;
        
        registeredMap = zeros(size(brainImage));
        registeredMap( ...
            round(ref.YWorldLimits(1)+1:ref.YWorldLimits(2)),   ...
            round(ref.XWorldLimits(1)+1:ref.XWorldLimits(2)),:) ...
            = interp1(0:255,cmap,255*warpedMap/max(warpedMap(:)));
        
        figs(ii) = figure;
        
        imagesc(brainImage+registeredMap/5); % TODO : transparency
        
        hold on;
        
        plot(grid(:,1),grid(:,2),'LineStyle','none','Marker','.','Color','m'); % TODO : control marker
    end
end