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
%     '20180219'  ...
%     '20180220'  ...
%     '20180221'  ...
%     '20180222'  ...
%     '20180223'  ...
%     '20180226'  ...
%     '20180227'  ...
%     '20180228'  ...
%     '20180301'  ...
%     '20180302'  ...
%     '20180305'  ...
%     '20180306'  ...
%     '20180307'  ...
%     '20180308'  ...
    % two wheels
%     '20180312'  ...
%     '20180313'  ...
%     '20180314'  ... this one we switched part way through and i'm too lazy to deal with that
%     '20180315'  ...
%     '20180316'  ...
%     '20180319'  ...
%     '20180320'  ...
%     '20180321'  ...
%     '20180322'  ...
%     '20180323'  ...
    % with lickometer
    '20180424'  ...
    '20180425'  ...
    '20180426'  ...
    '20180427'  ...
    '20180430'  ...
    '20180502'  ...
    '20180503'  ...
    '20180504'  ...
    '20180507'  ...
    };

isTwoWheels = true;
isBigRewards = false(1,1024);

% treatment = {           ...
%     0 1 [] [];          ...
%     0 1 [] [];          ...
%     0 1 [] [];          ...
%     0 1 [] [];          ...
%     0 1 [] [];          ...
%     [0;1] 0 1 0;        ...
%     [1;0] 0 1 0;        ...
%     [0;1] 0 1 0;        ...
%     [1;0] 0 1 0;        ...
%     [0;1] 0 1 0;        ...
%     [] [1;0] 0 [0;1];   ...
%     [] [0;1] 0 [1;0];   ...
%     [] [0;1] [] [];     ...
%     [] [1;0] [] [];     ...
%     };
treatment = repmat({0},100,4);
%%
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

nCages = numel(uniqueCages);

fields = {'successRate' 'maxThreshold' 'learningIndex' 'firstRewardLatency' 'angleBias' 'turnBias' 'crossoverLatency' 'maxTurnDistance' 'totalTurnDistance' 'averageTurnDistance' 'averageTurnSpeed' 'maxTurnSpeed' 'engagement' 'engagedSuccessRate' 'percentEngagedTime' 'percentSuccessfulTrials' 'lickSuccessCorrelation' 'percentWastedLicks' 'medianInterBoutInterval' 'nBouts'};
nFields = numel(fields);

if exist('treatment','var')
    conditions = unique([treatment{:}]);
    nConditions = numel(conditions);
else
    conditions = 1;
    nConditions = 1;
end

dataFiles = cell(nDirs,nCages);
isMultiphase = false(nDirs,nCages);
mice = {};
allPhases = [];
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
        lickInitiatedDataFile = strrep(multiphaseDataFile,'.mat','_2.mat');
        
        if ~exist(dataDir,'dir')
            continue
        end
        
        cd(dataDir)
        
%         multiPhaseWheelPlots(true);
        
%         input('...');
        
        if exist(lickInitiatedDataFile,'file')
            dataFiles{ii,jj} = lickInitiatedDataFile;
            isMultiphase(ii,jj) = true;
            dataField = 'phaseData';
        elseif exist(basicDataFile,'file')
            dataFiles{ii,jj} = basicDataFile;
            isMultiphase(ii,jj) = false;
            dataField = 'sessionData';
        elseif exist(multiphaseDataFile,'file')
            dataFiles{ii,jj} = multiphaseDataFile;
            isMultiphase(ii,jj) = true;
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
        
        load(dataFiles{ii,jj},'uniqueNames','phases');
        
        mice = union(mice,cellfun(@(mouse) sprintf('%s %s',uniqueCages{jj},mouse),uniqueNames,'UniformOutput',false));
        allPhases = union(allPhases,phases);
        toc
    end
end
%%
nMice = numel(mice);
allPhases = allPhases(~isnan(allPhases));
nPhases = numel(allPhases);
allDates = dates(1):dates(end);
datas = cell(numel(allDates),nMice,nPhases,nConditions,nFields);
phaseDatas = cell(numel(allDates),nMice,nPhases,nConditions);

for ii = 1:numel(allDates)
    dirIndex = find(ismember(dirNames,datestr(allDates(ii),'yyyymmdd')));
    
    if isempty(dirIndex)
        continue
    end
    
    for jj = 1:nCages
        tic;
        if isempty(dataFiles{dirIndex,jj})
            continue
        end
        
        data = load(dataFiles{dirIndex,jj});
        
%         phase = arrayfun(@(A) ternaryfun(isempty(A.phase),@() NaN,@() A.phase(1)),data.(dataField));
        
        for kk = 1:size(data.successRate,2)
            mouse = [data.cageNumberString ' ' data.uniqueNames{kk}];
            
            mouseIndex = find(ismember(mice,mouse));
            
            if isempty(mouseIndex)
                error('This shouldn''t happen.');
            end
            
%             theData = data.(dataField);
%             x(:,mouseIndex,ii) = interp1(vertcat(theData(:,kk).timestamps),vertcat(theData(:,kk).angle),t);
            
            for mm = 1:numel(allPhases)
                phaseIndex = ismember(data.phases(:,kk),allPhases(mm));

                if isscalar(treatment{dirIndex,jj})
                    for ll = 1:numel(fields)
                        theData = data.(fields{ll});
                        datas{ii,mouseIndex,mm,ismember(conditions,treatment{dirIndex,jj}),ll} = theData(phaseIndex,kk,:);
                    end
                    
                    phaseData = data.(dataField);
                    phaseDatas{ii,mouseIndex,mm,ismember(conditions,treatment{dirIndex,jj})} = phaseData(phaseIndex,kk);
                else
                    for nn = 1:numel(conditions)
                        for ll = 1:numel(fields)
                            theData = data.(fields{ll});
                            datas{ii,mouseIndex,mm,nn,ll} = theData(phaseIndex & ismember(treatment{dirIndex,jj},conditions(nn)),kk,:);
                        end
                        
                        phaseData = data.(dataField);
                        phaseDatas{ii,mouseIndex,mm,nn} = phaseData(phaseIndex & ismember(treatment{dirIndex,jj},conditions(nn)),kk);
                    end
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

%%

if isTwoWheels
    for ii = find(ismember(allDates,dates(:)'))
        for jj = 1:nMice
            for kk = 1:nPhases
                for ll = 1:nConditions
                    if isBigRewards(ii)
                        singleRewards = cellfun(@(s,t) sum(s(1:end-1) ~= 6 & s(2:end) == 6)/(t(end)-t(1)),{phaseDatas{ii,jj,kk,ll}.state}',{phaseDatas{ii,jj,kk,ll}.timestamps}');
                        doubleRewards = cellfun(@(s,t) sum(~ismember(s(1:end-1),7:8) & ismember(s(2:end),7:8))/(t(end)-t(1)),{phaseDatas{ii,jj,kk,ll}.state}',{phaseDatas{ii,jj,kk,ll}.timestamps}');
                    else
                        singleRewards = cellfun(@(s,t) sum(s(1:end-1) == 1 & ismember(s(2:end),6:7))/(t(end)-t(1)),{phaseDatas{ii,jj,kk,ll}.state}',{phaseDatas{ii,jj,kk,ll}.timestamps}');
                        doubleRewards = cellfun(@(s,t) sum(ismember(s(1:end-1),10:11) & ismember(s(2:end),6:7))/(t(end)-t(1)),{phaseDatas{ii,jj,kk,ll}.state}',{phaseDatas{ii,jj,kk,ll}.timestamps}');
                    end
                    
                    assert(all(datas{ii,jj,kk,ll,1}-(singleRewards+doubleRewards) < 1e-6));
                    datas{ii,jj,kk,ll,nFields+1} = singleRewards;
                    datas{ii,jj,kk,ll,nFields+2} = doubleRewards;
                    datas{ii,jj,kk,ll,nFields+3} = doubleRewards./(singleRewards+doubleRewards);
                end
            end
        end
    end
end


%%


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

ylabels = {'Rewards per Second' 'Max Threshold' 'Learning Index' 'First Reward Latency (s)' 'Angular Bias' 'Turn Bias' 'Crossover Latency (s)' 'Max Turn Distance (°)' 'Total Turn Distance (°)' 'Average Turn Distance (°)' 'Average Turn Speed (°/s)' 'Max Turn Speed (°/s)' 'Percent Time Engaged' 'Rewards per Engaged Second' '% Engaged Time' '% Successful Trials' 'Lick vs Success Correlation (R{^2})' '% Wasted Licks' 'Median Inter-trial Interval (s)' '# Trials' 'Single Wheel Rewards Per Second' 'Double Wheel Rewards Per Second' 'Double Wheel Rewards/All Rewards'};
directionLabels = {'Bi' 'CW' 'CCW'};
lineStyles = {'-' '--'};
markers = 'os';
hs = gobjects(6,1);

for ii = [1:2 15:20] % nFields+(1:3)] %size(datas,5)
    figure
    
    for jj = 1:size(datas,3)
        subplot(1,size(datas,3),jj);
        hold on
        
        for kk = 1:size(datas,4)
            set(gca,'ColorOrderIndex',1);
            plot(allDates,cellfun(@(x) ternaryfun(isempty(x),@() NaN,@() median(x)),datas(:,:,jj,kk,ii)),'LineStyle',lineStyles{kk});
            
            set(gca,'ColorOrderIndex',1);
            
            for ll = 1:size(datas,2)
                individualDates = arrayfun(@(date,data) repmat(date,size(data{1})),allDates',datas(:,ll,jj,kk,ii),'UniformOutput',false);
                individualDates = vertcat(individualDates{:});
                
                individualDatas = vertcat(datas{:,ll,jj,kk,ii});
                
                plot(individualDates,individualDatas,'LineStyle','none','marker',markers(kk));
            end
        end
        
        set(gca,'ColorOrderIndex',1);
        
        hs(1:nMice) = plot(repmat(datetime('now','TimeZone','America/Chicago'),10,4),NaN(10,nMice));
        hs(5) = plot(datetime('now','TimeZone','America/Chicago'),NaN,'Color','k','LineStyle','-','Marker','o');
        hs(6) = plot(datetime('now','TimeZone','America/Chicago'),NaN,'Color','k','LineStyle','--','Marker','s');
        
        legend(hs,[mice; {'Saline'; 'PSEM'}],'Location','Best');
        
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

if false
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
end
%%