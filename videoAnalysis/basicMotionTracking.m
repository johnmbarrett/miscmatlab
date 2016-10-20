function trajectory = basicMotionTracking(I,varargin)
    parser = inputParser;
    parser.addParameter('ROIs',NaN,@(x) isa(x,'imroi'));
    parser.addParameter('UpdateTemplate',false,@(x) isscalar(x) && islogical(x));
    parser.addParameter('VideoOutputFile','trajectory',@(x) ischar(x));
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
    
    trajectory = zeros(nFrames,2,nROIs);
    trajectory(1,1,:) = templatePos(:,1)+templatePos(:,3)/2;
    trajectory(1,2,:) = templatePos(:,2)+templatePos(:,4)/2;
    
    fig = figure;
    set(fig,'Position',[100 100 size(I,2) size(I,1)]);
    ax = gca;
    set(ax,'Position',[0 0 1 1]);
    plotFrameWithTemplateMarker(ax,firstFrame,trajectory(1,1,:),trajectory(1,2,:),templateX,templateY);
    
    trajectoryVideo = VideoWriter(parser.Results.VideoOutputFile);
    trajectoryVideo.FrameRate = 30; % TODO : pass in frame rate
    open(trajectoryVideo);
    writeVideo(trajectoryVideo,getframe(fig));
    
    for jj = 2:nFrames
%         tic;
        
        nextFrameIndex = cell(1,extraDims);
        [nextFrameIndex{:}] = ind2sub(sizeI(3:end),jj);
        nextFrameIndex = [{':' ':'} nextFrameIndex]; %#ok<AGROW>
        nextFrame = I(nextFrameIndex{:});
        
        if std(double(nextFrame(:))) == 0
            trajectory(jj,:,:) = NaN;
            writeVideo(trajectoryVideo,zeros(size(nextFrame)));
            continue
        end
        
        matchX = cell(size(templateX));
        matchY = cell(size(templateY));
        
        for kk = 1:nROIs
            template = templates{kk};
            
            C = normxcorr2(template,nextFrame);

            [ymax,xmax] = find(C == max(C(:)));
            
            trajectory(jj,:,kk) = [xmax(1)-size(template,2)/2 ymax(1)-size(template,1)/2];

            matchX{kk} = xmax-size(template,2)+(1:size(template,2));
            matchY{kk} = ymax-size(template,2)+(1:size(template,2));
        end
        
        plotFrameWithTemplateMarker(ax,nextFrame,trajectory(jj,1,:),trajectory(jj,2,:),matchX,matchY);
        
        writeVideo(trajectoryVideo,getframe(fig));
        
        if updateTemplate
            templates = cellfun(@(x,y) nextFrame(x,y),matchY,matchX,'UniformOutput',false);
        end
        
%         toc;
    end
    
    close(trajectoryVideo); % TODO : oncleanup
    close(fig);
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