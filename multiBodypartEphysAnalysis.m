topDir = 'Z:\LACIE\DATA\John\ephys\sensory stim\';
experimentSpreadsheet = [topDir 'all sensory ephys.xlsx'];
experiments = readtable(experimentSpreadsheet);
[uniqueDates,~,dateIndices] = unique(experiments.Date);
%%
nExperiments = size(experiments,1);

figOrder = {'sdf' 'psth'; 'condition' 'probe'};
extraPlotOptions = {{} {'NoSave' true 'Subplots' 'Probes'}};

allPSTHs = cell(1,nExperiments);
allSDFs = cell(1,nExperiments);
stimulusParams = cell(1,nExperiments);

for ii = 1:2 %numel(uniqueDates)
    dateIndices = find(experiments.Date == uniqueDates(ii))';
    
    for jj = dateIndices
        tic;
        experimentFolder = sprintf('%s\\%s\\%s',topDir,datestr(uniqueDates(ii),'yyyymmdd'),experiments.Folder{jj});
        cd(experimentFolder);
        
        if ~exist('.\DataMatrix','dir') || ~exist('.\DataMatrix\Par_PSTH_ave.mat','file')
            error('John you have to test your code.');
            probeTypes = strsplit(experiments.ProbesType,' '); %#ok<UNRCH>
            channelsPerProbe = 32*ones(size(probeTypes));
            probeVersions = cellfun(@(s) find(ismember({'A32' 'A16'},s)),probeTypes);
            processRHDFiles(experimentFolder,sprintf('%s\\%s',experimentFolder,experiments.ParamFile{jj}),channelsPerProbe,probeVersions);
        end
        
        if exist('.\DataMatrix\psth.mat','file')
            movefile('.\DataMatrix\psth.mat','.\psth.mat');
        elseif ~exist('.\psth.mat','file')
            for kk = 1:2
                probeNames = strsplit(experiments.ProbeNames{jj},' ');
                
                includeChannels = experiments.IncludeChannels{jj};
                
                if isempty(includeChannels)
                    includeChannels = {[]};
                else
                    includeChannels = {eval(includeChannels)};
                end
                
                intanPSTHPlots(experimentFolder,'ManualDeartifacting',str2num(experiments.BadBins{jj})+100,'IncludeProbes',includeChannels,'ProbeNames',probeNames,extraPlotOptions{kk}{:}); %#ok<ST2NM>

                for ll = 1:2
                    jbsavefig(gcf,'.\\%s_by_%s',figOrder{1,ll},figOrder{2,kk});
                    close(gcf);
                end
            end
        end
        
        load('.\psth.mat','psths','sdfs','params');
        allPSTHs{jj} = psths;
        allSDFs{jj} = sdfs;
        stimulusParams{jj} = params;
        
        if exist('.\response_params.mat','file')
            responseParam = load('.\response_params.mat');
        else
            responseParam = calculateLinearArrayResponseParams(experimentFolder,'ResponseStartIndex',101,'ResponseEndIndex',200,'TransposeData',true,'ProbeNames',probeNames);
        end
        
        if jj == 1
            responseParams = repmat(responseParam,1,nExperiments);
        else
            responseParams(jj) = responseParam;
        end
        
        toc;
    end
    
    [groups,~,groupIndices] = unique(experiments.Group(dateIndices));
    
    for jj = 1:numel(groups)
        if groups(jj) == 0 
            continue
        end
        
        psthIndices = dateIndices(groupIndices == jj);
        
        folderTitles = cell(1,numel(psthIndices));
        
        for kk = 1:numel(folderTitles)
            if strcmp(experiments.BodyPart{psthIndices(kk)},'Forepaw')
                folderTitles{kk} = experiments.SubBodyPart{psthIndices(kk)};
            else
                folderTitles{kk} = experiments.BodyPart{psthIndices(kk)};
            end
        end
        
        [psths,sdfs,params] = combineIntanPSTHs(allPSTHs(psthIndices),allSDFs(psthIndices),stimulusParams(psthIndices),'AverageDuplicateConditions',true,'FolderTitles',folderTitles);
        
        if size(psths,3) < size(psths,4)
            subfigures = 'Conditions';
        else
            subfigures = 'Folders';
        end
                
        intanPSTHPlots(psths,sdfs,params,'Subplots','Probes','ProbeNames',probeNames,'FolderTitles',unique(folderTitles),'Subfigures',subfigures);
    end
end

error('');

%%

[allStimulusParams,~,stimulusParamIndices] = unique(vertcat(stimulusParams{:}),'rows');
nParamsPerRecording = cellfun(@(A) size(A,1),stimulusParams);
stimulusParamIndices = mat2cell(stimulusParamIndices,nParamsPerRecording,1);

bodyParts = {'Forepaw' 'Hindpaw' 'Whisker' 'None'};
subBodyParts = {'D1' 'D2' 'D3' 'D4' 'D5' 'HT' 'TH'};

bodyPartIndices = cellfun(@(s) find(ismember(bodyParts,s)),experiments.BodyPart)+6;
bodyPartIndices(bodyPartIndices == 7) = cellfun(@(s) find(ismember(subBodyParts,s)),experiments.SubBodyPart(bodyPartIndices == 7));

%%

fields = fieldnames(responseParams(1));

allResponseParams = struct([]);

for ii = 1:numel(fields)
    allResponseParams(1).(fields{ii}) = cell(max(vertcat(stimulusParamIndices{:})),3,max(bodyPartIndices));
    
    for jj = 1:nExperiments
        for kk = 1:nParamsPerRecording(jj)
            for ll = 1:3
                allResponseParams(1).(fields{ii}){stimulusParamIndices{jj}(kk),ll,bodyPartIndices(jj)}(end+1) = responseParams(jj).(fields{ii})(ll,kk); % honestly I should just make the transpose the default option
            end
        end
    end
end

medianResponseParams = allResponseParams;

for ii = 1:numel(fields)
    medianResponseParams.(fields{ii}) = cellfun(@nanmedian,allResponseParams.(fields{ii}));
end

%%

plotLinearArrayResponseParams(medianResponseParams,getConditionNames(allStimulusParams),probeNames,'probe');