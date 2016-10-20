classdef EmptyVideoStream < VideoStream % TODO: just use OpenCV's VideoCapture or something
    methods (Access = protected)
        function setUp(~)
            % nothing to do
        end
        
        function tearDown(~)
            % nothing to do
        end
    end
    
    methods (Access = public)
        function b = hasFrame(~)
            b = false;
        end
        
        function frame = readFrame(~)
            frame = uint8(zeros(640,480,3));
        end
    end
end