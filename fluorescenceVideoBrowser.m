function fig = fluorescenceVideoBrowser(V,mddff0,baselineFrames,frameRate,fovMoves,mddff0Thresholded,smddff0,hulls,masks,centroidBinary,centroidWeighted,maxX,maxY)
    sizeMDDFF0 = size(mddff0);

    if ndims(mddff0) > 4
        mddff0 = reshape(mddff0,[sizeMDDFF0(1:3) prod(sizeMDDFF0(4:end))]);
    end
    
    if nargin < 7 || isempty(smddff0) || any(~isfinite(smddff0(:)))
        smddff0 = squeeze(sum(sum(mddff0)));
    end
    
    framesPerTrial = size(mddff0,3);
    nStimuli = size(mddff0,4);
    
    if nargin < 8
        hulls = cell(framesPerTrial,nStimuli);
    end
    
    if nargin < 9
        centroidBinary = nan(framesPerTrial,2,nStimuli);
    end
    
    if nargin < 10
        centroidWeighted = nan(framesPerTrial,2,nStimuli);
    end
    
    if nargin < 12
        maxX = nan(framesPerTrial,nStimuli);
        maxY = nan(framesPerTrial,nStimuli);
    end
    
    fig = figure;
    set(fig,'Position',[100 100 400 600]);
    
    subplot('Position',[0.15 0.55 0.8 0.45]);
    
    function updateImage(varargin)
        if get(findobj(fig,'Tag','thresholdcheckbox'),'Value')
            J = mddff0Thresholded(:,:,frameIndex,stimulusIndex);
        else
            J = mddff0(:,:,frameIndex,stimulusIndex);
        end
        
        set(img,'CData',J);
        
        hull = hulls{frameIndex,stimulusIndex};
        
        if ~isempty(hull)
            set(hullPlot,'XData',hull(:,1),'YData',hull(:,2));
        end
        
        set(maxPoint,'XData',maxX(frameIndex,stimulusIndex),'YData',maxY(frameIndex,stimulusIndex));
        set(cbPoint,'XData',centroidBinary(frameIndex,1,stimulusIndex),'YData',centroidBinary(frameIndex,2,stimulusIndex));
        set(cwPoint,'XData',centroidWeighted(frameIndex,1,stimulusIndex),'YData',centroidWeighted(frameIndex,2,stimulusIndex));
    end
    
    if nargin < 6 || isempty(mddff0Thresholded) || any(~isfinite(mddff0Thresholded(:)))
        isThresholdCheckboxEnabled = 'off';
    else
        isThresholdCheckboxEnabled = 'on';
    end
        
    uicontrol(fig,'Style','checkbox','Tag','thresholdcheckbox','String','Half-max threshold (within frame)','Enable',isThresholdCheckboxEnabled,'Units','normalized','Position',[0.15 0.525 0.8 0.025],'Callback',@updateImage);
    
    frameIndex = baselineFrames(1);
    stimulusIndex = nStimuli;
    img = imagesc(mddff0(:,:,frameIndex,stimulusIndex));
    hold on;
    hullPlot = plot(NaN,NaN,'r');
    maxPoint = plot(NaN,NaN,'m*');
    cbPoint = plot(NaN,NaN,'g+');
    cwPoint = plot(NaN,NaN,'gx');
    caxis([min(mddff0(:)) max(mddff0(:))]);
    daspect([1 1 1]);
    set(gca,'XTick',[],'YTick',[]);
    updateImage();
    
    ax = subplot('Position',[0.15 0.275 0.8 0.25]);
    
    hold on;
    
    t = ((1:framesPerTrial)-baselineFrames(2))/frameRate;
    
    h = plot(t,100*smddff0/numel(V(:,:,1)));
    
    marker = plot(t(frameIndex),100*smddff0(frameIndex)/numel(V(:,:,1)),'LineStyle','none','Marker','o');
    
    xlim(t([baselineFrames(1) framesPerTrial]));
    
    yy = 100*[min(smddff0(:)) max(smddff0(:))]/numel(V(:,:,1));
    ylim(yy);
    
    line([0 0],yy,'Color','k','LineStyle','--');
    
%     legend({'Data' 'Current Frame' 'Stimulus'});
    
    xlabel('Time from stimulus onset (s)');
    ylabel('{\Delta}F/F{_0}');
    
    function updateLabelAndSlider(tagPrefix,value)
        set(findobj(fig,'Tag',[tagPrefix 'slider']),'Value',value);
        set(findobj(fig,'Tag',[tagPrefix 'label']),'String',sprintf('%s%s %d',upper(tagPrefix(1)),lower(tagPrefix(2:end)),value));
    end

    function update(dimension,value)
        index = round(value);
        
        switch dimension
            case 1
                frameIndex = index;
                tagPrefix = 'frame';
            case 2
                stimulusIndex = index;
                tagPrefix = 'stim';
            otherwise
                errordlg('This should never happen.');
        end
        
        updateLabelAndSlider(tagPrefix,index);
        updateImage();
        set(marker,'XData',t(frameIndex),'YData',100*smddff0(frameIndex,stimulusIndex)/numel(V(:,:,1)));
    end

    set(ax,'ButtonDownFcn',@(~,event) update(1,event.IntersectionPoint(1)));
    set(h,'ButtonDownFcn',@(~,event) update(1,event.IntersectionPoint(1)));
    
    uicontrol(fig,'Style','text','String','Frame 1','Tag','framelabel','Units','normalized','Position',[0.0125 0.175 0.125 0.025]);
    uicontrol(fig,'Style','slider','Tag','frameslider','Min',1,'Max',framesPerTrial,'SliderStep',[1 10]./(framesPerTrial-1),'Value',frameIndex,'Units','normalized','Position',[0.15 0.175 0.8 0.025],'Callback',@(slider,varargin) update(1,get(slider,'Value'))); 
    
    function updateCAxis(varargin)
        minSlider = findobj(fig,'Tag','cminslider');
        maxSlider = findobj(fig,'Tag','cmaxslider');
        
        cmin = round(get(minSlider,'Value'));
        cmax = round(get(maxSlider,'Value'));
        
        caxis(get(img,'Parent'),[cmin cmax]/1000);
        
        set(minSlider,'Value',cmin,'Max',cmax-1,'SliderStep',[1 1]./(cmax-1-fmin));
        set(maxSlider,'Value',cmax,'Min',cmin+1,'SliderStep',[1 1]./(fmax-cmin-1));
        
        set(findobj(fig,'Tag','cminslider'),'String',sprintf('CMin %d',cmin/1000));
        set(findobj(fig,'Tag','cmaxslider'),'String',sprintf('CMax %d',cmax/1000));
    end

    fmin = round(1000*min(mddff0(:)));
    fmax = round(1000*max(mddff0(:)));
    
    if nStimuli > 1
        uicontrol(fig,'Style','text','String',sprintf('Stim %d',stimulusIndex),'Tag','stimlabel','Units','normalized','Position',[0.0125 0.15 0.125 0.025]);
        uicontrol(fig,'Style','slider','Tag','stimslider','Min',1,'Max',nStimuli,'SliderStep',[1 1]./(nStimuli-1),'Value',stimulusIndex,'Units','normalized','Position',[0.15 0.15 0.8 0.025],'Callback',@(slider,varargin) update(2,get(slider,'Value'))); 
    end
    
    uicontrol(fig,'Style','text','String',sprintf('CMin %d',fmin/1000),'Tag','cminlabel','Units','normalized','Position',[0.0125 0.125 0.125 0.025]);
    uicontrol(fig,'Style','slider','Tag','cminslider','Min',fmin,'Max',fmax-1,'SliderStep',[1 1]./(fmax-1-fmin),'Value',fmin,'Units','normalized','Position',[0.15 0.125 0.8 0.025],'Callback',@updateCAxis); 
    uicontrol(fig,'Style','text','String',sprintf('CMax %d',fmax/1000),'Tag','cmaxlabel','Units','normalized','Position',[0.0125 0.1 0.125 0.025]);
    uicontrol(fig,'Style','slider','Tag','cmaxslider','Min',fmin+1,'Max',fmax,'SliderStep',[1 1]./(fmax-fmin-1),'Value',fmax,'Units','normalized','Position',[0.15 0.1 0.8 0.025],'Callback',@updateCAxis);
    
    roiPosition = [NaN NaN NaN NaN];
    
    function chooseROI(varargin)
        roi = imrect(get(img,'Parent'));
        
        if isempty(roi)
            return
        end
        
        roiPosition = getPosition(roi);
        delete(roi);
    end
    
    uicontrol(fig,'Style','pushbutton','String','Choose ROI','Tag','chooseroibutton','Units','normalized','Position',[0.05 0.025 0.2 0.025],'Callback',@chooseROI);
    
    function highlightROI(varargin)
        isUserSpecifiedROI = ~isnan(roiPosition(1));
        
        pxpmm = 2.020758017492712e+02/16;
        
        figure;
        set(gcf,'Position',[1000 118 560*numel(fovMoves) 840]); %1120 840]);
        
        cols = numel(fovMoves);
        
        yyrois = [Inf -Inf];
        
        for hh = 1:numel(fovMoves)
            if hh == numel(fovMoves)
                stimulusIndices = fovMoves(hh):nStimuli;
            else
                stimulusIndices = fovMoves(hh):(fovMoves(hh+1)-1);
            end
            
            subplot(2,cols,hh);
            imagesc(V(:,:,hh));
            colormap(gray);
            daspect([1 1 1]);
            hold on;

            if isUserSpecifiedROI
                fill(roiPosition(1)+[0 0 roiPosition(3) roiPosition(3)],roiPosition(2)+[0 roiPosition(4) roiPosition(4) 0],[0 0 0],'EdgeColor','g','FaceColor','none');
            else
                set(gca,'ColorOrderIndex',stimulusIndices(1));
                for ii = stimulusIndices
                    if isempty(hulls{frameIndex,ii})
                        plot(NaN,NaN); % plot ignores empty arrays, so plots NaNs instead to keep the ColorOrder consistent and create a fake handle in the plot browser
                    else
                        plot(hulls{frameIndex,ii}(:,1),hulls{frameIndex,ii}(:,2));
                    end
                end
            end

            scaleBar = fill([0 1 1 0]*pxpmm+2,[47 47 46 46],[1 1 1],'EdgeColor','none');
            scaleText = text(2+pxpmm/2,46,'1 mm','Color',[1 1 1],'FontSize',8,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','bottom');
            horizontalArrow = annotation('arrow',[0.01 0.11],[0.06 0.06],'Color',[1 1 1],'LineWidth',2);
            verticalArrow = annotation('arrow',[0.06 0.06],[0.01 0.11],'Color',[1 1 1],'LineWidth',2);

            subplot(2,cols,numel(fovMoves)+hh);

            if isUserSpecifiedROI
                roiX = max(1,min(64,round(roiPosition(1)+(0:roiPosition(3)-1))));
                roiY = max(1,min(48,round(roiPosition(2)+(0:roiPosition(4)-1))));
                mask = ones(size(V(:,:,1)));
                N = numel(roiX)*numel(roiY);
            else
                roiX = 1:size(V,2);
                roiY = 1:size(V,1);
                mask = cat(4,masks{frameIndex,stimulusIndices});
                N = sum(sum(mask));
            end

            hs = gobjects(numel(stimulusIndices)+4,1);
            smddff0roi = squeeze(bsxfun(@rdivide,sum(sum(bsxfun(@times,mddff0(roiY,roiX,baselineFrames(1):end,stimulusIndices),mask))),N));
            hold on
            set(gca,'ColorOrderIndex',stimulusIndices(1));
            hs(1:numel(stimulusIndices)) = plot(t(baselineFrames(1):end),100*smddff0roi);
            set(gca,'ColorOrderIndex',stimulusIndices(1));
            plot(t(baselineFrames(1):end),100*smddff0(baselineFrames(1):end,stimulusIndices)/numel(V(:,:,1)),'LineStyle',':');
            plot(t(frameIndex),100*smddff0roi(frameIndex-baselineFrames(1)+1),'Color','k','LineStyle','none','Marker','o');
            hs(end-3) = plot(NaN,NaN,'Color','k');
            hs(end-2) = plot(NaN,NaN,'Color','k','LineStyle',':');
            yyroi = ylim;
            hs(end-1) = line([0 0],[-100 100],'Color','k','LineStyle','--');
            hs(end) = line([1 1]*t(frameIndex),[-100 100],'Color','k','LineStyle','-.');
            legend(hs,[arrayfun(@(ii) sprintf('Stim %d',ii),stimulusIndices,'UniformOutput',false) {'ROI' 'Whole Image' 'Stim Onset' 'Response Time'}],'Location','NorthWest');
            xlabel('Time from stimulus onset (s)');
            xlim(t([baselineFrames(1) framesPerTrial]));
            ylabel('{\Delta}F/F{_0} (%)');
            yyrois(1) = min(yyrois(1),yyroi(1));
            yyrois(2) = max(yyrois(2),yyroi(2));

    %         a1 = subplot(2,2,2);
    %         imagesc(mddff0(:,:,frameIndex,stimulusIndex));
    %         daspect([1 1 1]);
    % %         colormap(jet);
    %         cc1 = caxis(a1);
    %         copyobj(outline,a1);
    %         copyobj(scaleBar,a1);
    %         copyobj(scaleText,a1);
    %         
    %         a2 = subplot(2,2,4);
    %         imagesc(mddff0(:,:,frameIndex,1));
    %         daspect([1 1 1]);
    % %         colormap(jet);
    %         cc2 = caxis(a2);
    %         copyobj(outline,a2);
    %         copyobj(scaleBar,a2);
    %         copyobj(scaleText,a2);
    %         
    %         cc = [min(cc1(1),cc2(1)) max(cc1(2),cc2(2))];
    %         caxis(a1,cc);
    %         caxis(a2,cc);
        end
        
        for hh = 1:numel(fovMoves)
            ylim(subplot(2,cols,numel(fovMoves)+hh),yyrois);
        end
    end

    uicontrol(fig,'Style','pushbutton','String','Highlight ROI On First Frame','Tag','highlightroibutton','Units','normalized','Position',[0.3 0.025 0.5 0.025],'Callback',@highlightROI);
end