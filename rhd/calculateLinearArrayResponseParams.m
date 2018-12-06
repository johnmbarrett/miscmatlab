function calculateLinearArrayResponseParams(folder,varargin) % TODO : folders? pass psths and/or sdfs directly?
    if nargin < 1
        folder = pwd;
    end
    
    if exist(folder,'dir')
        load([folder '\psth.mat'],'sdfs');
    elseif exist(folder,'file')
        m = matfile(folder);
        
        if ~all(cellfun(@(s) isfield(m,s),{'params' 'psths' 'sdfs'}))
            error('Unable to understand contents of file %s\n',folder);
        end
        
        sdfs = m.sdfs;
    else
        error('Cannot locate PSTH file for folder %s\n',folder);
    end
    
    parser = inputParser;
    parser.KeepUnmatched = true;
    isValidIndex = @(x) isnumeric(x) && isscalar(x) && isfinite(x) && round(x) == x && x > 0 && x <= size(sdfs,1);
    addParameter(parser,'BaselineStartIndex',1,isValidIndex);
    addParameter(parser,'ResponseEndIndex',size(sdfs,1),isValidIndex);
    addParameter(parser,'StimOnsetIndex',100,isValidIndex);
    parser.parse(varargin{:});
    
    addParameter(parser,'BaselineEndIndex',parser.Results.StimOnsetIndex,isValidIndex);
    addParameter(parser,'ResponseStartIndex',parser.Results.StimOnsetIndex+1,isValidIndex);
    parser.parse(varargin{:});
    
    % TODO : the parameters for calculateTemporalParameters are stupid. Fix them so I can implement this.
    [peaks,peakIndices,latencies,riseTimes,fallTimes,halfWidths,peak10IndexRising,peak90IndexRising,peak90IndexFalling,peak10IndexFalling,peak50IndexRising,peak50IndexFalling,fallIntercept] = ...
        calculateTemporalParameters(sdfs,1e3);
end