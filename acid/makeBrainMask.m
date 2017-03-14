function makeBrainMask(brainImageFile,outputFile)
    I = imread(brainImageFile);
    
    I = bin(I,2);
    imagesc(I);
    daspect([1 1 1]);
    
    rois(1) = imfreehand;
    rois(2) = imfreehand;
    
    masks = arrayfun(@(r) createMask(r),rois,'UniformOutput',false);
    
    mask = masks{1} + masks{2};
    
    mask(mask == 0) = NaN; %#ok<NASGU>
    
    if nargin < 2 || ~ischar(outputFile)
        outputFile = uiputfile('*.mat','Save Mask As...','mask.mat');
    end
    
    save(outputFile,'mask');
end