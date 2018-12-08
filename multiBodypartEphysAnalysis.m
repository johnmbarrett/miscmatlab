topDir = 'Z:\LACIE\DATA\John\ephys\sensory stim\';
experimentSpreadsheet = [topDir 'all sensory ephys.xlsx'];
experiments = readtable(experimentSpreadsheet);
[uniqueDates,~,dateIndices] = unique(experiments.Date);
%%
nExperiments = size(experiments,1);

figOrder = {'sdf' 'psth'; 'condition' 'probe'};
extraPlotOptions = {{} {'NoSave' true 'Subplots' 'Probes'}};

for ii = 1:numel(uniqueDates)
    for jj = find(experiments.Date == uniqueDates(ii))'
        experimentFolder = sprintf('%s\\%s\\%s',topDir,datestr(uniqueDates(ii),'yyyymmdd'),experiments.Folder{jj});
        cd(experimentFolder);
        
        if ~exist('.\DataMatrix','dir') || ~exist('.\DataMatrix\Par_PSTH_ave.mat','file')
            error('John you have to test your code.');
            probeTypes = strsplit(experiments.ProbesType,' '); %#ok<UNRCH>
            channelsPerProbe = 32*ones(size(probeTypes));
            probeVersions = cellfun(@(s) find(ismember({'A32' 'A16'},s)),probeTypes);
            processRHDFiles(experimentFolder,sprintf('%s\\%s',experimentFolder,experiments.ParamFile{jj}),channelsPerProbe,probeVersions);
        end
        
        if false && exist('.\DataMatrix\psth.mat','file')
            movefile('.\DataMatrix\psth.mat','.\psth.mat');
        elseif true || ~exist('.\psth.mat','file')
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
        
        continue
        
        if ~exist('.\response_params.mat','file')
            calculateLinearArrayResponseParams(experimentFolder);
        end
    end
end