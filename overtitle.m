function overtitle(s)
    fakeAxis = subplot('Position',[0.5 0.975 0 0]);
    set(fakeAxis,'Visible','off');
    plot(fakeAxis,0,0);
    text(0,0,s,'FontSize',16,'FontWeight','bold','HorizontalAlignment','center','Interpreter','none','Parent',fakeAxis,'VerticalAlignment','middle'); % TODO : varargin
end