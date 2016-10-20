function [rois,masks,meanImage] = chooseROIs(stacks,ledOnFrames,outputFile)
    meanImage = zeros(sizes(1,[1 2]));
    nStacks = numel(stacks);
    
    if nargin < 2 || ~((islogical(ledOnFrames) && numel(ledOnFrames) == size(stacks{1},3)) || (isnumeric(ledOnFrames) && isreal(ledOnFrames(:)) && all(isfinite(ledOnFrames) & round(ledOnFrames(:)) == ledOnFrames(:) & ledOnFrames(:) > 0 & ledOnFrames(:) <= size(stacks{1},3))))
        ledOnFrames = true(size(stacks{1},3),1);
    end
    
    for ii = 1:nStacks
        meanImage = meanImage + double(mean(stacks{ii}(:,:,ledOnFrames),3))/nStacks;
    end
    
    meanImageFigure = figure;
    imshow(meanImage);
    hold(gca,'on');
    caxis(prctile(meanImage(:),[1 99]))
    
%     if nargin > 4 && ischar(roisFile) && exist(roisFile,'file') % TODO : fix
%         load(roisFile,'rois');
%     else
        roi = imfreehand;

        while ~isempty(roi)
            if exist('rois','var')
                rois(end+1) = roi; %#ok<AGROW>
            else
                rois = roi;
            end

            roi = imfreehand;
        end

        if ~exist('rois','var')
            return
        end
%     end
    
    colours = distinguishable_colors(nCells);
    
    for ii = 1:nCells
        pos = getPosition(rois(ii));
        line(pos(:,1),pos(:,2),'Color',colours(ii,:));
        text(max(pos(:,1)),max(pos(:,2)),sprintf('#%d',ii),'Color',colours(ii,:),'FontSize',16,'HorizontalAlignment','left','VerticalAlignment','bottom');
        set(rois(ii),'Visible','off');
    end
    
    masks = arrayfun(@createMask,rois,'UniformOutput',false);
    
    if nargin < 3 || ~ischar(outputFile)
        return
    end
    
    saveas([outputFile '_meanImage.fig'],meanImageFigure,'fig');
end