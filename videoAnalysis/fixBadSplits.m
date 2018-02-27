function fixBadSplits(offset)
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
    
%     load(resultsFile);
    load(resultsFile,'trajectories');
    
    load('parsed_params.mat','stimOrder');
    
    n = numel(stimOrder);
    
%     load(sprintf('VT%d.mat',stimOrder(1)));
    
%     firstFrames = cellfun(@(V) V(:,:,1:offset),VT,'UniformOutput',false); %#ok<NODEF>
    firstTrajectories = cellfun(@(T) T(1:offset,:,:),trajectories(stimOrder(1)+1,:),'UniformOutput',false); %#ok<NODEF>
%     firstTubes = cellfun(@(MT) cellfun(@(M) M(:,:,1:offset),MT,'UniformOutput',false),motionTubes(stimOrder(1)+1,:),'UniformOutput',false); %#ok<NODEF>
    
    for ii = 1:n
        tic;
%         VT1 = load(sprintf('VT%d.mat',stimOrder(ii)));
%         
%         if ii < n
%             VT2 = load(sprintf('VT%d.mat',stimOrder(ii+1)));
%         end
        
%         m = numel(VT1.VT);
        m = size(trajectories,2);
        
        for jj = 1:m
            VT1.VT{jj}(:,:,1:offset) = [];
            trajectories{stimOrder(ii)+1,jj}(1:offset,:,:) = []; %#ok<AGROW>
            
            for kk = 1:2
                motionTubes{stimOrder(ii)+1,jj}{kk}(:,:,1:offset) = []; %#ok<AGROW>
            end
            
            if ii == n
                if jj == m
                    VT1.VT{jj}(:,:,end+(1:offset)) = nan;
                    trajectories{stimOrder(ii)+1,jj}(end+(1:offset),:,:) = nan; %#ok<AGROW>
            
                    for kk = 1:2
                        motionTubes{stimOrder(ii)+1,jj}{kk}(:,:,end+(1:offset)) = nan; %#ok<AGROW>
                    end
            
                    continue
                end
                
                VT1.VT{jj}(:,:,end+(1:offset)) = firstFrames{jj+1};
                trajectories{stimOrder(ii)+1,jj}(end+(1:offset),:,:) = firstTrajectories{1,jj+1}; %#ok<AGROW>
            
                for kk = 1:2
                    MT1 = motionTubes{stimOrder(ii)+1,jj}{kk};
                    MT2 = firstTubes{1,jj+1}{kk};
                    yidx = 1:min(size(MT1,1),size(MT2,1));
                    xidx = 1:min(size(MT1,2),size(MT2,2));
                    motionTubes{stimOrder(ii)+1,jj}{kk}(yidx,xidx,end+(1:offset)) = firstTubes{1,jj+1}{kk}(yidx,xidx,:); %#ok<AGROW>
                end
            
                continue
            end
                    
            VT1.VT{jj}(:,:,end+(1:offset)) = VT2.VT{jj}(:,:,1:offset);
            trajectories{stimOrder(ii)+1,jj}(end+(1:offset),:,:) = trajectories{stimOrder(ii+1)+1,jj}(1:offset,:,:); %#ok<AGROW>
            
            for kk = 1:2
                % TODO : this is wrong but fuck it
                MT1 = motionTubes{stimOrder(ii)+1,jj}{kk};
                MT2 = motionTubes{stimOrder(ii+1)+1,jj}{kk};
                yidx = 1:min(size(MT1,1),size(MT2,1));
                xidx = 1:min(size(MT1,2),size(MT2,2));
                motionTubes{stimOrder(ii)+1,jj}{kk}(yidx,xidx,end+(1:offset)) = motionTubes{stimOrder(ii+1)+1,jj}{kk}(yidx,xidx,1:offset); %#ok<AGROW>
            end
        end
        
        VT = VT1.VT; %#ok<NASGU>
        
        save(sprintf('VT%d.mat',stimOrder(ii)),'-v7.3','VT');
        toc;
    end
    
    save(resultsFile,'-append','motionTubes','trajectories');
end