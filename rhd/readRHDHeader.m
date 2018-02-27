function [header,fin] = readRHDHeader(file)
    try
        fin = fopen(file,'rb');

        fseek(fin,0,-1);

        magicNumber = typecast(hex2num('C6912702'),'uint32');
        assert(fread(fin,1,'uint32') == magicNumber(2),'File is not a valid RHD file');

        header = struct([]);

        versionArray = fread(fin,[1 2],'int16');
        versionString = sprintf('%d.%d',versionArray(1),versionArray(2));
        header(1).VersionNumber = str2double(versionString);

        fprintf('RHD2000 header version %s\n',versionString);

        header(1).SampleRate = fread(fin,1,'single');
        header(1).IsDSPEnabled = logical(fread(fin,1,'int16'));
        header(1).DspHighPassCutoffActual = fread(fin,1,'single');
        header(1).AnalogHighPassCutoffActual = fread(fin,1,'single');
        header(1).AnalogLowPassCutoffActual = fread(fin,1,'single');
        header(1).DspHighPassCutoffDesired = fread(fin,1,'single');
        header(1).AnalogHighPassCutoffDesired = fread(fin,1,'single');
        header(1).AnalogLowPassCutoffDesired = fread(fin,1,'single');

        notchFilterMode = fread(fin,1,'int16');
        notchFilterEnabled = notchFilterMode > 0;
        header(1).NotchFilterFrequency = notchFilterEnabled*(40+10*notchFilterMode)/notchFilterEnabled; % NaN if mode == 0, 50 if mode == 1, 60 if mode == 2

        header(1).ImpedanceTestFrequencyDesired = fread(fin,1,'single');
        header(1).ImpedanceTestFrequencyActual = fread(fin,1,'single');

        header(1).Notes = arrayfun(@(~) readQString(fin),1:3,'UniformOutput',false);

        if header(1).VersionNumber >= 1.1
            header(1).NTemperatureSensors = fread(fin,1,'int16');
        end

        if header(1).VersionNumber >= 1.3
            header(1).BoardMode = fread(fin,1,'int16');
        end

        if header(1).VersionNumber >= 2.0
            error('I''m too lazy to write all this crap');
        end

        header(1).NSignalGroups = fread(fin,1,'int16');

        for ii = 1:header(1).NSignalGroups
            header(1).SignalGroups(ii) = readSignalGroup(fin);
        end

        if nargout < 2
            fclose(fin);
        end
    catch err
        fclose(fin);
        rethrow(err);
    end
end

function signalGroup = readSignalGroup(fin)
    signalGroup = struct([]);
    
    signalGroup(1).Name = readQString(fin);
    signalGroup(1).Prefix = readQString(fin);
    signalGroup(1).IsEnabled = logical(fread(fin,1,'int16'));
    signalGroup(1).NChannels = fread(fin,1,'int16');
    signalGroup(1).NAmplifierChannels = fread(fin,1,'int16');
    
    for ii = 1:signalGroup(1).NChannels
        signalGroup(1).Channels(ii) = readChannel(fin);
    end
end

function channel = readChannel(fin)
    channel = struct([]);
    
    channel(1).NativeName = readQString(fin);
    channel(1).CustomName = readQString(fin);
    channel(1).NativeOrder = fread(fin,1,'int16');
    channel(1).CustomOrder = fread(fin,1,'int16');
    channel(1).SignalType = fread(fin,1,'int16');
    channel(1).IsEnabled = logical(fread(fin,1,'int16'));
    channel(1).ChipChannel = fread(fin,1,'int16');
    channel(1).BoardStream = fread(fin,1,'int16');
    channel(1).IsSpikeScopeVoltageTriggered = logical(fread(fin,1,'int16'));
    channel(1).SpikeScopeVoltageThreshold = fread(fin,1,'int16');
    channel(1).SpikeScopeDigitalTriggerChannel = fread(fin,1,'int16');
    channel(1).IsSpikeScopeTriggeredOnRisingEdge = fread(fin,1,'int16');
    channel(1).ElectrodeImpedanceMagnitude = fread(fin,1,'single');
    channel(1).ElectrodeImpedancePhase = fread(fin,1,'single');
end

function a = readQString(fin)
    length = fread(fin,1,'uint32');
    nullLength = typecast(hex2num('ffffffff'),'uint32');
    
    if length == nullLength(2)
        a = '';
        return
    end
    
    length = length / 2; % convert length from bytes to 16-bit Unicode words
    
    a = fread(fin,[1 length],'uint16=>char');
end