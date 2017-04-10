function rois = chooseMultipleROIs(roifun)
    if nargin < 1
        roifun = @imrect;
    end
    
    roi = roifun();
    
    if isempty(roi)
        return
    end
    
    while ~isempty(roi)
        if exist('rois','var')
            rois(end+1) = roi; %#ok<AGROW>
        else
            rois = roi;
        end
        
        roi = roifun();
    end
end