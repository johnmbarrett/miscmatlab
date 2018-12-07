function responseParams = calculateLinearArrayResponseParams(folder,varargin) % TODO : folders? pass psths and/or sdfs directly?
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
    
    sampleRate = 1e3;
    [responseStartIndex,responseEndIndex,baselineStartIndex,baselineEndIndex] = getBaselineAndResponseWindows(sdfs,sampleRate,varargin{:});
    
    responseParams = struct([]);
    
    % TODO : the parameters for calculateTemporalParameters are stupid. Fix them so I can implement this.
    [responseParams(1).peakAmplitudes,          ...
     responseParams(1).peakLatencies,           ...
     responseParams(1).interpolatedLatencies,   ...
     responseParams(1).riseTimes,               ...
     responseParams(1).fallTimes,               ...
     responseParams(1).halfWidths,              ...
     responseParams(1).peak10TimeRising,        ...
     responseParams(1).peak90TimeRising,        ...
     responseParams(1).peak90TimeFalling,       ...
     responseParams(1).peak10TimeFalling,       ...
     responseParams(1).peak50TimeRising,        ...
     responseParams(1).peak50TimeFalling]       ...
        = calculateTemporalParameters(sdfs,sampleRate,'ResultsAsTime',true,'ResponseStartIndex',responseStartIndex,'ResponseEndIndex',responseEndIndex,'BaselineStartIndex',baselineStartIndex,'BaselineEndIndex',baselineEndIndex);
    
    baseline = sdfs(baselineStartIndex:baselineEndIndex,:,:,:);
    
    responseParams(1).mu = mean(baseline);
    responseParams(1).sigma = std(baseline);
    
    parser = inputParser;
    parser.KeepUnmatched = true;
    addParameter(parser,'NoPlot',false,@(x) islogical(x) && isscalar(x));
    addParameter(parser,'SDThreshold',3,@(x) isscalar(x) && isnumeric(x) && isreal(x) && isfinite(x) && x >= 0);
    addParameter(parser,'TransposePlots',false,@(x) islogical(x) && isscalar(x));
    parser.parse(varargin{:});
    
    addParameter(parser,'ProbeNames',NaN,@(x) iscellstr(x) && numel(x) == size(sdfs,2)+parser.Results.TransposeProbes); %#ok<ISCLSTR>
    
    responseParams(1).threshold = responseParams(1).mu+parser.Results.SDThreshold*responseParams(1).sigma;
    parser.parse(varargin{:});
    
    % TODO : this next bit might reasonably be moved into shepherdlabephys
    [thresholdCrossings,~,polarities] = findThresholdCrossings(sdfs(responseStartIndex:responseEndIndex,:,:,:),repmat(responseParams(1).threshold,[ones(1,ndims(sdfs)) 2]),'both');
    
    responseParams(1).responseStartTime = inf(size(thresholdCrossings));
    responseParams(1).responseEndTime = inf(size(thresholdCrossings));
    responseParams(1).responseArea = zeros(size(thresholdCrossings));
    
    for ii = 1:numel(thresholdCrossings)
        firstRise = find(polarities{ii} > 0,1);
        
        if isempty(firstRise)
            continue
        end
        
        responseParams(1).responseStartTime(ii) = thresholdCrossings{ii}(firstRise)/sampleRate;
        
        firstFall = find(polarities{ii}((firstRise+1):end) < 0,1)+firstRise;
        
        if isempty(firstFall)
            firstFall = responseEndIndex-responseStartIndex+1;
        end
        
        responseParams(1).responseEndTime(ii) = thresholdCrossings{ii}(firstFall)/sampleRate;
        
        responseParams(1).responseArea(ii) = sum(sdfs(responseStartIndex-1+(thresholdCrossings{ii}(firstRise):thresholdCrossings{ii}(firstFall)),ii));
    end
    
    fields = fieldnames(responseParams);
    for ii = 1:numel(fields)
        responseParams(1).(fields{ii}) = permute(responseParams(1).(fields{ii}),[2 3 4 1]);
    end
    
    if parser.Results.NoPlot
        return
    end
    
    resultSize = size(responseParams(1).peakAmplitudes);
    
    [rows,cols] = subplots(resultSize(2));
    nFigures = prod(resultSize(3:end));
    
    plotData = responseParams;
    
    if parser.Results.TransposePlots
        sdfs = permute(sdfs,[1 3 2 4:ndims(sdfs)]);
        
        for ii = 1:numel(fields)
            plotData(1).(fields{ii}) = permute(plotData(1).(fields{ii}),[2 1 3:ndims(plotData(1).(fields{ii}))]);
        end
        
        tracePrefix = 'Condition';
    else
        tracePrefix = 'Probe';
    end
    
    traceNames = parser.Results.ProbeNames;
    
    if isnan(traceNames)
        traceNames = arrayfun(@(ii) sprintf('%s %d',tracePrefix,ii),1:size(sdfs,2),'UniformOutput',false);
    end
    
    t = ((1:size(sdfs,1))-responseStartIndex+1)/sampleRate;
    
    markers = 'sd^+x';
    percentiles = [10 50 90];
    directions = {'Rising' 'Falling'};
    
    x = nan(3,2);
    y = nan(3,2);
    
    yy = [Inf -Inf];
    
    hs = gobjects(resultSize(1)+8,1);
    
    for ii = 1:nFigures
        figure;

        for jj = 1:resultSize(2)
            subplot(rows,cols,jj);

            hold on;
            
            if ii == 1 && jj == 1
                colours = get(gca,'ColorOrder');
                colours = repmat(colours,ceil(size(sdfs,2)/size(colours,1)),1);
            end

            hs(1:resultSize(1)) = plot(t,sdfs(:,:,jj,ii));
            
            yy(1) = min(yy(1),min(ylim));
            yy(2) = max(yy(2),max(ylim));

            for kk = 1:size(sdfs,2)
                t1 = responseParams(1).responseStartTime(kk,jj,ii);
                t2 = responseParams(1).responseEndTime(kk,jj,ii);
                tidx = find(t >= t1 & t <= t2);
                fill([t1 t(tidx) t2]',[0;sdfs(tidx,kk,jj,ii);0],colours(kk,:),'EdgeColor','none','FaceAlpha',0.25);
                
                plot(plotData(1).peakLatencies(kk,jj,ii),plotData.peakAmplitudes(kk,jj,ii),'Color',colours(kk,:),'Marker','o');
                
                for ll = 1:3
                    for mm = 1:2
                        x(ll,mm) = plotData(1).(sprintf('peak%dTime%s',percentiles(ll),directions{mm}))(kk,jj,ii);
                        y(ll,mm) = interp1(t,sdfs(:,kk,jj,ii),x(ll,mm));
                        plot(x(ll,mm),y(ll,mm),'Color',colours(kk,:),'Marker',markers(ll));
                    end
                end
                
                peakIndex = plotData(1).peakLatencies(kk,jj,ii)*sampleRate+responseStartIndex-1;
                
                for ll = 1:2
                    m = diff(y([1 3],ll))/diff(x([1 3],ll));
                    c = y(1,ll)-m*x(1,ll);
                    
                    if ll == 1
                        idx = 1:peakIndex;
                    else
                        idx = peakIndex:numel(t);
                    end
                    
                    u = m*t(idx)+c;
                    plot(t(idx),u,'Color',3*colours(kk,:)/4,'LineStyle','--');
                    
                    if ll == 1
                        plot(plotData(1).interpolatedLatencies(kk,jj,ii),interp1(t(idx),u,plotData(1).interpolatedLatencies(kk,jj,ii)),'Color',colours(kk,:),'Marker',markers(4));
                    end
                end
                
                plot(x(2,:),y(2,:),'Color',colours(kk,:),'LineStyle',':');
                
                plot(t([1 end]),plotData(1).threshold(kk,jj,ii)*[1 1],'Color',3*colours(kk,:)/4,'LineStyle','-.');
                plot(plotData(1).responseStartTime(kk,jj,ii),interp1(t,sdfs(:,kk,jj,ii),plotData(1).responseStartTime(kk,jj,ii)),'Color',colours(kk,:),'Marker',markers(5));
                plot(plotData(1).responseEndTime(kk,jj,ii),interp1(t,sdfs(:,kk,jj,ii),plotData(1).responseEndTime(kk,jj,ii)),'Color',colours(kk,:),'Marker',markers(5));
            end
            
            xlabel('Time from stimulus onset (s)');
            xlim(t([baselineStartIndex responseEndIndex]));
            
            ylabel('Events/s');
            
            hs(resultSize(1)+1) = line([0 0],[min(sdfs(:)) max(sdfs(:))],'Color','k');
            hs(resultSize(1)+2) = plot(NaN,NaN,'Color','k','LineStyle','--');
            hs(resultSize(1)+3) = plot(NaN,NaN,'Color','k','LineStyle','-.');
            
            hs(resultSize(1)+4) = fill(NaN,NaN,[0 0 0],'EdgeColor','none','FaceAlpha',0.25);
            
            for kk = 1:5
                hs(resultSize(1)+4+kk) = plot(NaN,NaN,'Color','k','LineStyle','none','Marker',markers(kk));
            end
            
            if jj == 1
                if rows*cols > resultSize(2)
                    a = subplot(rows,cols,resultSize(2)+1);
                    hs = copyobj(hs,a);
                    xlim(a,t(1)-[1000 1]);
                    set(a,'Visible','off');
                end
                
                legend(hs,[traceNames {'Stim Onset' '10-90% peak slope' sprintf('mean+%dSD threshold',parser.Results.SDThreshold) 'Above threshold response'} arrayfun(@(ii) sprintf('%d%% of peak',ii),percentiles,'UniformOutput',false) {'10-90% peak baseline crossing' 'SD threshold crossings'}],'Location','NorthWest');
            end
        end
        
        set(findobj(gcf,'Type','Axes'),'YLim',yy);
    end
end