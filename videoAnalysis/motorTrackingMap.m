function [map,trajectories,pathLengths,motionTubes,roiPositions] = motorTrackingMap(files,varargin)
    parser = inputParser;
    parser.addParameter('ROIs',NaN,@(x) isa(x,'imroi') || (iscell(x) && all(cellfun(@(A) isequal(size(A),[1 4]),x))) || (isnumeric(x) && ismatrix(x) && size(x,2) == 4));
    parser.addParameter('UseMeanFirstImage',false,@(x) isscalar(x) && islogical(x));
    parser.parse(varargin{:});
    
    rois = parser.Results.ROIs;
    
%     if isa(files,'MappedTensor')
%         allVideos = files;
%         nFiles = size(allVideos,5);
%         nTrials = size(allVideos,4);
%         
%         if ~isa(rois,'imroi')
%             meanFirstImage = sum(sum(allVideos(:,:,1,:,:),4),5)/(nTrials*nFiles);
%         end
%     else
        I = loadLXJOrMATFile(files{1});

        nTrials = numel(I);
        nFiles = numel(files);
%         imageSize = [size(I{1},1) size(I{1},2)];
%         nFrames = max(cellfun(@(A) size(A,3),I)); % TODO : what if all the trials on the first location have dropped frames?
%         nFiles = numel(files);
% 
%         tic;
%         allVideos = MappedTensor([imageSize nFrames nTrials nFiles],'Class','uint8');
%         toc;
% 
%         tic;
%         allVideos(:) = NaN;
%         toc;

    if isscalar(rois) && isnan(rois)
        if parser.Results.UseMeanFirstImage
            meanFirstImage = zeros(imageSize); % do this for speed in case we need it because it doesn't slow us down much if we do

            for ii = 1:numel(files)
                tic;
                if ii > 1
                    I = loadLXJOrMATFile(files{ii});
                end

    %             for jj = 1:numel(I)
    %                 allVideos(:,:,1:size(I{jj},3),jj,ii) = I{jj};
    %             end
    %             toc;
    % 
    %             tic;
                for jj = 1:numel(I)
                    meanFirstImage = meanFirstImage + double(I{jj}(:,:,1))/(nTrials*nFiles);
                end
                toc;
            end
        else
            meanFirstImage = I{1}(:,:,1);
        end
%     end
    
        figure;
        set(gcf,'Position',[100 100 800 600]);
        
        imagesc(meanFirstImage);
        colormap(gray);
        daspect([1 1 1]);
        
        rois = chooseMultipleROIs(@imfreehand);
        roiPositions = zeros(numel(rois),4);
        templates = cell(size(rois));
        masks = cell(size(rois));
        
        for ii = 1:numel(rois)
            mask = createMask(rois(ii));
            pos = regionprops(mask,'BoundingBox');
            pos = pos.BoundingBox;
            
            roiPositions(ii,:) = pos;
            
            templates{ii} = meanFirstImage( ...
                max(1,round(pos(2))):min(size(meanFirstImage,1),round(pos(2)+pos(4))),  ...
                max(1,round(pos(1))):min(size(meanFirstImage,2),round(pos(1)+pos(3)))   ...
                );
            
            
            masks{ii} = find(~mask( ...
                max(1,round(pos(2))):min(size(meanFirstImage,1),round(pos(2)+pos(4))),  ...
                max(1,round(pos(1))):min(size(meanFirstImage,2),round(pos(1)+pos(3)))   ...
                ));
        end
        
        close(gcf);
        
%         clf;
%         h = surf(meanFirstImage);
%         shading flat;
%         view(2);
%         set(gca,'Color',[1 0 1],'YDir','reverse');
%         set(h,'FaceAlpha','flat','AlphaDataMapping','scaled','AlphaData',meanFirstImage);
%         alim([-Inf 0]);
%         xlim([0 size(meanFirstImage,2)]);
%         ylim([0 size(meanFirstImage,1)]);
%         
%         slider = uicontrol(gcf,'Style','slider','Position',[100 10 500 25],'Min',0,'Max',256,'Value',0,'SliderStep',[1/256 10/256]);
%         set(slider,'Callback',@(varargin) alim([-Inf get(slider,'Value')]));
%         
%         uicontrol(gcf,'Style','pushbutton','Position',[625 10 75 25],'String','Set Threshold','Callback',@(varargin) uiresume(gcf));
%         
%         uiwait(gcf);
%         
%         threshold = get(slider,'Value');
    end
    
    trajectories = cell(nFiles,nTrials);
    motionTubes = cell(nFiles,nTrials);
    
    for ii = 1:nFiles
        I = loadLXJOrMATFile(files{ii});
        
        for jj = 1:nTrials
            tic;
            [trajectories{ii,jj},motionTubes{ii,jj}] = basicMotionTracking(I{jj},'Templates',templates,'UpdateTemplate',false,'VideoOutputFile',NaN,'MotionTubeMasks',masks); %sprintf('%d_trial_%d_motion_tracking',files{ii},jj));
            toc;
        end
    end
    
    pathLengths = cell2mat(cellfun(@(t) sum(sqrt(sum(diff(t(~any(any(isnan(t),2),3),:,:),[],1).^2,2)),1),trajectories,'UniformOutput',false));
    
    map = squeeze(median(pathLengths,2));
    
    if ~exist('roiPositions','var')
        if isa(rois,'imroi')
            roiPositions = arrayfun(@(r) r.getPosition,rois,'UniformOutput',false);
            roiPositions = vertcat(roiPositions{:}); %#ok<NASGU>
        elseif iscell(rois)
            roiPositions = vertcat(rois{:}); %#ok<NASGU>
        else
            roiPositions = rois; %#ok<NASGU>
        end
    end
    
    dirs = strsplit(pwd,{'\' '/'});
    lastDir = dirs{end};
    save([lastDir '_motion_tracking.mat'],'-v7.3','map','trajectories','motionTubes','roiPositions','pathLengths');
end