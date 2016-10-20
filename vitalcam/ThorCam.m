classdef ThorCam < VideoStream
    properties (Access = private)
        Handle
    end
    
    methods (Access = protected)
        function setUp(obj)
            obj.Handle = thormex('init');
            thormex('prepareMemory',obj.Handle,1024,1280,24); % oh dear
        end
        
        function tearDown(obj)
            try
                thormex('exit',obj.Handle);
            catch err
                warning('thormex encountered error "%s" trying to close camera\n',err.message);
            end
        end
    end
       
    methods (Access = public)
        function b = hasFrame(~) % lol
            b = true;
        end
        
        function frame = readFrame(obj)
            frame = thormex('readFrame',obj.Handle);
        end
    end
end