function [psths,sdfs] = intanPSTHPlots(psths,sdfs,params,varargin)
    parser = inputParser;
    parser.KeepUnmatched = true;
    addParameter(parser,'ConditionTitles',NaN,@iscellstr);
    addParameter(parser,'FolderTitles',repmat({''},size(psths,4)),@iscellstr);
    addParameter(parser,'ProbeNames',NaN,@iscellstr);
    addParameter(parser,'Subplots','Conditions',@(x) ismember(x,{'Conditions' 'Probes'}));
    parser.parse(varargin{:});
    
    folderTitles = parser.Results.FolderTitles;
    conditionTitles = parser.Results.ConditionTitles;
    
    if ~iscell(conditionTitles) % TODO : this assumes the same set of conditions per folder
        conditionTitles = getConditionNames(params);
    end
    
    isSingleConditionPerFolder = size(psths,3) == 1;
    
    if isSingleConditionPerFolder
        psths = permute(psths,[1 2 4 3]);
        sdfs = permute(sdfs,[1 2 4 3]);
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
            nProbes = size(psths,2)/32; % TODO : diff number of channels per probe
            psths = reshape(permute(reshape(psths,nBins,32,nProbes,nConditions,nFolders),[1 2 4 3 5]),nBins,32*nConditions,nProbes,nFolders);
            sdfs = permute(sdfs,[1 3 2 4]);
            
            if ~iscell(parser.Results.ProbeNames)
                subplotTitles = arrayfun(@(ii) sprintf('Probe %d',ii),1:nProbes,'UniformOutput',false);
            else
                subplotTitles = parser.Results.ProbeNames;
            end

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