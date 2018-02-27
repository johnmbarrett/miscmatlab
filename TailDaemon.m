classdef TailDaemon < handle
    properties(Access=protected)
        FileHandle_ = -1
        Callback_
    end
    
    properties(GetAccess=public,SetAccess=protected)
        FileName
        IsPaused
        Timer
    end
    
    properties(Access=public,Dependent=true)
        FileHandle
        Callback
    end
    
    methods
        function self = TailDaemon(filename,callback)
            self.IsPaused = true; % TODO : hacky
            
            if nargin < 2
                self.Callback = @self.defaultCallback;
            else
                self.Callback = callback;
            end
                
            if nargin < 1 || ~ischar(filename) || isempty(filename)
                filename = uigetfile;
            end
            
            self.FileHandle = filename;
            
            self.IsPaused = false;
            
            start(self.Timer);
        end
        
        function delete(self)
            self.cleanupExistingTimer();
            self.cleanupExistingFile();
        end
        
        function s = get.FileHandle(self)
            s = sprintf('Handle to file %s',self.FileName);
        end
        
        function set.FileHandle(self,filename)
            if ischar(filename) && exist(filename,'file')
                fin = fopen(filename,'rb');
            elseif isnumeric(filename) && isscalar(filename);
                fin = filename;
            else
                error('Filename must be a string pointing to a file that exists.');
            end
            
            ftell(fin); % if fin is a valid file handle this will do nothing, otherwise it will give a meaningful error
            
            self.cleanupExistingFile();
            
            self.FileHandle_ = fin;
            
            % don't set self.FileName_ until we know the file is valid
            if ischar(filename)
                self.FileName = filename;
            else % we were provided a raw file handle and Matlab doesn't provide a way to retrieve the file name because matlab is dumb
                self.FileName = 'Unknown File';
            end
            
            self.setupTimer();
        end
        
        function cb = get.Callback(self)
            cb = self.Callback_;
        end
        
        function set.Callback(self, callback)
            assert(isa(callback,'function_handle'),'Callback must be a function handle you absolute numpty.');
            
            self.Callback_ = callback;
            
            self.setupTimer();
        end
    end
    
    methods(Access=protected)
        function cleanupExistingFile(self)
            if self.FileHandle_ < 0
                return
            end
            
            try
                fclose(self.FileHandle_);
            catch err
                logMatlabError(err,'Encountered the following error trying to close the file:-');
            end
        end
        
        function cleanupExistingTimer(self)
            if strcmp(get(self.Timer,'Running'),'on')
                stop(self.Timer);
            end
            
            delete(self.Timer);
        end
        
        function defaultCallback(~,bytes)
            fprintf(1,char(bytes));
        end
        
        function processFileContents(self,varargin)
            theStart = ftell(self.FileHandle_);
            
            fseek(self.FileHandle_,0,1);
            
            theEnd = ftell(self.FileHandle_);
            
%             disp(theStart);
%             disp(theEnd);
            
            if theStart == theEnd
                return
            end
            
            fseek(self.FileHandle_,theStart,-1);
            
            self.Callback(fread(self.FileHandle_,Inf,'uint8'));
        end
        
        function setupTimer(self)
            self.cleanupExistingTimer();
            
            self.Timer = timer( ....
                'BusyMode',         'drop',                     ...
                'ExecutionMode',    'fixedRate',                ... % TODO : expose?
                'Period',           0.2,                          ... % TODO : expose.
                'TimerFcn',         @self.processFileContents   ...
                );
            
            if ~self.IsPaused
                start(self.Timer);
            end
        end
    end
end
        