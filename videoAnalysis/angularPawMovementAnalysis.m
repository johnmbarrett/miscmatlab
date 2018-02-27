topDir = 'Z:\LACIE\DATA\John\Videos\motor mapping';
cd(topDir);
expts = readtable('good transcranial corticospinal experiments.xlsx');

%%

expts = expts(logical(expts.Analysed),:);

%%

for ii = 26 1:size(expts,1)
    tic;
    
    cd(sprintf('%s\\%d\\stim %d',topDir,expts.Date(ii),expts.Exp(ii)));
    
    files = {'front\front_motion_tracking.mat' 'front\analysis\front_motion_tracking.mat' 'front\raw\analysis\front_motion_tracking'};
    
    isFound = false;
    
    for jj = 1:numel(files)
        if exist(files{jj},'file')
            isFound = true;
            load(files{jj},'map','trajectories');
            break
        end
    end
    
    if ~isFound
        continue
    end
    
    nSites = size(trajectories,1);
    nTrials = size(trajectories,2);
    
    X = cell2mat(cellfun(@(T) T(:,1,2),reshape(trajectories,1,nSites,nTrials),'UniformOutput',false));
    Y = cell2mat(cellfun(@(T) T(:,2,2),reshape(trajectories,1,nSites,nTrials),'UniformOutput',false));
    
    dX = diff(X);
    dY = diff(Y);
    
    theta = atan2(dY,dX);
    
    break;
    
    [~,best] = max(map(:,2));
    
%     figure
%     subplot(2,1,1);
%     plot(reshape(dX,size(dX,1),[],1));
%     subplot(2,1,2);
%     plot(reshape(dY,size(dY,1),[],1));
%     figure
%     subplot(2,1,1);
%     plot(reshape(median(dX(:,best,:),3),[],1));
%     subplot(2,1,2);
%     plot(reshape(median(dY(:,best,:),3),[],1));
    
%     figure
%     set(gcf,'Position',[1 41 1600 784]);
    [r,c] = subplots(size(map,1));
%     
%     yy = [min(reshape(median(dY(:,best,:),3),[],1)) max(reshape(median(dY(:,best,:),3),[],1))];
    theta = zeros(size(dX,2),size(dX,3));
    
    for jj = 1:size(map,1)
%         subplot(r,c,jj);
%         hold on
%         plot(median(dX(:,jj,:),3));
%         plot(median(dY(:,jj,:),3));
%         line([onset onset],yy,'Color','k','LineStyle','--');
%         ylim(yy);
        onset = find(median(abs(dY(2:end,jj,:)),3) > 1,1)+1;
        
        if isempty(onset)
            continue
        end
        
        theta(jj,:) = atan2(dY(onset,jj,:),dX(onset,jj,:));
    end
    
    thetaM = median(theta,2);
    
    cmap = hsv(361);
    
    thetaC = interp1(-180:180,cmap,rad2deg(thetaM));
    
    combo = bsxfun(@times,thetaC,(map(:,2)-min(map(:,2)))/(max(map(:,2))-min(map(:,2))));
    
    maps = {map(:,2) thetaM combo};
    
    suffixes = {'total' 'angle' 'combo'};
    
    for jj = 1:3
        figure
        imagesc(flipud(reshape(maps{jj},c,r,size(maps{jj},2))));
        
        if jj == 1
            colormap(gray)
        elseif jj == 2
            colormap(hsv);
        end
        
        figFile = sprintf('C:\\Users\\jmb9770\\Documents\\work\\posters\\sfn 2017\\angular motion analysis\\expt_%d_%s_movement',ii,suffixes{jj});
        saveas(gcf,figFile,'fig');
        saveas(gcf,figFile,'png');
        close(gcf);
    end
    
    toc;
end