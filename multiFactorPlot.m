function [figs,uniqueConditions,conditionIndices,conditionsPerFactor] = multiFactorPlot(responses,conditions,plotfun,varargin)
    if nargin > 2 && ischar(plotfun)
        varargin = [{plotfun} varargin];
    end

    [uniqueConditions,~,conditionIndices] = unique(conditions,'rows');
    nConditions = size(uniqueConditions,1);
    nFactors = size(conditions,2);
    conditionsPerFactor = arrayfun(@(col) unique(conditions(:,col)),1:nFactors,'UniformOutput',false);
    nConditionsPerFactor = cellfun(@numel,conditionsPerFactor);
    
    parser = inputParser;
    parser.addParameter('VarNames',arrayfun(@(n) sprintf('Var %d',n),1:nFactors,'UniformOutput',false),@(v) iscellstr(v) && numel(v) == nFactors);
    isIntegerScalarLessThanResponseDims = @(x) isnumeric(x) && isscalar(x) && isfinite(x) && round(x) == x && x > 0 && x <= ndims(responses)+1; % plus one because need to specify first singleton dimension as subject dim if only one subject
    parser.addParameter('TrialDim',2,isIntegerScalarLessThanResponseDims);
    parser.addParameter('SubjectDim',3,isIntegerScalarLessThanResponseDims);
    parser.addParameter('Colours',[0 0 0],@(x) isnumeric(x) && isreal(x) && ismatrix(x) && size(x,2) == 3 && all(isfinite(x(:)) & x(:) >= 0 & x(:) <= 1));
    parser.addParameter('SaveFilePrefix',NaN,@ischar);
    parser.addParameter('XData',NaN);
    parser.addParameter('XDim',1,isIntegerScalarLessThanResponseDims);
    parser.addParameter('ManualSubplots',false,@(x) isscalar(x) && islogical(x));
    parser.addParameter('Figures',NaN,@(x) all(isgraphics(x(:))));
    
    parser.parse(varargin{:});
    
    x = parser.Results.XData;
    if isscalar(x) && isnan(x)
        x = 1:size(responses,parser.Results.XDim); 
    else
        assert(isvector(x) && isnumeric(x) && numel(x) == size(responses,parser.Results.XDim));
    end
    
    nSubjects = size(responses,parser.Results.SubjectDim);
    nTrials = size(responses,parser.Results.TrialDim);
    assert(ismatrix(conditions) && isnumeric(conditions) && size(conditions,1) == nTrials); % TODO : non-numeric conditions
    
    if ~isgraphics(parser.Results.Figures)
        if nFactors < 3
            figs = gobjects(nSubjects,1);
        else
            figs = gobjects([nConditionsPerFactor(3:end) nSubjects]);
        end
        
        for ii = 1:numel(figs)
            figs(ii) = figure;
        end
    else
        figs = parser.Results.Figures;
        assert(numel(figs) == prod(nConditionsPerFactor(3:end)*nSubjects));
    end
    
    colours = parser.Results.Colours;
    
    if size(colours,1) < nSubjects
        colours = repmat(colours,ceil(nSubjects/size(colours,1)),1);
    end
    
    varNames = parser.Results.VarNames;
    
    for ii = 1:nSubjects
        for jj = 1:nConditions
            condition = uniqueConditions(jj,:);
            
            conditionIndex = cell(1,nFactors);
            
            for kk = 1:nFactors
                conditionIndex{kk} = find(condition(kk) == conditionsPerFactor{kk});
            end
            
            figIndex = [conditionIndex(3:end) {ii}];
            fig = figs(figIndex{:});
            
%             if nFactors > 2
                superTitle = sprintf('Subject #%d',ii);
                
                for kk = 3:nFactors
                    superTitle = sprintf('%s, %s',getVarNameValueString(varNames{kk},conditionsPerFactor{kk}(conditionIndex{kk})));
                end
            
                annotation(fig,'textbox',[0.5 0.9 0.1 0.1],'String',superTitle,'EdgeColor','none');
%             end
            
            dataIndex = repmat({':'},1,ndims(responses));
            dataIndex{parser.Results.TrialDim} = conditionIndices == jj;
            dataIndex{parser.Results.SubjectDim} = ii;
            data = responses(dataIndex{:});
            
            if nargin > 3 && isa(plotfun,'function_handle') % TODO : option to use default subplot positioning
                if parser.Results.ManualSubplots
                    ax = plotfun(data,conditionIndex{1},conditionIndex{2});
                else
                    ax = subplot(nConditionsPerFactor(1),nConditionsPerFactor(2),nConditionsPerFactor(2)*(conditionIndex{1}-1)+conditionIndex{2},'Parent',fig);
                    plotfun(ax,data,conditionIndex{1},conditionIndex{2});
                end
            else
                ax = subplot(nConditionsPerFactor(1),nConditionsPerFactor(2),nConditionsPerFactor(2)*(conditionIndex{1}-1)+conditionIndex{2},'Parent',fig);
                hold(ax,'on');
                plot(ax,x,data,'Color',0.5+colours(ii,:)*0.5); % TODO : x-axis
                plot(ax,x,nanmean(data,parser.Results.TrialDim),'Color',colours(ii,:),'LineWidth',2);
            end
            
            if conditionIndex{2} == 1
                ylabel(ax,getVarNameValueString(varNames{1},conditionsPerFactor{1}(conditionIndex{1})));
            end
            
            if conditionIndex{1} == 1
                title(ax,getVarNameValueString(varNames{2},conditionsPerFactor{2}(conditionIndex{2})));
            end
        end
    end
    
    saveFilePrefix = parser.Results.SaveFilePrefix;
    
    if isnan(saveFilePrefix)
        return
    end
    
    figIndex = cell(1,ndims(figs));
    
    for ii = 1:numel(figs)
        [figIndex{1:end}] = ind2sub(size(figs),ii);

        figFile = saveFilePrefix;

        for kk = 3:size(conditions,2)
            figFile = sprintf('%s_%s',figFile,getVarNameValueString(varNames{kk},conditionsPerFactor{kk}(figIndex{kk-2})));
        end

        figFile = sprintf('%s_subject_%d.fig',figFile,figIndex{end-(nFactors<3)});

        saveas(figs(ii),figFile,'fig');
    end
end

function s = getVarNameValueString(varName,value)
    if round(value) == value % TODO : user provided format
        formatChar = 'd';
    else
        formatChar = 'f';
    end

    s = sprintf(['%s = %' formatChar],varName,value);
end