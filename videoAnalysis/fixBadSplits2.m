function fixBadSplits2(offset)
    if nargin < 1
        offset = 1;
    end
    
    if exist('front_motion_tracking.mat','file')
        resultsFile = 'front_motion_tracking.mat';
    elseif exist('VT0_motion_tracking.mat','file')
        resultsFile = 'VT0_motion_tracking.mat';
    else
        warning('can''t find the results file.');
        return
    end
    
    load(resultsFile,'trajectories');
    
    load('parsed_params.mat','stimOrder');
    
    n = numel(stimOrder);
    m = size(trajectories,2); %#ok<NODEF>
    
    lastFrames = repmat(trajectories{stimOrder(1)+1,1}(1,:,:),offset,1,1);
    
    for jj = 1:m
        for ii = 1:n
            tic;
            nextFrames = trajectories{stimOrder(ii)+1,jj}(end-((offset-1):-1:0),:,:);
            trajectories{stimOrder(ii)+1,jj}(end-((offset-1):-1:0),:,:) = []; %#ok<AGROW>
            trajectories{stimOrder(ii)+1,jj} = [lastFrames;trajectories{stimOrder(ii)+1,jj}((offset+1):end,:,:)]; %#ok<AGROW>
            lastFrames = nextFrames;
            toc;
        end
    end
    
    save(resultsFile,'-append','trajectories');
end