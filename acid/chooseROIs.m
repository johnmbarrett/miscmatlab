function [rois,masks,meanImage] = chooseROIs(stacks,varargin)
    if ~iscell(stacks)
        stacks = {stacks};
    end
    
    meanImage = zeros(size(stacks{1},1),size(stacks{1},2));
    nStacks = numel(stacks);
    
    parser = inputParser;
    parser.addParameter('UseFrames',true(size(stacks{1},3),1),@(x) (islogical(x) && numel(x) == size(stacks{1},3)) || (isnumeric(x) && isreal(x) && all(isfinite(x(:)) & round(x(:)) == x(:) & x(:) > 0 & x(:) <= size(stacks{1},3))));
    parser.addParameter('MeanImageFile',NaN,@(x) ischar(x) || (isscalar(x) && isnumeric(x) && isnan(x)));
    
    isFunctionHandle = @(x) isa(x,'function_handle');
    
    parser.addParameter('ROIFunction',@imfreehand,isFunctionHandle);
    parser.addParameter('MeanFunction',@(a,b) a + double(mean(b,3))/nStacks,isFunctionHandle);
    parser.parse(varargin{:});
    
    useFrames = parser.Results.UseFrames;
    
    for ii = 1:nStacks
        meanImage = parser.Results.MeanFunction(meanImage,stacks{ii}(:,:,useFrames));
    end
    
    meanImageFigure = figure;
    imshow(meanImage);
    hold(gca,'on');
    caxis(prctile(meanImage(:),[1 99]))
    
    roifun = parser.Results.ROIFunction;
    
%     if nargin > 4 && ischar(roisFile) && exist(roisFile,'file') % TODO : fix
%         load(roisFile,'rois');
%     else
        roi = roifun();

        while ~isempty(roi)
            if exist('rois','var')
                rois(end+1) = roi; %#ok<AGROW>
            else
                rois = roi;
            end

            roi = roifun();
        end

        if ~exist('rois','var')
            return
        end
%     end
    
    nROIs = numel(rois);
    colours = distinguishable_colors(nROIs);
    
    for ii = 1:nROIs
        pos = getPosition(rois(ii));
        line(pos(:,1),pos(:,2),'Color',colours(ii,:));
        text(max(pos(:,1)),max(pos(:,2)),sprintf('#%d',ii),'Color',colours(ii,:),'FontSize',16,'HorizontalAlignment','left','VerticalAlignment','bottom');
        set(rois(ii),'Visible','off');
    end
    
    masks = arrayfun(@createMask,rois,'UniformOutput',false);
    
    if ischar(parser.Results.MeanImageFile)
        saveas(meanImageFigure,parser.Results.MeanImageFile,'fig');
    end
end