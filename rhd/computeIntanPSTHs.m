function [psths,sdfs] = computeIntanPSTHs(folders,varargin)
    if ischar(folders)
        folders = {folders};
    end

    parser = inputParser;
    parser.KeepUnmatched = true;
    addParameter(parser,'CrudeDeartifacting',false,@(x) islogical(x) && isscalar(x));
    addParameter(parser,'IncludeProbes',cell(size(folders)),@(x) iscell(x) && numel(x) == numel(folders) && all(cellfun(@(x) isvector(x) || isempty(x),x)));
    addParameter(parser,'ManualDeartifacting',NaN,@(x) isnumeric(x) && (isempty(x) || (isvector(x) && all(isreal(x) & isfinite(x) & x >= 1 & x == round(x)))));
    addParameter(parser,'NoPlot',false,@(x) islogical(x) && isscalar(x));
    addParameter(parser,'NoSave',false,@(x) islogical(x) && isscalar(x));
    addParameter(parser,'SaveFileName','',@(x) (ischar(x) && isvector(x)) || isstring(x));
    parser.parse(varargin{:});
    
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
        
        psth = cat(3,Par_PSTH_ave{:,2}); %#ok<IDISVAR,USENS>
        
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
    
    [psths,params] = combineIntanPSTHs(allPSTHs,allParams,varargin{:});
    
    nProbes = size(psths,2)/32; % TODO : diff number of channels per probe
    sdfs = permute(mean(reshape(psths,size(psths,1),32,nProbes,size(psths,3),size(psths,4)),2),[1 3 4 5 2]); % TODO : nChannels
    
    if ~isnan(parser.Results.ManualDeartifacting)
        bad = parser.Results.ManualDeartifacting;
    elseif parser.Results.CrudeDeartifacting
        bad = find(any(any(any(psth >= 0.5,2),3),4)); % TODO : is it ever physiologically possible to have > 1 spike per bin on every trial on every channel of a given probe? is that even what these numbers are?
    else
        bad = [];
    end
    
    if ~isempty(bad)
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
        
        options = parser.Results; %#ok<NASGU>
        
        save(filename,'psths','sdfs','params','folders','options');
    end
    
    % TODO : moving plotting into a separate function
    if parser.Results.NoPlot
        return
    end
    
    if ~ismember('FolderTitles',fieldnames(parser.Unmatched))
        varargin{end+1} = 'FolderTitles';
        varargin{end+1} = cellfun(@makeDefaultFolderTitle,folders,'UniformOutput',false);
    end
    
    intanPSTHPlots(psths,sdfs,params,varargin{:});
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