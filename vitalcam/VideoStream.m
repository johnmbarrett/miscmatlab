classdef (Abstract) VideoStream < handle % TODO: just use OpenCV's VideoCapture or something
    methods
        function obj = VideoStream(varargin)
            setUp(obj,varargin{:});
        end
        
        function delete(obj)
            tearDown(obj);
        end
    end
    
    methods (Abstract, Access = protected)
        setUp(obj)
        tearDown(obj)
    end
    
    methods (Abstract, Access = public)
        b = hasFrame(obj)
        frame = readFrame(obj)
    end
    
    methods (Access = public)
        function b = isnan(~)
            b = false;
        end
    end
end