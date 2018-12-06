function estimateBimorphMotion
    avis = dir('setup*.avi');
    nSetups = numel(avis);

    b = zeros(500,2,nSetups);
    rois = zeros(nSetups,4);
    thresholds = zeros(1,nSetups);
    
    function setThreshold(varargin)
        threshold = get(slider,'Value');
        set(img,'CData',I < threshold);
    end

    for ii = 1:nSetups
        r = VideoReader(avis(ii).name);

        for jj = 1:500
            tic;
            I = mean(double(readFrame(r)),3);

            if jj == 1
                fig = figure;
                img = imagesc(I);

                roi = drawrectangle;

                pos = get(roi,'Position');
                
                for kk = 1:2
                    if pos(kk) >= 0.5
                        continue
                    end
                    
                    pos(kk+2) = pos(kk+2)-pos(kk)-1;
                    pos(kk) = 1;
                end
                
                rois(ii,:) = pos;
                
                x = round(pos(1))+(0:round(pos(3)));
                y = round(pos(2))+(0:round(pos(4)));
                
                threshold = 128;
                
                slider = uicontrol('Style','slider','Units','normalized','Position',[0.05 0.05 0.9 0.05],'Value',threshold,'Min',0,'Max',256,'SliderStep',[1 10]/256,'Callback',@setThreshold);

                uiwait(fig);
                
                thresholds(ii) = threshold;
            end

            B = I(y,x) < threshold;

            idx = find(B);
            [v,u] = ind2sub(size(B),idx);

            b(jj,:,ii) = regress(v,[ones(size(u)) u]);
            toc;
        end
    end
    
    b = reshape(b,100,2,5,nSetups);
    
    disp = squeeze(bsxfun(@rdivide,bsxfun(@minus,b(:,1,:,:),b(end,1,:,:)),sin(atan(b(1,2,:,:)))));
    
    maxDisp = squeeze(max(disp));
    
    [~,currentDir] = fileparts(pwd);
    
    save([currentDir '_bimorph_displacement.mat'],'avis','b','rois','thresholds','disp','maxDisp');
end