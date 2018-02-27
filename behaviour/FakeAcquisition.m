classdef FakeAcquisition < handle
    properties
        Data
        Index
        ChunkSize
        SampleRate
    end
    
    methods
        function self = FakeAcquisition(data,sampleRate,chunkSize)
            if nargin < 1
                self.Data = randn(10000,1);
            else
                if size(data,1) < size(data,2)
                    data = data';
                end
                
                self.Data = data;
            end
            
            if nargin < 2
                self.SampleRate = 20000;
            else
                self.SampleRate = sampleRate;
            end
            
            if nargin < 3
                self.ChunkSize = round(self.SampleRate/10);
            else
                self.ChunkSize = chunkSize;
            end
            
            self.Index = 0;
        end
            
        function data = getLatestAnalogData(self)
            data = self.Data(unique(min(self.Index+(1:self.ChunkSize),size(self.Data,1))),:);
            self.Index = self.Index + self.ChunkSize;
        end
    end
end