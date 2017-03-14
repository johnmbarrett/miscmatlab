function plotMotionTrackingWithVideo(V,T,outputFile)
    fig = figure;
    writer = VideoWriter([outputFile '.avi']);
    open(writer);
    
    colours = jet(50);
    
    for ii = 1:numel(V)
        clf(fig);
        
        h = imagesc(192+double(V{1}(:,:,1))/4);
        caxis([0 255]);
        colormap(gray);
        hold on;
        
        for jj = 1:size(T{ii},3)
            plot(T{ii}(1,1,jj),T{ii}(1,2,jj),'Color',colours(1,:),'LineStyle','none','Marker','.');
        end
        
        writeVideo(writer,getframe(fig));
        
        for jj = 2:size(V{ii},3);
            set(h,'CData',192+double(V{ii}(:,:,jj))/4);
            
            for kk = 1:size(T{ii},3)
                line(squeeze(T{ii}(jj-[1 0],1,kk)),squeeze(T{ii}(jj-[1 0],2,kk)),'Color',colours(jj,:));
            end
            
            pause(0.3);
            
            writeVideo(writer,getframe(fig));
        end
        
        if ii == 1
            saveas(fig,[outputFile '.fig']);
        end
    end
    
    close(writer);
    
    close(fig);
end