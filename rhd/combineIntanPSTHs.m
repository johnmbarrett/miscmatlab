function [psths,params,varargout] = combineIntanPSTHs(allPSTHs,allParams,varargin)
    isCombineSDFs = false;
    
    if all(cellfun(@(psth,sdf) ndims(psth) == ndims(sdf) && size(psth,1) == size(sdf,1) && all(arrayfun(@(ii) size(psth,ii) == size(sdf,ii),3:ndims(psth))),allPSTHs,allParams))
        assert(~isempty(varargin) && all(cellfun(@(params) ismatrix(params) && size(params,2) == 7,varargin{1})),'You must supply at least one parameter matrix');
        
        isCombineSDFs = true;
        
        allSDFs = allParams;
        allParams = varargin{1};
        varargin = varargin(2:end);
    end

    [params,~,paramIndices] = unique(vertcat(allParams{:}),'rows');
    nConditions = size(params,1);
    
    maxRepeatConditions = max(accumarray(paramIndices,1,[nConditions 1]));
    
    if maxRepeatConditions == 1 && numel(allPSTHs) > 1
        error('Need to check if this results in the same matrix regardless of how you set AverageDuplicateConditions');
    end
    
    parser = inputParser;
    parser.KeepUnmatched = true;
    addParameter(parser,'AverageDuplicateConditions',false,@(x) islogical(x) && isscalar(x));
    parser.parse(varargin{:});
    
    if parser.Results.AverageDuplicateConditions
        nPSTHs = numel(allPSTHs);
    else
        nPSTHs = maxRepeatConditions;
        seen = zeros(nConditions,1);
    end
    
    psths = nan([size(allPSTHs{1},1) size(allPSTHs{1},2) nConditions nPSTHs]);
    
    if isCombineSDFs
        sdfs = nan([size(allSDFs{1},1) size(allSDFs{1},2) nConditions nPSTHs]);
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
            
            if isCombineSDFs
                sdfs(:,:,psthParamIndices(jj),hyperpageIndices(jj)) = allSDFs{ii}(:,:,jj);
            end
        end
        
        psthsSoFar = psthsSoFar + size(allPSTHs{ii},3);
    end
    
    if parser.Results.AverageDuplicateConditions
        psths = nanmean(psths,4);
        
        if isCombineSDFs
            sdfs = nanmean(sdfs,4);
        end
    end
    
    if isCombineSDFs
        if nargout > 2
            varargout = {params};
        end
        
        params = sdfs;
    end
end