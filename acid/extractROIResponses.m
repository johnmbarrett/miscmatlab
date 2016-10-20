function responses = extractROIResponses(dff0,masks,conditions,varNames,outputFile,colours)
    nCells = numel(masks);
    nTrials = size(dff0,4);
    framesPerTrial = size(dff0,3);
    
    responses = zeros(framesPerTrial,nTrials,numel(masks));
    
    if nargin < 6
        colours = distinguishable_colors(nCells);
    end
    
    for ii = 1:nCells
        n = sum(sum(masks{ii}));
        
        for jj = 1:framesPerTrial
            for kk = 1:nTrials
                responses(jj,kk,ii) = sum(sum(dff0(:,:,jj,kk).*masks{ii}))/n;
            end
        end
    end
    
    multiFactorPlot(responses,conditions,'VarNames',varNames,'Colours',colours,'SaveFilePrefix',outputFile);
end