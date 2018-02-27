function doubleLeverTaskTest(waveforms,varargin)
    if isa(waveforms,'DoubleLeverTask')
        theTask = waveforms;
        theModel = theTask.Parent;
        waveforms = varargin{1};
        varargin = varargin(2:end);
    else
        theModel = FakeWavesurferModel;
        theTask = DoubleLeverTask(struct('Parent',theModel));
    end

    parser = inputParser;
    parser.addRequired('waveforms',@(x) isnumeric(x) && ismatrix(x) && size(x,2) == 2 && all(isreal(x(:)) & isfinite(x(:)))); % TODO : multiple sweeps?
    isFiniteRealNonNegativeScalar = @(x) isnumeric(x) && isscalar(x) && isfinite(x) && isreal(x) && x > 0;
    parser.addParameter('SamplingRate',2e4,isFiniteRealNonNegativeScalar);
    parser.addParameter('DeltaT',0.1,isFiniteRealNonNegativeScalar);
    parser.addParameter('Thresholds',[NaN NaN],@(x) isnumeric(x) && isequal(size(x),[1 2]) && all(isreal(x) & isfinite(x) & x >= -10 & x <= 100))
    parser.addParameter('ContinuousReward',NaN,@(x) islogical(x) && issscalar(x));
    parser.addParameter('DelayPeriod',NaN,isFiniteRealNonNegativeScalar);
    parser.addParameter('StimPeriod',NaN,isFiniteRealNonNegativeScalar);
    parser.addParameter('ResponsePeriod',NaN,isFiniteRealNonNegativeScalar);
    parser.parse(waveforms,varargin{:});
    
    if ~all(isnan(parser.Results.Thresholds))
        theTask.setThresholds(parser.Results.Thresholds);
    end
    
    if ~isnan(parser.Results.ContinuousReward)
        theTask.setContinuousReward(parser.Results.ContinuousReward);
    end
    
    if ~isnan(parser.Results.DelayPeriod)
        theTask.DelayPeriod = parser.Results.DelayPeriod;
    end
    
    if ~isnan(parser.Results.StimPeriod)
        theTask.StimPeriod = parser.Results.StimPeriod;
    end
    
    if ~isnan(parser.Results.ResponsePeriod)
        theTask.ResponsePeriod = parser.Results.ResponsePeriod;
    end
    
    n = ceil(parser.Results.SamplingRate*parser.Results.DeltaT);
    N = size(waveforms,1);
    T = N/parser.Results.SamplingRate;
    m = ceil(N/n);
    
    fprintf('Starting sweep...\n');
    
    theTask.startingSweep();
    
    fprintf('Task state is %s\n',theTask.State);

    t = tic;
    for ii = 1:m
        pause(parser.Results.DeltaT);
        fprintf('Feeding task waveforms from t = %f to %f...\n',(ii-1)*parser.Results.DeltaT,min(ii*parser.Results.DeltaT,T));
        theModel.Acquisition.setLatestAnalogData(waveforms(((ii-1)*n+1):min(ii*n,N),:));
        theTask.dataAvailable(theModel);
        fprintf('Elapsed time is %f seconds\n',toc(t));
        fprintf('Task state is %s\n',theTask.State);
    end
end