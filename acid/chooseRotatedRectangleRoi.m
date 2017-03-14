function [mask,theta,x,y,w,pos] = chooseRotatedRectangleROI(I)
    fig = figure;
    image = imshow(I);
    caxis([min(I(:)) max(I(:))]);
    
    lineROI = NaN;
    rect = NaN;
    theta = 0;
    pos = [0 0; 0 0];
    w = 50;
    x = [0 0 0 0];
    y = [0 0 0 0];
    
    function makeRectangle(hObj,varargin)
        w = get(hObj,'Value');
        
        x = pos([1 1 2 2],1)+[-1 1 1 -1]'*w*cos(theta)/2;
        y = pos([1 1 2 2],2)+[-1 1 1 -1]'*w*sin(theta)/2;
        
        if isgraphics(rect)
            delete(rect);
        end
        
        rect = line([x x([2:4 1])],[y y([2:4 1])],'Color','g');
        
        set(txt,'String',num2str(w))
    end

    isDone = false;

    function finish(varargin)
        isDone = true;
        uiresume(fig);
    end

    function makeLine(varargin)
        if isa(lineROI,'imroi')
            delete(lineROI);
        end
        
        if isgraphics(rect)
            delete(rect);
        end
        
        lineROI = imline;
    
        pos = getPosition(lineROI);
        theta = atan2(diff(pos(:,2)),diff(pos(:,1)))+pi/2;
    end

    width = size(I,2);
    
    imagePos = get(get(image,'Parent'),'Position');
    figPos = get(fig,'Position');
    imagePosPixels = round(imagePos.*repmat(figPos(3:4),1,2));
    
    sliderPos = [imagePosPixels(1) max(0,imagePosPixels(2)-25) max(50,imagePosPixels(3)-110) 20];
    doneButtonPos = [imagePosPixels(1)+sliderPos(3)+5 max(0,imagePosPixels(2)-25) 50 20];
    resetButtonPos = [imagePosPixels(1)+sliderPos(3)+60 max(0,imagePosPixels(2)-25) 50 20];
    textPos = [imagePosPixels(1)+sliderPos(3)/2 sliderPos(2)-20 20 15];
    
    slider = uicontrol('Parent',fig, 'Style','slider', 'Value',50, 'Min',0,...
        'Max',width, 'SliderStep',[1 10]./width, ...
        'Position',sliderPos, 'Callback',@makeRectangle);
    uicontrol('Parent',fig,'Style','pushbutton','Position',doneButtonPos','String','Done','Callback',@finish);
    uicontrol('Parent',fig,'Style','pushbutton','Position',resetButtonPos','String','Reset','Callback',@makeLine);
    txt = uicontrol('Style','text', 'Position',textPos, 'String','50');
    
    makeLine();
    
    makeRectangle(slider);
    
    while ~isDone
        uiwait(fig); % for some reason the reset button also causes uiresume
    end
    
    % http://math.stackexchange.com/a/190373
    [AMy,AMx] = ndgrid((1:size(I,1))-y(1),(1:width)-x(1));
    AB = [x(2)-x(1) y(2)-y(1)];
    AD = [x(4)-x(1) y(4)-y(1)];
    AMAB = AMx*AB(1)+AMy*AB(2);
    AMAD = AMx*AD(1)+AMy*AD(2);
    mask = (0 < AMAB & AMAB < sum(AB.^2) & 0 < AMAD & AMAD < sum(AD.^2));
end