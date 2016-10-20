function addEphysTracesToDFF0Plot(ffig,traceFiles,conditions)
    nTrials = size(conditions,1);
    assert(numel(traceFiles) == nTrials);

    nSamples = NaN;
    
    nn = 0;
    while isnan(nSamples)
        nn = nn + 1;
        
        try
            xsg = importdata(traceFiles{nn});
            nSamples = size(xsg.data.ephys.trace_1,1);
        catch
            continue
        end
    end
    
    traces = nan(nSamples,nTrials);
    traces(:,nn) = xsg.data.ephys.trace_1;
    
    for ii = (nn+1):nTrials
        tic;
        xsg = importdata(traceFiles{ii});
        traces(:,ii) = xsg.data.ephys.trace_1;
        toc;
    end
        
    tmax = nSamples/1e4;
    [efig,~,~,conditionsPerFactor] = multiFactorPlot(traces,conditions,'XData',1e-4:1e-4:tmax); % TODO : sampling rate
    
    assert(numel(ffig) == 1 && numel(efig) == 1); % TODO : make this not have to be true
    
    nConditionsPerFactor = cellfun(@numel,conditionsPerFactor);
    
    fig = figure;
    set(fig,'Position',[0 0 1600 1200]);
    
    faxs = get(ffig,'Children');
    
    for ii = 1:numel(faxs)
        hs = get(faxs(ii),'Children');
        
        for jj = 1:numel(hs)
            set(hs(jj),'XData',0.24+(0.12:0.12:(0.12*numel(get(hs(jj),'XData'))))); % TODO : frame rate and offset
        end
    end
    
    eaxs = get(efig,'Children');
    saxs = [faxs eaxs];
    
    yy = zeros(2,2);
    
    for ii = 1:2
        ylims = get(saxs(:,ii),'YLim');
        ylims = vertcat(ylims{:});
        yy(ii,1) = min(ylims(:,1));
        yy(ii,2) = max(ylims(:,2));
    end
    
    rows = nConditionsPerFactor(1);
    cols = nConditionsPerFactor(2);
    
    for ii = 1:rows
        for jj = 1:cols
            for kk = 1:2
                ax = subplot(rows*2,cols,cols*(2*(ii-1)+kk-1)+jj);
                pos = get(ax,'Position');
                delete(ax);
                ax = copyobj(saxs(rows*cols-(cols*(ii-1)+jj)+1,kk),fig);
                set(ax,'Position',pos);
                xlim(ax,[0 tmax]);
                ylim(ax,yy(kk,:));
            end
        end
    end
end