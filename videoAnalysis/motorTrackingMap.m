function [map,trajectories] = motorTrackingMap(files,varargin)
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
    
        imshow(meanFirstImage);
        
        rois = chooseMultipleROIs;
    end
    
    trajectories = cell(nFiles,nTrials);
    
    for ii = 1:nFiles
        I = loadLXJOrMATFile(files{ii});
        
        for jj = 1:nTrials
            tic;
            trajectories{ii,jj} = basicMotionTracking(I{jj},'ROIs',rois,'UpdateTemplate',false,'VideoOutputFile',NaN); %sprintf('%d_trial_%d_motion_tracking',files{ii},jj));
            toc;
        end
    end
    
    map = squeeze(median(cell2mat(cellfun(@(t) sum(sqrt(sum(diff(t(~any(any(isnan(t),2),3),:,:),[],1).^2,2)),1),trajectories,'UniformOutput',false)),2));
    
    if isa(rois,'imroi')
        roiPositions = arrayfun(@(r) r.getPosition,rois,'UniformOutput',false);
        roiPositions = vertcat(roiPositions{:}); %#ok<NASGU>
    elseif iscell(rois)
        roiPositions = vertcat(rois{:}); %#ok<NASGU>
    else
        roiPositions = rois; %#ok<NASGU>
    end
    
    dirs = strsplit(pwd,{'\' '/'});
    lastDir = dirs{end};
    save([lastDir '_motion_tracking.mat'],'map','trajectories','roiPositions');
end