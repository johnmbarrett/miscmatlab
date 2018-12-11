function [psths,params,varargout] = combineIntanPSTHs(allPSTHs,allParams,varargin)
    isCombineSDFs = false;
    
    if all(cellfun(@(psth,sdf) ndims(psth) == ndims(sdf) && size(psth,1) == size(sdf,1) && all(arrayfun(@(ii) size(psth,ii) == size(sdf,ii),3:ndims(psth))),allPSTHs,allParams))
        assert(~isempty(varargin) && isstruct(varargin{1}) || all(cellfun(@(params) ismatrix(params) && size(params,2) == 7,varargin{1})),'You must supply at least one parameter matrix');
        
        isCombineSDFs = true;
        
        allSDFs = allParams;
        allParams = varargin{1};
        varargin = varargin(2:end);
    end
    
    if isCombineSDFs && isstruct(allParams)
        assert(~isempty(varargin) && all(cellfun(@(params) ismatrix(params) && size(params,2) == 7,varargin{1})),'You must supply at least one parameter matrix');
        
        isCombineResponses = true;
        
        allResponses = allParams;
        allParams = varargin{1};
        varargin = varargin(2:end);
    end
    
    parser = inputParser;
    parser.KeepUnmatched = true;
    addParameter(parser,'AverageDuplicateConditions',false,@(x) islogical(x) && isscalar(x));
    addParameter(parser,'FolderTitles',NaN,@(x) iscellstr(x) && numel(x) == numel(allPSTHs)); %#ok<ISCLSTR>
    parser.parse(varargin{:});
    
    if iscell(parser.Results.FolderTitles)
        folders = cellfun(@(params,folder) repmat({folder},size(params,1),1),allParams,reshape(parser.Results.FolderTitles,size(allParams)),'UniformOutput',false);
        [uniqueFolders,~,folderIndices] = unique(vertcat(folders{:}));
        nFolders = numel(uniqueFolders);
    elseif parser.Results.AverageDuplicateConditions
        folderIndices = ones(sum(cellfun(@(A) size(A,1),allParams)),1);
        nFolders = 1;
    else
        folderIndices = arrayfun(@(ii,A) repmat(ii,size(A{1},1)),reshape(1:numel(allParams),size(allParams)),allParams,'UniformOutput',false);
        folderIndices = vertcat(folderIndices{:});
        nFolders = numel(allParams);
    end
    
    allParams = vertcat(allParams{:});
    [params,~,paramIndices] = unique(allParams,'rows');
    nConditions = size(params,1);
    
    [~,~,hyperParamIndices] = unique([allParams folderIndices],'rows');
    
    maxRepeatConditions = max(accumarray(hyperParamIndices,1));
    
    seen = zeros(nConditions,nFolders);
    
    psths = nan([size(allPSTHs{1},1) size(allPSTHs{1},2) nConditions maxRepeatConditions nFolders]);
    
    if isCombineSDFs
        sdfs = nan([size(allSDFs{1},1) size(allSDFs{1},2) nConditions maxRepeatConditions nFolders]);
    end
    
    if isCombineResponses
        fields = fieldnames(allResponses);
        
        responses = allResponses(1);
        
        for ii = 1:numel(fields)
            responses(1).(fields{ii}) = nan([size(allSDFs{1},2) nConditions maxRepeatConditions nFolders]);
        end
    end
    
    psthsSoFar = 0;
    for ii = 1:numel(allPSTHs)
        psthParamIndices = paramIndices(psthsSoFar+(1:size(allPSTHs{ii},3)));
        psthFolderIndices = folderIndices(psthsSoFar+(1:size(allPSTHs{ii},3)));
        
        seen(psthParamIndices,psthFolderIndices) = seen(psthParamIndices,psthFolderIndices)+1;
        hyperpageIndices = seen(psthParamIndices,psthFolderIndices);
        
        for jj = 1:size(allPSTHs{ii},3)
            psths(:,:,psthParamIndices(jj),hyperpageIndices(jj),psthFolderIndices(jj)) = allPSTHs{ii}(:,:,jj);
            
            if isCombineSDFs
                sdfs(:,:,psthParamIndices(jj),hyperpageIndices(jj),psthFolderIndices(jj)) = allSDFs{ii}(:,:,jj);
            end
            
            if isCombineResponses
                for kk = 1:numel(fields)
                    responses(1).(fields{kk})(:,psthParamIndices(jj),hyperpageIndices(jj),psthFolderIndices(jj)) = allResponses(ii).(fields{kk})(:,jj);
                end
            end
        end
        
        psthsSoFar = psthsSoFar + size(allPSTHs{ii},3);
    end
    
    if parser.Results.AverageDuplicateConditions
        psths = nanmean(psths,4);
        
        if isCombineSDFs
            sdfs = nanmean(sdfs,4);
        end
        
        if isCombineResponses
            for ii = 1:numel(fields)
                responses(1).(fields{ii}) = nanmean(responses(1).(fields{ii}),3);
            end
        end
    end
    
    if size(psths,4) == 1
        psths = permute(psths,[1 2 3 5 4]);
        
        if isCombineSDFs
            sdfs = permute(sdfs,[1 2 3 5 4]);
        end
        
        if isCombineResponses
            for ii = 1:numel(fields)
                responses(1).(fields{ii}) = permute(responses(1).(fields{ii}),[1 2 4 3]);
            end
        end
    end
    
    if isCombineSDFs
        if nargout > 2
            varargout = {params};
        end
        
        params = sdfs;
    end
    
    if isCombineResponses
        if nargout > 3
            varargout{2} = varargout{1};
            varargout{1} = responses;
        end
    end
end