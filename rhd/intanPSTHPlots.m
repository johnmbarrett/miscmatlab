function [psths,sdfs] = intanPSTHPlots(folders,varargin)
    if ischar(folders)
        folders = {folders};
    end

    parser = inputParser;
    addParameter(parser,'AverageDuplicateConditions',false,@(x) islogical(x) && isscalar(x));
    addParameter(parser,'ConditionTitles',NaN,@iscellstr);
    addParameter(parser,'CrudeDeartifacting',false,@(x) islogical(x) && isscalar(x));
    addParameter(parser,'FolderTitles',NaN,@iscellstr);
    addParameter(parser,'IncludeProbes',cell(size(folders)),@(x) iscell(x) && numel(x) == numel(folders) && all(cellfun(@(x) isvector(x) || isempty(x),x)));
    addParameter(parser,'ProbeNames',NaN,@iscellstr);
    addParameter(parser,'NoPlot',false,@(x) islogical(x) && isscalar(x));
    addParameter(parser,'NoSave',false,@(x) islogical(x) && isscalar(x));
    addParameter(parser,'SaveFileName','',@(x) (ischar(x) && isvector(x)) || isstring(x));
    addParameter(parser,'Subplots','Conditions',@(x) ismember(x,{'Conditions' 'Probes'}));
    parser.parse(varargin{:});
    
    conditionTitles = parser.Results.ConditionTitles;
    
    allPSTHs = cell(1,numel(folders));
    allParams = cell(1,numel(folders));
    
    for ii = 1:numel(folders)
        if exist([folders{ii} '\Par_PSTH_ave.mat'],'file')
            load([folders{ii} '\Par_PSTH_ave.mat'],'Par_PSTH_ave');
        elseif exist([folders{ii} '\DataMatrix\Par_PSTH_ave.mat'],'file')
            load([folders{ii} '\DataMatrix\Par_PSTH_ave.mat'],'Par_PSTH_ave')
        else
            warning('Can''t find PSTH file for folder %s, ignoring...\n',folders{ii});
            continue
        end
        
        psth = cat(3,Par_PSTH_ave{:,2});
        
        includeProbes = parser.Results.IncludeProbes{ii};
        
        if isempty(includeProbes)
            includeProbes = true(1,size(psth,2));
        elseif ~islogical(includeProbes) && all(includeProbes <= 5)
            includeProbes = repmat(1:32,1,numel(includeProbes))+kron(32 *(includeProbes(:)'-1),ones(1,32)); % TODO : non 32 channel probes?
        end
        
        psth = psth(:,includeProbes,:);
        allPSTHs{ii} = psth;
        allParams{ii} = vertcat(Par_PSTH_ave{:,1});
    end
    
    [params,~,paramIndices] = unique(vertcat(allParams{:}),'rows');
    nConditions = size(params,1);
        
    if ~iscell(conditionTitles) % TODO : this assumes the same set of conditions per folder
        conditionTitles = repmat({''},1,nConditions);

        includeParams = find(arrayfun(@(ii) numel(unique(params(:,ii))) > 1,1:size(params,2)));
        paramNames = {'PW' 'IPI' 'NP' 'Delay' 'X' 'Y' 'Amp'}; % TODO : older formats
        paramUnits = {'ms' 'ms' '' 'ms' '' '' '%'};

        for jj = 1:nConditions
            for kk = includeParams
                if kk > includeParams(1)
                    comma = ' ,';
                else
                    comma = '';
                end

                conditionTitles{jj} = sprintf('%s%s%s = %d%s',conditionTitles{jj},comma,paramNames{kk},params(jj,kk),paramUnits{kk});
            end
        end
    end
    
    maxRepeatConditions = max(accumarray(paramIndices,1,[nConditions 1]));
    
    if maxRepeatConditions == 1 && numel(folders) > 1
        error('Need to check if this results in the same matrix regardless of how you set AverageDuplicateConditions');
    end
    
    if parser.Results.AverageDuplicateConditions
        psths = nan([size(allPSTHs{1},1) size(allPSTHs{1},2) nConditions numel(folders)]);
    else
        psths = nan([size(allPSTHs{1},1) size(allPSTHs{1},2) nConditions maxRepeatConditions]);
        seen = zeros(nConditions,1);
    end
    
    psthsSoFar = 0;
    for ii = 1:numel(allPSTHs)
        psthParamIndices = paramIndices(psthsSoFar+(1:size(allPSTHs{ii},3)));
        
        if parser.Results.AverageDuplicateConditions
            hyperpageIndices = repmat(ii,size(psthParamIndices));
        else
            seen(psthParamIndices) = seen(psthParamIndices)+1;
            hyperpageIndices = seen(psthParamIndices);
        end
        
        for jj = 1:size(allPSTHs{ii},3)
            psths(:,:,psthParamIndices(jj),hyperpageIndices(jj)) = allPSTHs{ii}(:,:,jj);
        end
        
        psthsSoFar = psthsSoFar + size(allPSTHs{ii},3);
    end
    
    if parser.Results.AverageDuplicateConditions
        psths = nanmean(psths,4);
    end
    
    nProbes = size(psths,2)/32; % TODO : diff number of channels per probe
    sdfs = permute(mean(reshape(psths,size(psths,1),32,nProbes,size(psths,3),size(psths,4)),2),[1 3 4 5 2]); % TODO : nChannels
    
    if parser.Results.CrudeDeartifacting
        bad = find(any(any(any(psth >= 0.5,2),3),4)); % TODO : is it ever physiologically possible to have > 1 spike per bin on every trial on every channel of a given probe? is that even what these numbers are?
        good = setdiff(1:size(sdfs,1),bad);
        sdfs(bad,:,:,:) = interp1(good,sdfs(good,:,:,:),bad);
    end
    
    if ~parser.Results.NoSave
        if isempty(parser.Results.SaveFileName)
            if numel(folders) == 1
                filename = [folders{1} '\psth.mat'];
            else
                filename = '';
                
                for ii = 1:numel(folders)
                    if ii > 1
                        separator = '_';
                    else
                        separator = '';
                    end
                    
                    [~,bottomFolder] = fileparts(folders{ii});
                    filename = sprintf('%s%s%s',filename,separator,bottomFolder);
                end
                
                filename = [filename '_combined_psth.mat'];
            end
        else
            filename = parser.Results.SaveFileName; 
        end
        
        options = parser.Results;
        
        save(filename,'psths','sdfs','params','folders','options');
    end
    
    % TODO : moving plotting into a separate function
    if parser.Results.NoPlot
        return
    end
    
    isSingleConditionPerFolder = size(psths,3) == 1;
    
    if isSingleConditionPerFolder
        psths = permute(psths,[1 2 4 3]);
        sdfs = permute(sdfs,[1 2 4 3]);
    end
    
    if ~iscellstr(parser.Results.FolderTitles)
        folderTitles = cellfun(@makeDefaultFolderTitle,folders,'UniformOutput',false);
    else
        folderTitles = parser.Results.FolderTitles;
        assert(numel(folderTitles) == numel(folders),'You must supply one folder title for every folder.');
    end
    
    nBins = size(psths,1);
    nConditions = size(psths,3);
    nFolders = size(psths,4);
    
    switch parser.Results.Subplots
        case 'Conditions'
            legendEntries = parser.Results.ProbeNames;
            
            if isSingleConditionPerFolder
                subplotTitles = folderTitles;
                figureTitles = {''};
            else
                subplotTitles = conditionTitles;
                figureTitles = folderTitles;
            end
        case 'Probes'
            psths = reshape(permute(reshape(psths,nBins,32,nProbes,nConditions,nFolders),[1 2 4 3 5]),nBins,32*nConditions,nProbes,nFolders);
            sdfs = permute(sdfs,[1 3 2 4]);
            subplotTitles = parser.Results.ProbeNames;

            if isSingleConditionPerFolder
                legendEntries = folderTitles;
                figureTitles = {''};
            else
                legendEntries = conditionTitles;
                figureTitles = folderTitles;
            end
        otherwise
            error('Unknown Subplots option ''%s''\n',parser.Results.Subplots);
    end
    
    nSubImages = size(psths,2)/32;
    
    [rows,cols] = subplots(size(psths,3)); % TODO : choose based on params if more than two parameters were varied in a recording
    
    for hh = 1:size(psths,4)
        figure;
        
        for ii = 1:size(psths,3)
            subplot(rows,cols,ii);
            imagesc((1:size(psths,1))-100,1:size(psths,2),psths(:,:,ii,hh)'); % TODO : diff stimulus time
            hold on;
            line(repmat(xlim',1,nSubImages-1),repmat(32*(1:nSubImages-1),2,1),'Color','w'); % TODO : nChannels
            
            title(subplotTitles{ii},'Interpreter','none'); % TODO : what if I want to use TeX?
            
            xlabel('Time (ms)');
            xlim([-50 100]); % TODO : expose parameter
            
            ylim([0 size(psths,2)]);
            set(gca,'YTick',32*(0:nSubImages)); % TODO : nChannels
            caxis([0 1]); % TODO : is this always right?
            
            if iscellstr(legendEntries) && mod(ii,cols) == 1 %#ok<ISCLSTR>
                for jj = 1:nSubImages
                    text(-75,32*(jj-0.5),legendEntries{jj},'FontSize',8,'HorizontalAlignment','center','VerticalAlignment','middle'); % TODO : nChannels, xlim
                end
            end
        end
        
        if ~isSingleConditionPerFolder
            annotation('textbox',[0 0.925 1 0.5],'String',figureTitles{hh},'EdgeColor','none','HorizontalAlignment','center','VerticalAlignment','middle');
        end
    end
    
    yy = [Inf -Inf];
    figs = gobjects(1,size(psths,4));
    
    % TODO : duplicated code
    for hh = 1:size(psths,4)
        figs(hh) = figure;
        
        for ii = 1:size(psths,3)
            subplot(rows,cols,ii);
            plot((1:size(sdfs,1))-100,sdfs(:,:,ii,hh));
            
            title(subplotTitles{ii},'Interpreter','none');
            
            xlabel('Time (ms)');
            xlim([-50 100]); % TODO : expose parameter
            
            yy(1) = min(yy(1),min(ylim));
            yy(2) = max(yy(2),max(ylim));
            
            if iscellstr(legendEntries) && ii == 1 %#ok<ISCLSTR>
                legend(legendEntries)
            end
        end
        
        if ~isSingleConditionPerFolder
            annotation('textbox',[0 0.925 1 0.5],'String',figureTitles{hh},'EdgeColor','none','HorizontalAlignment','center','VerticalAlignment','middle');
        end
    end
    
    set(findobj(figs,'Type','Axes'),'YLim',yy);
end

function folderTitle = makeDefaultFolderTitle(folder)
    [foldersAbove,stimFolder] = fileparts(folder);
    [foldersAbove,dateFolder] = fileparts(foldersAbove);
     
    if strcmp(stimFolder,'DataMatrix')
        stimFolder = dateFolder;
        [~,dateFolder] = fileparts(foldersAbove);
    end
    
    folderTitle = [dateFolder '\' stimFolder];
end