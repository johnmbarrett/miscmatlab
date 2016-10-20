function [map,trajectories] = motorTrackingMap(files,varargin)
    parser = inputParser;
    parser.addParameter('ROIs',NaN,@(x) isa(x,'imroi'));
    parser.parse(varargin{:});
    
    rois = parser.Results.ROIs;
    
    if ~isa(rois,'imroi')
        I = loadLXJOrMATFile(files{1});
        
        

        meanFirstImage = double(I{1}(:,:,1));
        nTrials = 1;

        for ii = 1:numel(files)
            tic;
            if ii > 1
                I = loadLXJOrMATFile(files{ii});
            end

            for jj = (1+(ii>1)):numel(I)
                meanFirstImage = meanFirstImage + double(I{jj}(:,:,1));
                nTrials = nTrials + 1;
            end
            toc;
        end

        meanFirstImage = meanFirstImage/nTrials;

        imshow(meanFirstImage);
        
        rois = chooseMultipleROIs;
    end
    
    trajectories = cell(size(files));
    
    for ii = 1:numel(files)
        tic;
        
        I = loadLXJOrMATFile(files{ii});
        
        trajectories{ii} = cell(size(I));
        
        for jj = 1:numel(I)
            trajectories{ii}{jj} = basicMotionTracking(I{jj},'ROIs',rois,'UpdateTemplate',false,'VideoOutputFile',sprintf('%s_trial_%d_motion_tracking.mat',name,jj));
        end
        
        toc;
    end
    
    map = cell2mat(cellfun(@(ts) mean(cell2mat(cellfun(@(t) squeeze(sum(sqrt(sum(diff(t(~any(any(isnan(t),2),3),:,:),1).^2,2)),1)),ts,'UniformOutput',false)),2),trajectories,'UniformOutput',false))';
    
    roiPositions = arrayfun(@(r) r.getPosition,rois,'UniformOutput',false);
    roiPositions = vertcat(roiPositions{:}); %#ok<NASGU>
    
    dirs = strsplit(pwd,{'\' '/'});
    lastDir = dirs{end};
    save([lastDir '_motion_tracking.mat'],'map','trajectories','roiPositions');
end