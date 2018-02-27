function tf = registerImages(I,J)
    fig = figure;
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
    nargoutCaller = nargout;
    currentKey = '';
    
    function doAction(varargin)
%         disp(['The key is ' currentKey]);
        
        switch currentKey
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
            otherwise
                return
        end
        
        h = updateSecondImage(h,J,xoff,yoff,scaleFactor,theta,alpha);
    end
       
    function handleKey(fig,eventData)
        switch eventData.Key
            case 'return'
                tf = makeAffineTransformation(xoff,yoff,scaleFactor,deg2rad(theta));
                
                if nargoutCaller == 0
                    % TODO : dirty
                    assignin('caller','tf',tf);
                else
                    stopTimersAndCloseFig(fig)
                end
%                 evalin('caller',sprintf('tf = makeAffineTransformation(%f,%f,%f,deg2rad(%f));',xoff,yoff,scaleFactor,theta));
            case 'escape'
                stopTimersAndCloseFig(fig);
            otherwise
%                 disp('We are pressing a key now');
                currentKey = eventData.Key;
                
                if strcmp(t.Running,'off')
                    start(t);
                end
        end
    end

    function releaseKey(varargin)
%         disp('We have stopped pressing the key');
        stop(t);
    end

    function stopTimersAndCloseFig(fig)
        if isvalid(t) && ~strcmp(t.Running,'off')
            stop(t);
        end
        
        delete(t);
        delete(fig);
    end

    set(fig,'KeyPressFcn',@handleKey);
    set(fig,'KeyReleaseFcn',@releaseKey);
    set(fig,'CloseRequestFcn',@(varargin) stopTimersAndCloseFig(fig));
    
    t = timer('BusyMode','drop','ExecutionMode','fixedSpacing','Period',0.15,'StartDelay',0.05,'TimerFcn',@doAction);
    
    cleanupTimer = onCleanup(@(varargin) delete(t));
    
    if nargout > 0
        uiwait(fig);
    end
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
%     tic;
    tf = makeAffineTransformation(xoff,yoff,scaleFactor,deg2rad(theta));
    
    ref = imref2d(size(J));
    
    [K,ref] = imwarp(J,ref,tf);
    
    delete(h);
    h = displayImage(K,ref);
    set(h,'FaceAlpha',alpha);
%     toc;
end