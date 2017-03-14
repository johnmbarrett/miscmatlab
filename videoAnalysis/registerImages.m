function registerImages(I,J)
    figure;
    displayImage(I);
    
    colormap(gray);
    daspect([1 1 1]);
    set(gca,'YDir','reverse');
    view(2);
    
    xlim([-size(I,2)/2 3*size(I,2)/2]);
    ylim([-size(I,1)/2 3*size(I,1)/2]);
    
    hold on;
    
    h = displayImage(J);
    
    xoff = 0;
    yoff = 0;
    scaleFactor = 1;
    theta = 0;
    alpha = 1;
    
    function handleKey(fig,eventData)
        switch eventData.Key
            case 'w'
                yoff = yoff - 1;
            case 'a'
                xoff = xoff - 1;
            case 's'
                yoff = yoff + 1;
            case 'd'
                xoff = xoff + 1;
            case 'leftarrow'
                theta = theta + 1;
            case 'rightarrow'
                theta = theta - 1;
            case 'uparrow'
                scaleFactor = scaleFactor + 0.01;
            case 'downarrow'
                scaleFactor = scaleFactor - 0.01;
            case 'add'
                alpha = min(1,alpha + 0.01);
            case 'subtract'
                alpha = max(0,alpha - 0.01);
            case 'return'
                % TODO : dirty
                evalin('caller',sprintf('tf = makeAffineTransformation(%f,%f,%f,deg2rad(%f));',xoff,yoff,scaleFactor,theta));
                return
            case 'escape'
                close(fig);
                return
            otherwise
%                 disp(eventData.Key);
                return
        end
        
        h = updateSecondImage(h,J,xoff,yoff,scaleFactor,theta,alpha);
    end

    set(gcf,'KeyPressFcn',@handleKey);
end

function h = displayImage(I,ref)
    I = double(I);
    
    if nargin < 2
        xoff = 0;
        yoff = 0;
    else
        xoff = ref.XWorldLimits(1)-0.05;
        yoff = ref.YWorldLimits(1)-0.05;
    end
    
    [X,Y] = meshgrid((1:size(I,2))+xoff,(1:size(I,1))+yoff);
    
    I = I/max(I(:));
    
    h = surf(X,Y,2*ones(size(I)),I,'FaceColor','texturemap');
    shading flat;
end

function h = updateSecondImage(h,J,xoff,yoff,scaleFactor,theta,alpha)
    tf = makeAffineTransformation(xoff,yoff,scaleFactor,deg2rad(theta));
    
    ref = imref2d(size(J));
    
    [K,ref] = imwarp(J,ref,tf);
    
    delete(h);
    h = displayImage(K,ref);
    set(h,'FaceAlpha',alpha);
end