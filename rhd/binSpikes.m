function [psth, traces] = binSpikes(traces,sampleRate,isDeartifact,binWidth)
    % TODO : this can be merged in to shepherdlabephys
    if nargin < 4
        binWidth = sampleRate / 1000;
    end
    
    nBins = ceil(size(traces,1) / binWidth);

    if isDeartifact == 1
        traces(abs(traces) > 200) = 0; % TODO : set threshold
    end

    threshold = -4 * std(traces);

    psth = diff(bsxfun(@lt,traces,threshold)) == 1;
    
    % TODO : Xiaojian's original code had an off-by-one error whereby if
    % the data was above threshold at the edge of one bin and below
    % threshold at the beginning of the other, it would assign the spike to
    % the wrong bin. Leaving out the below should cause roughly the same
    % bug, at the risk of introducing the opposite bug going in the other
    % direction. For the sake of reproducing Xiaojian's code's results, I'm
    % leaving it like this for now.
%     psth = [traces(1,:) < threshold; psth]; % diff algorithm misses the very first sample
    
    psth = [psth; zeros(nBins*binWidth-size(psth,1),size(psth,2))]; % zero pad to a whole number of bins
    
    psth = squeeze(sum(reshape(psth,binWidth,nBins,[]),1));
end