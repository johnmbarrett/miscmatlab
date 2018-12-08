function plotLinearArrayResponseParams(plotData,xTickLabels,lineNames,saveFileSuffix)
    nSubplots = size(plotData(1).peakAmplitudes,3); % don't use resultSize because it's not guaranteed to have enough elements
    isParamsAsSubplots = nSubplots == 1;
    
    fields = fieldnames(plotData);
    
    if isParamsAsSubplots
        nSubplots = numel(fields);
        nFigures = 1;
    else
        nFigures = numel(fields);
    end
    
    [rows,cols] = subplots(nSubplots);
    ylabels = {'Peak Amplitude (spikes/s)' 'Peak latency (ms)' '10-90% slope onset latency (ms)' 'Rise time (ms)' 'Fall time (ms)' 'FWHM (ms)' 'Time to >10% of peak (ms)' 'Time to >90% of peak (ms)' 'Time to <90% of peak (ms)' 'Time to <10% of peak (ms)' 'Time to >50% of peak (ms)' 'Time to <50% of peak (ms)' 'Baseline mean (spikes/s)' 'Baseline S.D. (spikes/s)' 'Threshold (spikes/s)' 'Threshold crossing latency - onset (ms)' 'Threshold crossing latency - offset (ms)' 'Response AUC (spikes)'};
    coefficients = [1 1000*ones(1,11) 1 1 1 1000 1000 1];
    
    nPoints = size(plotData.peakAmplitudes,1);
    
    for ii = 1:nFigures
        figure;
        
        for jj = 1:nSubplots
            subplot(rows,cols,jj);
            
            fieldIndex = ternaryop(isParamsAsSubplots,jj,ii);
            hs = plot(1:nPoints,coefficients(fieldIndex)*plotData(1).(fields{fieldIndex})(:,:,ternaryop(isParamsAsSubplots,1,jj)),'Marker','o');
            
            xlim([0.5 nPoints+0.5]);
            
            set(gca,'XTick',[]);
            
            yy = ylim;
            ylim(yy); % stop ylim changing when resizing
            
            for kk = 1:nPoints
                % TODO : use actual param values as x-values if there's
                % only one parameter being varied
                text(kk,yy(1)-0.05*diff(yy),xTickLabels{kk},'FontSize',8,'HorizontalAlignment','right','Rotation',45,'VerticalAlignment','middle');
            end
            
            ylabel(ylabels{fieldIndex});
            
            if jj == 1
                if rows*cols > nSubplots
                    a = subplot(rows,cols,nSubplots+1);
                    hs = copyobj(hs,a);
                    xlim(a,[-1 0]);
                    set(a,'Visible','off');
                end
                
                legend(hs,lineNames,'Location','NorthWest');
            end
        end
        
        jbsavefig(gcf,'response_params%s_by_%s',ternaryop(isParamsAsSubplots,'',['_' fields{ii}]),saveFileSuffix);
    end
end