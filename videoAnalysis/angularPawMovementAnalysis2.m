topDir = 'Z:\LACIE\DATA\John\Videos\motor mapping';
cd(topDir);
expts = readtable('good transcranial corticospinal experiments.xlsx');

%%

expts = expts(logical(expts.Analysed),:);

%%

figFolder = 'C:\Users\jmb9770\Documents\work\posters\sfn 2017\angular motion analysis\';

for ii = 25 % 1:size(expts,1)
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
    
    theta = zeros(nSites,nTrials);
    eccentricity = zeros(nSites,nTrials);
    assymetry = zeros(nSites,nTrials);
    
    for jj = 1:nSites
        for kk = 1:nTrials
            XY = bsxfun(@times,[1 -1],trajectories{jj,kk}(:,:,2));
            dXY = bsxfun(@minus,XY,XY(1,:));
            d = sqrt(sum(dXY.^2,2));
            [~,maxD] = max(d);
            
            t = atan2(dXY(maxD,2),dXY(maxD,1));
            theta(jj,kk) = t;
            
            XYdash = pagefun(@(XY) ([cos(-t) -sin(-t); sin(-t) cos(-t)]*XY')',XY);
            dXYdash = bsxfun(@minus,XYdash,XYdash(1,:));
            
            eccentricity(jj,kk) = -diff(range(dXYdash))/sum(range(dXYdash));
            
            assymetry(jj,kk) = (max(dXYdash(:,2))+min(dXYdash(:,2)))/(max(dXYdash(:,2))-min(dXYdash(:,2)));
        end
    end
    
    eccentricity(isnan(eccentricity)) = 0;
    assymetry(isnan(assymetry)) = 0;
    
    scaledMap = (map(:,2)-min(map(:,2)))/(max(map(:,2))-min(map(:,2)));
    [r,c] = subplots(nSites);
    
    figure
    imagesc(flipud(reshape(scaledMap,c,r)));
    colormap(gray);
    caxis([0 1]);
    
    figFile = sprintf('%sexpt_%d_scaled_movement',figFolder,ii);
    saveas(gcf,figFile,'fig');
    saveas(gcf,figFile,'png');
    close(gcf);
    
    datas = {rad2deg(theta) eccentricity assymetry};
    nColours = [361 2001 2001];
    cax = {-180:180 -1:0.001:1 -1:0.001:1};
    suffixes = {'angle' 'eccentricity' 'assymetry'};
    
    for jj = 1:3
        figure
        dataM = median(datas{jj},2);
        
        if jj == 1
            cmapfun = @(n) flipud(hsv(n));
        else
            cmapfun = @jet;
        end
        
        cmap = colormap(cmapfun(nColours(jj)));
        dataC = interp1(cax{jj},cmap,dataM);
        dataS = bsxfun(@times,dataC,scaledMap);
        imagesc(flipud(reshape(dataS,c,r,size(dataS,2))));
        caxis(cax{jj}([1 end]));
        colorbar
        
        figFile = sprintf('%sexpt_%d_%s',figFolder,ii,suffixes{jj});
        saveas(gcf,figFile,'fig');
        saveas(gcf,figFile,'png');
        close(gcf);
    end
    
    toc;
end