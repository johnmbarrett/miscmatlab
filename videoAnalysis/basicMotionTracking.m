function trajectory = basicMotionTracking(I,varargin)
    parser = inputParser;
    parser.addParameter('ROIs',NaN,@(x) isa(x,'imroi'));
    parser.addParameter('UpdateTemplate',false,@(x) isscalar(x) && islogical(x));
    parser.addParameter('VideoOutputFile','trajectory',@(x) (isscalar(x) && isnan(x)) || ischar(x));
    parser.parse(varargin{:});
    
    updateTemplate = parser.Results.UpdateTemplate;
    
    extraDims = ndims(I)-2;
    firstFrameIndex = [{':' ':'} repmat({1},1,extraDims)];
    firstFrame = I(firstFrameIndex{:});
    
    templateROIs = parser.Results.ROIs;
    
    if ~isa(templateROIs,'imroi')
        imshow(firstFrame);
        caxis([0 255]);
        
        templateROIs = chooseMultipleROIs;
    end
    
    nROIs = numel(templateROIs);
    
    templatePos = arrayfun(@(roi) roi.getPosition,templateROIs,'UniformOutput',false);
    templatePos = vertcat(templatePos{:});
    templateX = cell(nROIs,1);
    templateY = cell(nROIs,1);
    
    for ii = 1:nROIs
        templateX{ii} = round(templatePos(ii,1)+(1:templatePos(ii,3))-1);
        templateY{ii} = round(templatePos(ii,2)+(1:templatePos(ii,4))-1);
    end
    
    templates = cellfun(@(x,y) firstFrame(x,y),templateY,templateX,'UniformOutput',false);
    
    sizeI = size(I);
    nFrames = prod(sizeI(3:end));
    
    xcenter = round(cellfun(@mean,templateX));
    ycenter = round(cellfun(@mean,templateY));
    
    searchX = arrayfun(@(x) unique(min(sizeI(2),max(1,x+(-100:100)))),xcenter,'UniformOutput',false);
    searchY = arrayfun(@(y) unique(min(sizeI(1),max(1,y+(-100:100)))),ycenter,'UniformOutput',false);
    
    trajectory = zeros(nFrames,2,nROIs);
    trajectory(1,1,:) = templatePos(:,1)+templatePos(:,3)/2;
    trajectory(1,2,:) = templatePos(:,2)+templatePos(:,4)/2;
    
    outputVideo = ischar(parser.Results.VideoOutputFile);
    
    if outputVideo
        fig = figure;
        set(fig,'Position',[100 100 size(I,2) size(I,1)]);
        ax = gca;
        set(ax,'Position',[0 0 1 1]);
        plotFrameWithTemplateMarker(ax,firstFrame,trajectory(1,1,:),trajectory(1,2,:),templateX,templateY);

        trajectoryVideo = VideoWriter(parser.Results.VideoOutputFile);
        trajectoryVideo.FrameRate = 30; % TODO : pass in frame rate
        open(trajectoryVideo);
        writeVideo(trajectoryVideo,getframe(fig));
    end
    
    for jj = 2:nFrames
%         tic;
        
        nextFrameIndex = cell(1,extraDims);
        [nextFrameIndex{:}] = ind2sub(sizeI(3:end),jj);
        nextFrameIndex = [{':' ':'} nextFrameIndex]; %#ok<AGROW>
        nextFrame = I(nextFrameIndex{:});
        
        s = std(double(nextFrame(:)));
        if s == 0 || isnan(s)
            trajectory(jj,:,:) = NaN;
            
            if outputVideo
                writeVideo(trajectoryVideo,zeros(size(nextFrame)));
            end
            
            continue
        end
        
        if outputVideo
            matchX = cell(size(templateX));
            matchY = cell(size(templateY));
        end
        
        for kk = 1:nROIs
            template = templates{kk};
            
            C = normxcorr2(template,nextFrame(searchY{kk},searchX{kk}));

            [ymax,xmax] = find(C == max(C(:)));
            
            trajectory(jj,:,kk) = [xmax(1)-size(template,2)/2+searchX{kk}(1)-1 ymax(1)-size(template,1)/2+searchY{kk}(1)-1];
            
            if ~outputVideo && ~updateTemplate
                continue
            end
            
            matchX{kk} = xmax-size(template,2)+(1:size(template,2))+searchX{kk}(1)-1;
            matchY{kk} = ymax-size(template,2)+(1:size(template,2))+searchY{kk}(1)-1;
        end
        
        if outputVideo
            plotFrameWithTemplateMarker(ax,nextFrame,trajectory(jj,1,:),trajectory(jj,2,:),matchX,matchY);

            writeVideo(trajectoryVideo,getframe(fig));
        end
        
        if updateTemplate
            templates = cellfun(@(x,y) nextFrame(x,y),matchY,matchX,'UniformOutput',false);
            xcenter = round(cellfun(@mean,matchX));
            ycenter = round(cellfun(@mean,matchY));
            searchX = arrayfun(@(x) unique(min(sizeI(2),max(1,x+(-100:100)))),xcenter,'UniformOutput',false);
            searchY = arrayfun(@(y) unique(min(sizeI(1),max(1,y+(-100:100)))),ycenter,'UniformOutput',false);
        end
        
%         toc;
    end
    
    if outputVideo
        close(trajectoryVideo); % TODO : oncleanup
        close(fig);
    end
end

function plotFrameWithTemplateMarker(ax,frame,x,y,templateX,templateY)
    cla;
    surf(flipud(frame));
    shading interp;
    colormap(gray);
    view(2);
    hold on;
    
    for ii = 1:numel(x)
        plot3(ax,x(ii),size(frame,1)-y(ii)+1,1e3,'Color','none','Marker','o','MarkerEdgeColor','r');
        line(ax,templateX{ii}([1 end; end end; end 1; 1 1]),size(frame,1)-templateY{ii}([1 1; 1 end; end end; end 1])+1,1000*ones(4,2),'Color','g');
    end
        
    xlim([0 size(frame,2)]);
    ylim([0 size(frame,1)]);
    set(ax,'XTick',[],'YTick',[]);
end