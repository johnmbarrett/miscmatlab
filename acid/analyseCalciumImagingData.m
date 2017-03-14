function analyseCalciumImagingData(files,ledOnFrames,baselineFrames,trialFrames,conditions,outputFile,varNames) % TODO : switch to param-value style
    stacks = openTIFFStacks(files);
    
    [rois,masks,meanImage] = chooseROIs(stacks,'UseFrames',ledOnFrames,'MeanImageFile',[outputFile '_meanImage']); %#ok<ASGLU>
    
    [dff0,f0] = extractDeltaFF0(stacks,baselineFrames,trialFrames,ledOnFrames); %#ok<ASGLU>
    
    if nargin < 7 || ~iscellstr(varNames) || numel(varNames) ~= size(conditions,2)
        varNames = arrayfun(@(n) sprintf('Var %d',n),1:size(conditions,2),'UniformOutput',false);
    end
    
    responses = extractROIResponses(dff0,masks,conditions,varNames,outputFile,distinguishable_colors(numel(masks))); %#ok<NASGU>
    
    save([outputFile '.mat'],'-v7.3','meanImage','f0','dff0','rois','masks','conditions','varNames','responses');
end