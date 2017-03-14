function makeMeanDeltaFF0Video(dff0,conditions,outputFile,varNames,frameRate,positionFun,figPosition)
    assert(size(conditions,1) == size(dff0,4));
    
    writer = VideoWriter(outputFile);
    writer.FrameRate = frameRate;
    
    open(writer);
    
    % prctile is slow, but a random sample of the data should have roughly
    % the same distribution.  However, generating random numbers is ALSO
    % slow, but a random start plus a fixed interval that is coprime with
    % all dimensions should get us pretty close to random
    
    cax = prctile(dff0(randi(997,1,1):997:end),[1 99]); 
    
    if nargin < 6
        positionFun = @(x,y) [0.05+0.24*(x-1) 1-0.48*y 0.21 0.21*36/20]; % TODO : work this out from the number of conditions
    end
    
    if nargin < 7
        figPosition = [0 0 1200 500];
    end
    
    fig = figure;
    
    for ii = 1:size(dff0,3)
        tic;
        multiFactorPlot(dff0(:,:,ii,:),conditions,@(d,y,x) plotMeanDeltaFF0VideoFrame(d,y,x,cax,positionFun),'Figures',fig,'TrialDim',4,'SubjectDim',5,'VarNames',varNames,'ManualSubplots',true);
        set(fig,'Position',figPosition);
        writeVideo(writer,getframe(fig));
        clf(fig);
        toc;
    end
    
    close(writer);
end

function ax = plotMeanDeltaFF0VideoFrame(frame,y,x,cax,positionFun)
   ax = subplot('Position',positionFun(x,y));
   
   if verLessThan('matlab','9')
       h = image(mean(frame,4),'Parent',ax);
   else
       h = image(ax,mean(frame,4));
   end
   
   xlim([0 size(frame,2)]+0.5);
   ylim([0 size(frame,1)]+0.5);
   set(h,'CDataMapping','scaled')
   set(ax,'XTick',[],'YTick',[]);
   caxis(ax,cax);
   colormap(ax,jet);
end