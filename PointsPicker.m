classdef PointsPicker < handle
    properties(GetAccess=public,SetAccess=protected)
        CurrentImage = 1
        CurrentPoint
        CurrentPointEditbox = NaN
        CurrentPointSlider = NaN
        Figure
        Filenames
        ImageAxis = NaN
        ImageHandle = NaN
        ImageNumberText = NaN
        ImageSlider = NaN
        IsVideo = false
        NFrames
        PointHandles = gobjects(0,1);
        PointNumberEditbox = NaN
        Points = zeros(0,8); % index, area, min, mean, max, x, y, image
        PointsPerImage
        PointsPerImageEditbox = NaN
    end
    
    methods
        function self = PointsPicker
            [files,path] = uigetfile('*.*','Choose Images...','MultiSelect','on');
            
            if isscalar(files) && files == 0
                return
            elseif ischar(files)
                files = {files};
            end
            
            isVideo = cellfun(@(s) strcmpi(s(end-2:end),'avi'),files);
            
            assert(all(isVideo) || ~any(isVideo),'Input must be a list of images or a list of raw AVIs');
            
            self.IsVideo = all(isVideo);
            
            self.Filenames = cellfun(@(f) [path f],files,'UniformOutput',false);
            
            if self.IsVideo
                self.NFrames = zeros(size(Self.Filenames));
                
                for ii = 1:numel(self.Filenames)
                    fin = fopen(self.Filenames{ii});
                    
                    fclose(fin);
                end
            end
            
            self.Figure = figure;
            
            self.setPointsPerImage(10);
            
            self.setCurrentImage(1);
            
            self.setCurrentPoint(1);
            
            uicontrol(self.Figure,'Style','pushbutton','String','Delete Point','Units','normalized','Position',[0.6 0.1 0.15 0.05],'Callback',@self.deletePoint);
            
            uicontrol(self.Figure,'Style','pushbutton','String','Export Points','Units','normalized','Position',[0.8 0.1 0.15 0.05],'Callback',@self.exportPoints);
        end
        
        function points = setCurrentImagePointsVisibility(self,visible)
            imagePointIndices = (self.CurrentImage-1)*self.PointsPerImage+(1:self.PointsPerImage);
            points = self.PointHandles(imagePointIndices);
            points = points(~arrayfun(@(h) isa(h,'matlab.graphics.GraphicsPlaceholder'),points) & isvalid(points));
            
            if isempty(points)
                return
            end
            
            set(points,'Visible',visible);
        end
        
        function setCurrentImage(self,index)
            nFiles = numel(self.Filenames);
            assert(isscalar(index) && isnumeric(index) && index > 0 && index <= nFiles,'Image number must be between 1 and the number of images.')
            index = round(index); % fix floating point issue with sliderstep
            
            self.setCurrentImagePointsVisibility('off');
            
            self.CurrentImage = index;
            
            if ~isgraphics(self.ImageAxis)
                self.ImageAxis = subplot('Position',[0.05 0.3 0.9 0.65]);
                set(self.ImageAxis,'XTick',[],'YTick',[]);
            end
            
            [~,filename] = fileparts(self.Filenames{index});
            title(self.ImageAxis,filename,'Interpreter','none');
            
            I = imread(self.Filenames{index}); % TODO : caching
            
            if ~isgraphics(self.ImageHandle)
                self.ImageHandle = imagesc(I);
                daspect([1 1 1]);
                colormap(gray);
                hold(self.ImageAxis,'on');
                set(self.ImageHandle,'ButtonDownFcn',@self.handleImageClick);
            else
                set(self.ImageHandle,'CData',I);
            end
            
            self.setCurrentImagePointsVisibility('on');
            
            % TODO : worth promoting to properties?
            isMultiImage = nFiles > 1;
            enable = {'off' 'on'};
            
            if ~isgraphics(self.ImageSlider)
                self.ImageSlider = uicontrol(self.Figure,'Style','slider','Min',1,'Max',nFiles,'Value',index,'SliderStep',isMultiImage*[1 10]./(nFiles-1),'Enable',enable{isMultiImage+1},'Units','normalized','Position',[0.125 0.2 0.825 0.05],'Callback',@(slider,varargin) self.setCurrentImage(get(slider,'Value')));
            else
                set(self.ImageSlider,'Value',index);
            end
            
            s = sprintf('%d/%d',index,nFiles);
            
            if ~isgraphics(self.ImageNumberText)
                self.ImageNumberText = uicontrol(self.Figure,'Style','text','String',s,'Units','normalized','Position',[0.025 0.2 0.1 0.05]);
            else
                set(self.ImageNumberText,'String',s);
            end
        end
        
        function setPointsPerImage(self,nPoints)
            assert(isscalar(nPoints) && isnumeric(nPoints) && isfinite(nPoints) && nPoints > 0 && nPoints == round(nPoints),'Points per image must be an integer greater than zero.')
            
            oldPointsPerImage = self.PointsPerImage;
            self.PointsPerImage = nPoints;
            
            s = sprintf('%d',self.PointsPerImage);
            
            if ~isgraphics(self.PointsPerImageEditbox)
                uicontrol(self.Figure,'Style','text','String','Points per image:','Units','normalized','Position',[0.05 0.1 0.15 0.05]);
                self.PointsPerImageEditbox = uicontrol(self.Figure,'Style','edit','String',s,'Units','normalized','Position',[0.2 0.1 0.1 0.05],'Callback',@(editbox,varargin) self.setPointsPerImage(str2double(get(editbox,'String'))));
            else
                set(self.PointsPerImageEditbox,'String',s);
            end
            
            if isgraphics(self.CurrentPointSlider)
                enable = {'off' 'on'};
                set(self.CurrentPointSlider,'Max',self.PointsPerImage,'SliderStep',[1 min(10,max(1,self.PointsPerImage-1))]./max(1,self.PointsPerImage-1),'Enable',enable{(self.PointsPerImage > 1)+1});
            end
            
            if self.CurrentPoint > self.PointsPerImage
                self.setCurrentPoint(self.PointsPerImage)
            end
            
            nFiles = numel(self.Filenames);
            totalPoints = self.PointsPerImage*nFiles;
            
            if size(self.Points,1) == 0
                self.Points = zeros(totalPoints,8);
                self.PointHandles = gobjects(totalPoints,1);
                return
            end
            
            dPoints = self.PointsPerImage-oldPointsPerImage;
            
            if dPoints < 0
                pointIndicesToDelete = repmat(self.PointsPerImage+(1:(-dPoints))',nFiles,1)+kron(oldPointsPerImage*(0:(nFiles-1))',ones(-dPoints,1));
                self.Points(pointIndicesToDelete,:) = [];
                delete(self.PointHandles(pointIndicesToDelete));
                self.PointHandles(pointIndicesToDelete) = [];
            elseif dPoints > 0
                existingPointIndices = repmat((1:oldPointsPerImage)',nFiles,1)+kron(self.PointsPerImage*(0:(nFiles-1))',ones(oldPointsPerImage,1));
                
                oldPoints = self.Points;
                self.Points = zeros(totalPoints,8);
                self.Points(existingPointIndices,:) = oldPoints;
                
                oldPointHandles = self.PointHandles;
                self.PointHandles = gobjects(totalPoints,1);
                self.PointHandles(existingPointIndices) = oldPointHandles;
            end
        end
        
        function setCurrentPoint(self,index)
            assert(isscalar(index) && isnumeric(index) && isfinite(index) && index > 0 && index <= self.PointsPerImage,'Current point must be an integer greater than zero and no greater than the number of points per image')
            index = round(index);
            
            currentPointIndex = self.getCurrentPointIndex();
            currentPointHandle = self.PointHandles(currentPointIndex);
            
            if ~isa(currentPointHandle,'matlab.graphics.GraphicsPlaceholder') && isvalid(currentPointHandle)
                isOccluded = sum(abs(self.Points(currentPointIndex,2:end-1))) == 0;
                set(currentPointHandle,'Color',[isOccluded 1-isOccluded 0]);
            end
            
            self.CurrentPoint = index;
            
            s = sprintf('%d',self.CurrentPoint);
            
            if ~isgraphics(self.CurrentPointEditbox)
                uicontrol(self.Figure,'Style','text','String','Current point:','Units','normalized','Position',[0.3 0.1 0.15 0.05]);
                self.CurrentPointEditbox = uicontrol(self.Figure,'Style','edit','String',s,'Units','normalized','Position',[0.45 0.1 0.1 0.05],'Callback',@(editbox,varargin) self.setCurrentPoint(str2double(get(editbox,'String'))));
                self.CurrentPointSlider = uicontrol(self.Figure,'Style','slider','Min',1,'Max',self.PointsPerImage,'Value',index,'SliderStep',[1 min(10,max(1,self.PointsPerImage-1))]./max(1,self.PointsPerImage-1),'Units','normalized','Position',[0.55 0.1 0.025 0.05],'Callback',@(slider,varargin) self.setCurrentPoint(get(slider,'Value')));
                % TODO : slider
            else
                set(self.CurrentPointEditbox,'String',s);
                set(self.CurrentPointSlider,'Value',index);
            end
            
            currentPointHandle = self.PointHandles(self.getCurrentPointIndex());
            
            if ~isa(currentPointHandle,'matlab.graphics.GraphicsPlaceholder') && isvalid(currentPointHandle)
                set(currentPointHandle,'Color','b');
            end
        end
        
        function pointIndex = getCurrentPointIndex(self)
            pointIndex = self.PointsPerImage*(self.CurrentImage-1)+self.CurrentPoint;
        end
        
        function handleImageClick(self,~,eventData)
            if ~ismember(eventData.Button,[1 3])
                return
            end
            
            switch eventData.Button
                case 1
                    x = round(eventData.IntersectionPoint(1));
                    y = round(eventData.IntersectionPoint(2));
                    I = get(self.ImageHandle,'CData');
                    v = repmat(mean(I(y,x,:),3),1,3);
                    c = 'g';
                case 3
                    x = 0;
                    y = 0;
                    v = [0 0 0];
                    c = 'r';
                otherwise
                    errordlg('You clicked the button that should not be.');
            end
            
            pointIndex = self.getCurrentPointIndex();
            
            self.Points(pointIndex,:) = [...
                size(self.Points,1) ...
                0                   ...
                v                   ...
                x                   ...
                y                   ...
                self.CurrentImage   ... TODO : multi-image
                ];
            
            if ~isa(self.PointHandles(pointIndex),'matlab.graphics.GraphicsPlaceholder')
                delete(self.PointHandles(pointIndex));
            end
            
            self.PointHandles(pointIndex) = plot(self.ImageAxis,x,y,'Color',c,'LineStyle','none','Marker','+');
                
            if self.CurrentPoint == self.PointsPerImage
                if self.CurrentImage < numel(self.Filenames)
                    self.setCurrentImage(self.CurrentImage+1);
                    self.setCurrentPoint(1);
                end
            else
                self.setCurrentPoint(self.CurrentPoint+1);
            end
        end
        
        function deletePoint(self,varargin)
            pointIndex = self.getCurrentPointIndex();
            self.Points(pointIndex,:) = zeros(1,8);
            delete(self.PointHandles(pointIndex));
            self.PointHandles(pointIndex) = gobjects(1,1);
        end
        
        function exportPoints(self,varargin)
            file = uiputfile('*.*','Save As...','Results.csv');
            
            if ~ischar(file)
                return
            end
            
            set(self.Figure,'Pointer','watch');
            
            header = ' ,Area,Mean,Min,Max,X,Y,Slice';
            
            fout = fopen(file,'w');
            
            fprintf(fout,'%s\n',header);
            
            for ii = 1:size(self.Points,1)
                s = num2str(self.Points(ii,:),'%d,');
                fprintf(fout,'%s\n',s(1:end-1));
            end
            
            fclose(fout);
            
            set(self.Figure,'Pointer','arrow');
        end
    end
end