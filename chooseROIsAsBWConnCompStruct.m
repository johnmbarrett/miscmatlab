function roiStructs = chooseROIsAsBWConnCompStruct(image)
    if isnumeric(image) && ismatrix(image)
        h = imshow(image);
    elseif ishandle(image)
        switch get(image,'Type')
            case {'figure' 'axes'}
                hs = findobj(image,'Type','image');

                if isempty(hs)
                    error('Figure or axes handle must contain at least one image');
                end

                h = hs(1);
            case 'image'
                h = image;
            otherwise
                error('First argument must be a 2D matrix or a handle to an image or to a figure or an axes containing at least one image');
        end
        
        image = get(h,'CData');
    else
        error('First argument must be a 2D matrix or a handle to an image or to a figure or an axes containing at least one image');
    end
    
    a = get(h,'Parent');
    caxis(a,prctile(image(:),[1 99]));
    imageSize = fliplr(size(image));
    
    roi = imfreehand(a);
    
    while ~isempty(roi)
        if exist('rois','var')
            rois(end+1) = roi; %#ok<AGROW>
        else
            rois = roi;
        end 
        
        roi = imfreehand(a);  
    end
    
    if ~exist('rois','var')
        return
    end
    
    roiStructs = struct('Connectivity',8,'ImageSize',{imageSize},'NumObjects',numel(rois),'PixelIdxList',{arrayfun(@(r) find(createMask(r)),rois,'UniformOutput',false)});
end