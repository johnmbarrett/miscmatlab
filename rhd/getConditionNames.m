function conditionNames = getConditionNames(params)
    conditionNames = repmat({''},1,size(params,1));

    includeParams = find(arrayfun(@(ii) numel(unique(params(:,ii))) > 1,1:size(params,2)));
    paramNames = {'PW' 'IPI' 'NP' 'Delay' 'X' 'Y' 'Amp'}; % TODO : older formats
    paramUnits = {'ms' 'ms' '' 'ms' '' '' '%'};

    for jj = 1:size(params,1)
        for kk = includeParams
            if kk > includeParams(1)
                comma = ' ,';
            else
                comma = '';
            end

            conditionNames{jj} = sprintf('%s%s%s = %d%s',conditionNames{jj},comma,paramNames{kk},params(jj,kk),paramUnits{kk});
        end
    end
end