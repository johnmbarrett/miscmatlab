baseFolders = {'Z:\LACIE\DATA\John\cells\' 'Z:\LACIE\DATA\Laurie\Patch\'};
summarySpreadsheet = [baseFolders{1} 'psem experiments dedup.xlsx'];

%%

uniqueConditions = {'CTRL' 'PSEM' 'WASH'};
[num,txt,raw] = xlsread(summarySpreadsheet);

experiments = txt(2:end,1);
[uniqueExperiments,~,experimentIndices] = unique(experiments);

cells = num(:,1);
    
[uniqueCells,~,cellIndices] = unique([experimentIndices cells],'rows');

conditions = txt(2:end,3);

timePoints = arrayfun(@(t) datetime(t+datenum(1900,1,0),'ConvertFrom','excel'),num(:,3),'UniformOutput',false);
timePoints = vertcat(timePoints{:});

traceRegex = '(.*?)([0-9]+)-?([0-9]*)?';

nConditions = size(num,1);

traces = cell(nConditions,4);

for jj = 1:nConditions
    for kk = 1:4
        if isempty(txt{jj+1,kk+4})
            continue
        end
        
        if txt{jj+1,1}(1) == 'L'
            traces{jj,kk} = txt{jj+1,kk+4};
            
            if isempty(strfind(traces{jj,kk},'.'))
                traces{jj,kk} = [traces{jj,kk} '.h5'];
            end
            
            continue
        end

        % TODO : WaveSurfer
        tokens = regexp(txt{jj+1,kk+4},traceRegex,'tokens');
        traceParts = tokens{1};

        prefix = traceParts{1};
        firstTrace = str2double(traceParts{2});

        if isempty(traceParts{3})
            lastTrace = firstTrace;
        else
            lastTrace = str2double(traceParts{3});
        end

        traces{jj,kk} = arrayfun(@(ll) sprintf('%s%s%04d.xsg',experiments{jj},prefix,ll),(firstTrace:lastTrace)','UniformOutput',false);
    end
end

%%
nCells = size(uniqueCells,1);

seenIntrinsic = zeros(nCells,3);
seenIsteps = zeros(nCells,3);

allRsData = cell(nCells,3,0);

allFIData = cell(nCells,3,0);
allFISteps = cell(nCells,3,0);
isEmpties = cell(nCells,3,0);
sampleRates = zeros(nCells,1);
%%
amplitudes = -200:50:900;
%%
for jj = 1:nConditions
    experiment = experiments{jj};
    
    baseFolder = baseFolders{(double(experiment(1))-double('J'))/2+1};
    
    cd([baseFolder experiment]);
    
    cellIndex = cellIndices(jj);
    conditionIndex = find(strcmpi(conditions{jj},uniqueConditions));

    if ~isempty(traces{jj,1})
        intrinsicIndex = seenIntrinsic(cellIndex,conditionIndex)+1;
        seenIntrinsic(cellIndex,conditionIndex) = intrinsicIndex;

        [rsData,sampleRate] = concatenateTraces(traces{jj,1},[],1);
        
        if sampleRates(cellIndex) == 0 && sampleRate > 0
            sampleRates(cellIndex) = sampleRate;
        end

        rsData = preprocess(rsData,sampleRate,'Start',0,'Window',0.2,'AverageFun',@nanmedian,'FilterLength',7,'PreFilter',false,'PostFilter',true,'PostFilterFun',@nanmedian);

        allRsData{cellIndex,conditionIndex,intrinsicIndex} = rsData;
    end

    if ~isempty(traces{jj,3})
        istepIndex = seenIsteps(cellIndex,conditionIndex)+1;
        seenIsteps(cellIndex,conditionIndex) = istepIndex;
        
        if strncmpi(experiment,'J',1)
            allFISteps{cellIndex,conditionIndex,istepIndex} = -200:50:400;
            dataFiles = traces{jj,3};
        else
            dataFiles = {ws.loadDataFile(traces{jj,3})};
            % get the stimuli from the dataFile, not the header
            allFISteps{cellIndex,conditionIndex,istepIndex} = extractWavesurferSquarePulseTrainParameters(dataFiles{1},[],1);
        end

        [fiData,sampleRates(cellIndex,conditionIndex,istepIndex),~,isEmpties{cellIndex,conditionIndex,istepIndex},headers] = concatenateTraces(dataFiles,[],1);
        
        if sampleRates(cellIndex) == 0 && sampleRate > 0
            sampleRates(cellIndex) = sampleRate;
        end
        
        allFIData{cellIndex,conditionIndex,istepIndex} = fiData;
    end
end
%%
Rs = cell(size(allRsData));
Ri = cell(size(allRsData));
Racc = cell(size(allRsData));

for ii = 1:numel(allRsData)
    if isempty(allRsData{ii})
        continue
    end
    
    [cellIndex,~,~] = ind2sub(size(allRsData),ii);
    [Rs{ii},Ri{ii},~,~,~,Racc{ii}] = calculateCellParameters(allRsData{ii},-0.005,sampleRates(cellIndex),'ResponseStart',0.2,'ResponseLength',0.1,'SteadyStateStart',0.4,'SteadyStateLength',0.3);
end

missing = cellfun(@isempty,Racc);

Rs(missing) = {NaN};
Rs = cell2mat(Rs);

Ri(missing) = {NaN};
Ri = cell2mat(Ri);

Racc(missing) = {NaN};
Racc = cell2mat(Racc);
%%
Vm = cell(size(allFIData));
rheobases = cell(size(allFIData));
fiCurves = cell(size(allFIData));

for ii = 1:numel(allFIData)
    if isempty(allFIData{ii})
        continue
    end
    
    spikeIndices = findThresholdCrossings(allFIData{ii},0,'rising');

    [cellIndex,~,~] = ind2sub(size(allRsData),ii);
    Vm{ii} = nanmean(nanmedian(allFIData{ii}(1:(0.2*sampleRates(cellIndex)),:),2));

    fiCurve = cellfun(@(t) ternaryfun(isempty(t),@() 0,@() ternaryfun(numel(t) == 1,@() NaN,@() sampleRates(cellIndex)*numel(t)/(t(end)-t(1)))),spikeIndices)';
    
    rheobase = allFISteps{ii}(find(fiCurve > 0,1));
    
    if isempty(rheobase)
        rheobase = Inf;
    end
    
    rheobases{ii} = rheobase;
    
    fiCurve(isEmpties{ii}) = NaN;
    fiCurves{ii} = fiCurve;
end

Vm(cellfun(@isempty,Vm)) = {NaN};
rheobases(cellfun(@isempty,rheobases)) = {NaN};

Vm = cell2mat(Vm);
rheobases = cell2mat(rheobases);

%%
allRs = Rs;
allVm = Vm;
allRheobases = rheobases;
allFICurves = fiCurves;

isRejectionStrict = false;

if isRejectionStrict
    good = ~any(reshape(Rs,nCells,[]) > 40,2); %#ok<UNRCH>
else
    bad = find(Rs > 40);
    Rs(bad) = NaN;
    Vm(bad) = NaN;
    rheobases(bad) = NaN;
    fiCurves(bad) = {[]};
    
    good = ~all(isnan(reshape(Rs,nCells,[])),2);
end

goodCells = uniqueCells(good,:);
Rs = Rs(good,:,:);
Vm = Vm(good,:,:);
rheobases = rheobases(good,:,:);
fiCurves = fiCurves(good,:,:);

%%

relativeRheobase = bsxfun(@rdivide,rheobases,rheobases(:,1,:));
meanRelativeRheobase = nanmean(nanmean(relativeRheobase,3),1);

deltaRheobase = diff(rheobases,[],2);
meanDeltaRheobase = nanmean(nanmean(deltaRheobase,3),1);

gfpPositive = ~ismember(goodCells,[3 3],'rows');
pPSEM = signtest(nanmean(deltaRheobase(gfpPositive,1,:),3));
pWash = signtest(nanmean(deltaRheobase(gfpPositive,2,:),3));

%%

figure;
hold on;
plot(1:3,nanmedian(Vm,3)','Color',[0.7 0.7 0.7],'Marker','o');
plot(1:3,median(nanmedian(Vm,3)),'Color','b','Marker','o');
set(gca,'XTick',1:3,'XTickLabel',uniqueConditions);
xlim([0.5 3.5]);
ylabel('Membrane Potential (mV)');

figure;
hold on;
plot(1:3,nanmedian(rheobases,3)','Color',[0.7 0.7 0.7],'Marker','o');
plot(1:3,median(nanmedian(rheobases,3)),'Color','b','Marker','o');
set(gca,'XTick',1:3,'XTickLabel',uniqueConditions);
xlim([0.5 3.5]);
ylabel('Rheobase (pA)');
%%
goodIndices = find(good);
nGoodCells = numel(goodIndices);

figure;
[rows,cols] = subplots(nGoodCells);

colours = 'brg';

for jj = 1:nGoodCells
    subplot(rows,cols,jj);
    hold on;

    for kk = 1:3
        for ll = 1:size(fiCurves,3)
            fiCurve = fiCurves{jj,kk,ll};
            
            if isempty(fiCurve)
                continue
            end
            
            isFinite = isfinite(fiCurve);
            plot(allFISteps{goodIndices(jj),kk,ll}(isFinite),fiCurve(isFinite),'Color',colours(kk),'Marker','o');
            xlim([-200 900]);
        end
    end
    
    yy = ylim;
    
    for kk = 1:2
        line([-150 50 50 -150; 50 50 -150 -150],([0.1 0.1 0.45 0.45; 0.1 0.45 0.45 0.1]+0.45*(2-kk))*yy(2),'Color','k');
        
        vv = allFIData{goodIndices(jj),kk,1}(:,1:min(13,size(allFIData{goodIndices(jj),kk,1},2)));
        
        if isempty(vv)
            continue
        end
        
        vv = yy(2)*(0.35*(vv-min(vv(:)))/(max(vv(:))-min(vv(:)))+0.1+0.45*(2-kk));
        
        xx = linspace(-150,50,size(vv,1));
        
        plot(xx,vv);
        
        text(-100,yy(2)*(0.5+0.45*(2-kk)),uniqueConditions{kk});
        
        ylim([0 yy(2)]);
    end

    title(sprintf('Expt %s cell %d',uniqueExperiments{goodCells(jj,1)},goodCells(jj,2)));
    xlabel('Current Step (pA)');
    ylabel('Firing Rate (Hz)');
end

%%

allSteps = bigUnion(allFISteps{:});
meanFICurve = nan(numel(allSteps),3,size(allFICurves,1),size(allFICurves,3));

for ii = goodIndices(gfpPositive)'
    for jj = 1:3
        for kk = 1:size(allFICurves,3)
            if isempty(allFICurves{ii,jj,kk})
                continue
            end
            
            indices = ismember(allSteps,allFISteps{ii,jj,kk});
            meanFICurve(indices,jj,ii,kk) = allFICurves{ii,jj,kk};
        end
    end
end

meanFICurve = nanmedian(reshape(meanFICurve,numel(allSteps),3,[]),3);

figure
hold on;

for ii = 1:3
    plot(allSteps(~isnan(meanFICurve(:,ii))),meanFICurve(~isnan(meanFICurve(:,ii)),ii),'Marker','o');
end

%%

cd(baseFolders{1});
saveas(gcf,'all_the_good_fi_curves','fig')

%%

save('psem_analysis.mat','traces','allRsData','allFIData','allFISteps','allSteps','meanFICurve','Rs','Vm','rheobases','fiCurves','allRs','allVm','allRheobases','allFICurves');