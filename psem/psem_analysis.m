baseFolder = 'Z:\LACIE\DATA\John\cells\';
summarySpreadsheet = [baseFolder 'psem experiments.xlsx'];

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

        traces{jj,kk} = arrayfun(@(ll) sprintf('%s%s%04d.xsg',experiments{ii},prefix,ll),(firstTrace:lastTrace)','UniformOutput',false);
    end
end
%%
experimentFolder = [baseFolder experiments{ii}];

cd(experimentFolder);
%%
nCells = size(uniqueCells,1);

seenIntrinsic = zeros(nCells,3);
seenIsteps = zeros(nCells,3);

Vm = cell(nCells,3,0);
Rs = cell(nCells,3,0);

rheobases = cell(nCells,3,0);
fiCurves = cell(1,nCells,3,0);

amplitudes = -200:50:400;

for jj = 1:nConditions
    cellIndex = cellIndices(jj);
    conditionIndex = find(strcmpi(conditions{jj},uniqueConditions));

    if ~isempty(traces{jj,1})
        intrinsicIndex = seenIntrinsic(cellIndex,conditionIndex)+1;
        seenIntrinsic(cellIndex,conditionIndex) = intrinsicIndex;

        [rsData,sampleRate] = concatenateEphusTraces(traces{jj,1},[],1);

        rsData = preprocess(rsData,sampleRate,'Start',0,'Window',0.2,'AverageFun',@nanmedian,'FilterLength',7,'PreFilter',false,'PostFilter',true,'PostFilterFun',@nanmedian);

        Rs{cellIndex,conditionIndex,intrinsicIndex} = calculateCellParameters(rsData,-0.005,sampleRate,'ResponseStart',0.2,'ResponseLength',0.1,'SteadyStateStart',0.4,'SteadyStateLength',0.3);

%             figure;
%             plot((1:size(rsData,1))/sampleRate,rsData);
%             title(sprintf('Expt %s cell %d vsteps %s rep %d',sheets{ii},cellIndices(jj),conditions{jj},intrinsicIndex));            
    end

    if ~isempty(traces{jj,3})
        istepIndex = seenIsteps(cellIndex,conditionIndex)+1;
        seenIsteps(cellIndex,conditionIndex) = istepIndex;

        [fiData,sampleRate,~,isEmpty,headers] = concatenateEphusTraces(traces{jj,3},[],1);

        figure;
        plot((1:size(fiData,1))/sampleRate,fiData);
        title(sprintf('Expt %s cell %d Isteps %s rep %d',experiments{ii},cellIndices(jj),conditions{jj},istepIndex)); 

%             stimuli = extractEphusSquarePulseTrainParameters(headers(find(~cellfun(@isempty,{headers.ephusVersion}),1)),1,'program','pulseJacker');
%             amplitudes = vertcat(stimuli.amplitude);

        spikeIndices = findThresholdCrossings(fiData,0,'rising');

        Vm{cellIndex,conditionIndex,istepIndex} = nanmean(nanmedian(fiData(1:(0.2*sampleRate),:),2));

        if all(cellfun(@isempty,spikeIndices))
            rheobase = Inf;
        else
            rheobase = amplitudes(find(cellfun(@numel,spikeIndices) > 0,1)); % TODO : interpolate?
        end

        rheobases{cellIndex,conditionIndex,istepIndex} = rheobase;

        fiCurve = cellfun(@(t) ternaryfun(isempty(t),@() 0,@() ternaryfun(numel(t) == 1,@() NaN,@() t(end)-t(1)/sampleRate)),spikeIndices)';
        fiCurve(isEmpty) = NaN;
        fiCurves{1,cellIndex,conditionIndex,istepIndex} = fiCurve;
    end
end

close all
%%
missingIntrinsic = find(cellfun(@isempty,Rs))';

for jj = missingIntrinsic
    Rs{jj} = NaN;
end

missingIsteps = find(cellfun(@isempty,Vm))';

for jj = missingIsteps
    Vm{jj} = NaN;
    rheobases{jj} = NaN;
    fiCurves{jj} = NaN(13,1);
end

Rs = cell2mat(Rs);
Vm = cell2mat(Vm);
rheobases = cell2mat(rheobases);
fiCurves = cell2mat(fiCurves);
%%

good = ~any(reshape(Rs,nCells,[]) > 40,2);
goodCells = uniqueCells(good);
Vm = Vm(good,:,:);
rheobases = rheobases(good,:,:);
fiCurves = fiCurves(:,good,:,:);

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
nGoodCells = sum(good);

figure;
[rows,cols] = subplots(nGoodCells);

for jj = 1:nGoodCells
    subplot(rows,cols,jj);
    hold on;
    fiCurve = squeeze(nanmedian(fiCurves(:,jj,:,:),4));

    for kk = 1:3
        isGood = ~isnan(fiCurve(:,kk));
        plot(amplitudes(isGood),fiCurve(isGood,kk),'Marker','o');
    end

    title(sprintf('Expt %s cell %d',experiments{ii},goodCells(jj)));
    xlabel('Current Step (pA)');
    ylabel('Firing Rate (Hz)');
end