classdef SerialFucker
    properties
        Figure
        SerialPort  %serial
        SerialReader
    end
    
    methods
        function self = SerialFucker(port)
            ports = getAvailableComPort;
            
            if isempty(ports)
                error('There are not serial ports to fuck.');
            end
            
            if nargin < 1
                port = ports{1};
            else
                assert(ismember(port,ports),'You can not fuck a port that does not exist.');
            end
            
            self.SerialPort = serial(port,'BaudRate',115200);
            fopen(self.SerialPort);
            
            self.SerialReader = timer('BusyMode','drop','ExecutionMode','fixedSpacing','Period',0.1,'TimerFcn',@self.printSerialBuffer);
            start(self.SerialReader);
            
            self.Figure = figure;
            set(self.Figure,'KeyPressFcn',@self.sendKey);
            set(self.Figure,'KeyReleaseFcn',@self.sendTheWordStop);
        end
        
        function delete(self)
            delete(self.Figure);
            
            if strcmp(self.SerialReader.Running,'on')
                stop(self.SerialReader);
            end
            
            delete(self.SerialReader);
            
            if isa(self.SerialPort,'serial') && ischar(get(self.SerialPort,'Status')) && strcmp(get(self.SerialPort,'Status'),'open')
                fclose(self.SerialPort);
            end
        end
        
        function printSerialBuffer(self,varargin) 
            disp('Polling...');
            
            while self.SerialPort.BytesAvailable > 0
                disp(fgetl(self.SerialPort));
            end
        end
        
        function sendKey(self,~,eventData)
            if numel(eventData.Key) > 1
                return
            end
            
            keycode = uint16(eventData.Key);
            
            if numel(keycode) > 1 || keycode > 255
                return
            end
            
            disp(['SENT: ' eventData.Key]);
            fwrite(self.SerialPort,uint8(keycode));
        end
        
        function sendTheWordStop(self,varargin)
            disp('SENT: STOP');
            fwrite(self.SerialPort,0);
        end
    end
end