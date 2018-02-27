dirNames = {    ...
    % crap
%     '20171120'  ...
%     '20171121'  ...
%     '20171122'  ...
%     '20171124'  ...
%     '20171130'  ...      '20171201'  ... basic wheel plots assumes a single phase per session, but this folder violates this assumption
%     '20171204'  ... this is the last one where I saved the relative angle instead of the absolute angle
%     '20171205'  ...
%     '20171206'  ...
%     '20171207'  ...
%     '20171208'  ...
%     '20171211'  ...
%     '20171214'  ...
%     '20171215'  ...
    % red, white, and blue
%     '20180108'  ...
%     '20180109'  ...
%     '20180110'  ...
%     '20180111'  ...
%     '20180112'  ...
%     '20180115'  ...
%     '20180116'  ...
%     '20180117'  ...
%     '20180118'  ...
%     '20180119'  ...
%     '20180122'  ...
%     '20180123'  ...
%     '20180124'  ...
%     '20180125'  ...
%     '20180126'  ...
    % bill & ted
    '20180219'  ...
    '20180220'  ...
    '20180221'  ...
    '20180222'  ...
    '20180223'  ...
    };

dates = datetime(dirNames,'InputFormat','yyyyMMdd','TimeZone','America/Chicago');

topDir = 'Z:\\LACIE\\DATA\\John\\Videos\\Behaviour';
% topDir = 'C:\\Data\\Videos\\behaviour';
uniqueCages = {};
nDirs = numel(dirNames);

for ii = 1:nDirs
    cd(sprintf('%s\\%s',topDir,dirNames{ii}));
    
    subDirs = dir;
    
    goodDirs = ~strncmpi('.',{subDirs.name},1) & [subDirs.isdir];
    
    uniqueCages = union(uniqueCages,unique({subDirs(goodDirs).name}));
end

mice = cell(0,1);

nCages = numel(uniqueCages);

fields = {'successRate' 'maxThreshold' 'learningIndex' 'firstRewardLatency' 'angleBias' 'turnBias' 'crossoverLatency' 'maxTurnDistance' 'totalTurnDistance' 'averageTurnDistance' 'averageTurnSpeed' 'maxTurnSpeed' 'engagement' 'engagedSuccessRate'};
nFields = numel(fields);
datas = repmat({nan(3,nDirs,0)},1,nFields); % pages = initial, final
phaseDatas = cell(nDirs,nCages);
%%
t = 0:1e-3:(80*60);
x = nan(length(t),6,nDirs);
%%
for ii = 1:nDirs
    for jj = 1:nCages
        tic;
        dataDir = sprintf('%s\\%s\\%s\\',topDir,dirNames{ii},uniqueCages{jj});
        
        basicDataFile = sprintf('%s%s_basic_wheel_data.mat',dataDir,uniqueCages{jj});
        multiphaseDataFile = sprintf('%s%s_multiphase_wheel_data.mat',dataDir,uniqueCages{jj});
        
        if ~exist(dataDir,'dir')
            continue
        end
        
        cd(dataDir)
        toc;
        
%         multiPhaseWheelPlots(true);
        
%         input('...');
        
        if exist(basicDataFile,'file')
            dataFile = basicDataFile;
            isMultiphase = false;
            dataField = 'sessionData';
        elseif exist(multiphaseDataFile,'file')
            dataFile = multiphaseDataFile;
            isMultiphase = true;
            dataField = 'phaseData';
        else
            warning('Can''t find data file for day %s cage %s:-',dirNames{ii},uniqueCages{jj});
            continue
%             try
%                 basicWheelPlots;
%             catch err
%                 logMatlabError(err,sprintf('Error reading day %s cage %d:-',dirNames{ii},uniqueCages(jj)),false);
%                 continue
%             end
%             
%             close all;
        end
        
        tic;
        data = load(dataFile);
        
        phaseDatas{ii,jj} = data.(dataField);
        
        phase = arrayfun(@(A) ternaryfun(isempty(A.phase),@() NaN,@() A.phase(1)),data.(dataField));
        
        for kk = 1:size(data.successRate,2)
            mouse = [data.cageNumberString ' ' data.uniqueNames{kk}];
            
            mouseIndex = find(ismember(mice,mouse));
            
            if isempty(mouseIndex)
                mouseIndex = numel(mice)+1;
                
                for ll = 1:nFields
                    datas{ll}(:,:,mouseIndex) = NaN;
                end
                
                mice{mouseIndex} = mouse;
            end
            
            theData = data.(dataField);
%             x(:,mouseIndex,ii) = interp1(vertcat(theData(:,kk).timestamps),vertcat(theData(:,kk).angle),t);
            
            for ll = 1:numel(fields)
                for mm = 1:3
                    theData = data.(fields{ll});
                    datas{ll}(mm,ii,mouseIndex) = nanmedian(theData(data.phases(:,kk) == mm,kk));
                end
            end
            
%             for ll = setdiff(1:11,5*(1-isMultiphase))
%                 datas{ll}(:,ii,mouseIndex) = num2cell(data.(fields{ll})([1 end],kk));
%             end
%             
%             if isMultiphase
%                 continue
%             end
%         
%             firstUnidirectional = find(phase(:,kk) > 1,1);
%             lastUnidirectional = find(phase(:,kk) > 1,1,'last');
%             
%             if ~isempty(firstUnidirectional) && ~isempty(lastUnidirectional)
%                 datas{5}(:,ii,mouseIndex) = num2cell(data.crossoverLatency(phase([firstUnidirectional lastUnidirectional],kk)));
%             end
        end
        toc;
    end
end

% x = reshape(x,[],6*2);
% x(:,7:9) = [];
% %%
% dt = bin(t(2:end),60000,true);
% dx = bin(abs(diff(x)),60000,true);
% figure
% plot(dt,dx)
% pdx = prctile(dx,[25 50 75],2);
% mdx = pdx(:,2);
% ldx = mdx-pdx(:,1);
% udx = pdx(:,3)-mdx;
% figure
% boundedline(dt,mdx,[ldx udx])

% assert(false);
%%

% for ii = 1:11
%     datas{ii}(cellfun(@isempty,datas{ii})) = {NaN};
%     datas{ii} = cell2mat(datas{ii});
% end

%%

% colours = distinguishable_colors(numel(mice));

ylabels = {'Rewards per Second' 'Max Threshold' 'Learning Index' 'First Reward Latency (s)' 'Angular Bias' 'Turn Bias' 'Crossover Latency (s)' 'Max Turn Distance (°)' 'Total Turn Distance (°)' 'Average Turn Distance (°)' 'Average Turn Speed (°/s)' 'Max Turn Speed (°/s)' 'Percent Time Engaged' 'Rewards per Engaged Second'};
directionLabels = {'Bi' 'CW' 'CCW'};

for ii = 1:2 %numel(datas)
    figure
    hold on
    
    for jj = 1:3
        subplot(1,3,jj);
        plot(dates,squeeze(datas{ii}(jj,:,:)));
        legend(mice,'Location','Best');
        title(directionLabels{jj});
        xlabel('Date');
        
        if jj == 1
            ylabel(['Median ' ylabels{ii}]);
        end
    end
    
%     figure
%     hold on
%     set(gca,'ColorOrder',colours);
%     hs = plot(dates,squeeze(datas{ii}(1,:,:)));
%     plot(dates,squeeze(datas{ii}(2,:,:)),'LineStyle','--');
%     hs(end+1) = plot(NaN,NaN,'Color','k','LineStyle','-'); %#ok<SAGROW>
%     hs(end+1) = plot(NaN,NaN,'Color','k','LineStyle','--'); %#ok<SAGROW>
%     legend(hs,[mice {'First Session' 'Last Session'}],'Location','Best');
%     xlabel('Date');
%     ylabel(ylabels{ii});
    
%     figure
%     set(gca,'ColorOrder',colours);
%     plot(dates,squeeze(diff(datas{ii})));
%     legend(mice,'Location','Best');
%     xlabel('Date');
%     ylabel(['{\Delta} ' ylabels{ii}]);
end

%%

nMicePerCage = cellfun(@(A) size(A,2),phaseDatas(1,:));
cMice = [0 cumsum(nMicePerCage)];
nMice = cMice(end);

ecdfs = cell(nDirs,nMice,2);
rewardCurves = cell(nDirs,nMice,2);

for ii = 1:nDirs
    for jj = 1:nCages
        for kk = 1:nMicePerCage(jj)
            t = phaseDatas{ii,jj}(1,kk).successTimes;
            s = phaseDatas{ii,jj}(1,kk).learningCurve;
            
            firstEnd = phaseDatas{ii,jj}(1,kk).timestamps(find(phaseDatas{ii,jj}(1,kk).state ~= 4,1,'last'));
            
            if size(phaseDatas{ii,jj},1) > 1 && ~isempty(phaseDatas{ii,jj}(end,kk).timestamps)
                t = [t; firstEnd+phaseDatas{ii,jj}(end,kk).successTimes-phaseDatas{ii,jj}(end,kk).timestamps(1)]; %#ok<AGROW> this will introduce a spurious dt but ehhhhhhhhn
                s = [s; s(end)+phaseDatas{ii,jj}(end,kk).learningCurve]; %#ok<AGROW>
                lastEnd = phaseDatas{ii,jj}(end,kk).timestamps(find(phaseDatas{ii,jj}(end,kk).state ~= 4,1,'last'));
            else
                lastEnd = 0;
            end
            
            dt = diff(t);
            
            t(end+1) = lastEnd+firstEnd; %#ok<SAGROW>
            s(end+1) = s(end); %#ok<SAGROW>
            
            rewardCurves{ii,mouseIndex,2} = t;
            rewardCurves{ii,mouseIndex,1} = s;
            
            mouseIndex = cMice(jj)+kk;
            
            if isempty(dt)
                ecdfs{ii,mouseIndex,1} = NaN;
                ecdfs{ii,mouseIndex,2} = NaN;
                continue
            end
            
            [ecdfs{ii,mouseIndex,1},ecdfs{ii,mouseIndex,2}] = ecdf(dt);
        end
    end
end
%%

[rows,cols] = subplots(nMice);
colours = jet(nDirs);
curves = {ecdfs rewardCurves};

%%

for hh = 1:numel(curves)
    figure

    for ii = 1:nMice
        subplot(rows,cols,ii)
        hold on
        for jj = 1:nDirs
            stairs(curves{hh}{jj,ii,2}/(1+59*(hh-1)),curves{hh}{jj,ii,1},'Color',colours(jj,:));
            title(mice{ii});
            
            if hh == 2 && ii == 4
                xlabel('Time (min)');
                ylabel('# Rewards');
            end
        end
    end
end
%%