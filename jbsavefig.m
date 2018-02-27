function jbsavefig(fig,formatString,varargin)
    if ischar(fig)
        if nargin > 1
            varargin = [{formatString} varargin];
        end
        
        formatString = fig;
        fig = gcf;
    end
    
    figFile = sprintf(formatString,varargin{:});
    saveas(fig,figFile,'fig');
    saveas(fig,figFile,'png');
end