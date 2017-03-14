function quickCalciumImagingAnalysis(outputPrefix,conditions,varNames,frameRate,positionFun,figPosition,offlineBinning,badPixels,dropFrames,regenerateDFF0) % TODO : name-value params
    files = loadFilesInNumericOrder('et*.tiff','et([0-9]+).*\.tiff'); % TODO : specify match string/regex
    timestamps = cellfun(@(A) str2double(A{1}{1}),cellfun(@(s) regexp(s,'et[0-9]+_([0-9]+)\.tiff','tokens'),files,'UniformOutput',false))'; % TODO : specify regex
    [timestamps,si] = sort(timestamps); %#ok<TRSRT>
    files = files(si);

    if nargin < 1 || isempty(outputPrefix)
        [~,outputPrefix] = fileparts(pwd);
    end 
    
    dff0File = [outputPrefix '_dff0.mat'];
    trialStarts = [1;find(diff(timestamps/1e4) > 0.4)+1]; % TODO : specify gap between trials
    
    if nargin < 9
        dropFrames = 2;
    end
    
    trialEnds = [find(diff(timestamps/1e4) > 0.4); numel(timestamps)]-dropFrames; % something about xiaojian's video recording software seems to cause the penultimate frame to be much darker than the rest, so just ignore the last two

    nFramess = trialEnds-trialStarts+1;
    badTrials = nFramess < mode(nFramess)*0.8; % TODO : specify tolerance
    trialStarts = trialStarts(~badTrials);
    trialEnds = trialEnds(~badTrials);
    
    if nargin < 4 || isempty(frameRate)
        frameRate = 1/median(diff(timestamps/1e4));
    end
    
    if (nargin < 10 || ~all(logical(regenerateDFF0))) && exist(dff0File,'file')
        load(dff0File);
    else
        stacks = cellfun(@imread,files,'UniformOutput',false);   
        
        if nargin > 7 && ~isempty(badPixels)
            for jj = 1:numel(stacks)
                for ii = 1:numel(badPixels)
                    stacks{jj}(badPixels{ii}(2)+(1:badPixels{ii}(4))-1,badPixels{ii}(1)+(1:badPixels{ii}(3))-1,:) = NaN;
                end
            end
        end
        
        if nargin > 6 && ~isempty(offlineBinning)
            stacks = cellfun(@(A) bin(A,offlineBinning),stacks,'UniformOutput',false);
        end

        [dff0,f0] = extractDeltaFF0(stacks,[trialStarts trialStarts+floor(frameRate)-1],[trialStarts trialEnds]); %#ok<ASGLU> % TODO : specify number of baseline frames

        save(dff0File,'-v7.3','dff0','f0');
    end
    
    nTrials = numel(trialStarts);
    
    if nargin < 2 || isempty(conditions)
        conditions = [zeros(nTrials,1) repmat([0;1],nTrials/2,1)]; % TODO : odd number of trials?
    end
    
    if nargin < 3 || isempty(varNames)
        varNames = {'Dummy' 'Stim On'};
    end
    
    if nargin < 5 || isempty(positionFun)
        positionFun = @(x,y) [0.025+0.5*(x-1) 0.05 0.45 0.9]; % TODO : better default
    end
       
    if nargin < 6 || isempty(figPosition)
        figPosition = [0 0 1400 900]; % TODO : better default
    end
    
    makeMeanDeltaFF0Video(dff0,conditions,[outputPrefix '_basic.avi'],varNames,frameRate,positionFun,figPosition);
    
    save(dff0File,'-append','conditions','varNames','frameRate','positionFun','figPosition');
end