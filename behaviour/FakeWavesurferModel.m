classdef FakeWavesurferModel < ws.WavesurferModel
    methods
        function self = FakeWavesurferModel(varargin)
            self.Acquisition_ = FakeAcquisition;
            self.Stimulation_ = FakeStimulation;
        end
    end
end