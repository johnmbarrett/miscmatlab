function [bandPassFilteredData,notchFilteredData] = xiaojianFilter(data,sampleRate,highPassFrequency,lowPassFrequency,notchFrequency,notchBandwidth)
    % based on Xiaojian's filter_1.m
    
    if nargin < 2
        sampleRate = 30000;
    end

    if nargin < 5
        notchFrequency = 60;
        doNotch = true;
    elseif isnumeric(notchFrequency) && isscalar(notchFrequency) && isfinite(notchFrequency) && notchFrequency > 0 && notchFrequency < sampleRate/2
        doNotch = true;
    else
        doNotch = false;
    end
    
    if doNotch    
        if nargin < 6
            notchBandwidth = 10;
        end
        
        notchFilteredData = doFilter(data', 'bandstopiir','FilterOrder',2*2, 'HalfPowerFrequency1',notchFrequency - notchBandwidth/2,'HalfPowerFrequency2',notchFrequency + notchBandwidth/2, 'SampleRate',sampleRate);
    else
        notchFilteredData = data';
    end
    
    if nargin < 3
        highPassFrequency = 800;
    end
    
    if nargin < 4
        lowPassFrequency = 6000;
    end
    
    bandPassFilteredData = doFilter(notchFilteredData, 'bandpassiir','FilterOrder',2*2, 'HalfPowerFrequency1',highPassFrequency,'HalfPowerFrequency2',lowPassFrequency, 'SampleRate',sampleRate);
    bandPassFilteredData = bandPassFilteredData';
end

function out = doFilter(in, varargin)
    bpFilt = designfilt(varargin{:});
    out = filter(bpFilt,in);
    out(1,:) = in(1,:);  
    out(2,:) = in(2,:);
end