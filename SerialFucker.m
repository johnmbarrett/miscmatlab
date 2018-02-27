classdef SerialFucker
    properties
        Figure
        SerialPort  serial
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
            
            self.Figure = figure;
            set(self.Figure,'KeyReleaseFcn',@self.sendKey);
        end
        
        function delete(self)
            delete(self.Figure);
            
            if isa(self.SerialPort,'serial') && ischar(get(self.SerialPort,'Status')) && strcmp(get(self.SerialPort,'Status'),'open')
                fclose(self.SerialPort);
            end
        end
        
        function sendKey(self,~,eventData)
            disp(eventData.Key);
            fprintf(self.SerialPort,'%s\n',eventData.Key);
        end
    end
end