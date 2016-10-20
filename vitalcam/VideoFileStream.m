classdef VideoFileStream < VideoStream
    properties (Access = private)
        Reader
    end
    
    methods (Access = protected)
        function setUp(obj,varargin)
            if nargin == 1
                formats = strjoin(arrayfun(@(fmt) sprintf('*.%s',fmt.Extension),VideoReader.getFileFormats(),'UniformOutput',false),';');
                [filename,filepath] = uigetfile({formats 'Video Files'});
                
                if filename == 0
                    error('VideoFileStream:NoInputFile','No input file specified');
                end
                
                filepath = [filepath filename];
            elseif ischar(varargin{2})
                filepath = varargin{2};
            else
                error('VideoFileStream:NoInputFile','No input file specified');
            end
            
            obj.Reader = VideoReader(filepath);
        end
        
        function tearDown(~)
            % nothing to do
        end
    end
    
    methods (Access = public)
        function b = hasFrame(obj)
            b = obj.Reader.hasFrame();
        end
        
        function frame = readFrame(obj)
            frame = obj.Reader.readFrame();
        end
    end
end