function [timestamps,electrodeData,header,auxiliaryTimestamps,auxiliaryData,supplyTemperatureTimestamps,supplyData,temperatureData,usbAnalogData,usbDigitalData] = readRHDData(infile,outfile,isAppend)
    if nargin < 1
        infile = 'ABC_171012_175313.rhd';
    end
    
    N = 60; % for the evaluation board, others are 128. how to test?
    
    [header,fin] = readRHDHeader(infile);
    
    tic;
    
    try
        allChannels = [header.SignalGroups.Channels];
        isEnabled = [allChannels.IsEnabled];
        signalType = [allChannels.SignalType];

        nElectrodeChannels = sum(isEnabled & signalType == 0);
        nAuxiliaryChannels = sum(isEnabled & signalType == 1);
        nSupplyChannels = sum(isEnabled & signalType == 2);
        nUSBAnalogChannels = sum(isEnabled & signalType == 3);
        isAnyUSBDigitalChannelEnabled = any(isEnabled & signalType == 4);

        blockSizeBytes = N*4 ...
            + N*2*nElectrodeChannels ...
            + (N/4)*2*nAuxiliaryChannels ...
            + 2*nSupplyChannels ...
            + 2*header.NTemperatureSensors ...
            + N*2*nUSBAnalogChannels ...
            + N*2*isAnyUSBDigitalChannelEnabled;

        dataStart = ftell(fin);

        fseek(fin,0,1);

        dataEnd = ftell(fin);

        dataSizeBytes = dataEnd-dataStart;

        nBlocks = ceil(dataSizeBytes/blockSizeBytes);
        nSamples = N*nBlocks;

        fseek(fin,dataStart,-1);

        timestamps = zeros(nSamples,1);
        electrodeData = zeros(nSamples,nElectrodeChannels);
        auxiliaryData = zeros(nSamples,nAuxiliaryChannels);
        supplyData = zeros(nBlocks,nSupplyChannels);
        temperatureData = zeros(nBlocks,header.NTemperatureSensors);
        usbAnalogData = zeros(nSamples,nUSBAnalogChannels);
        usbDigitalData = false(nSamples,16*isAnyUSBDigitalChannelEnabled);
        
        isWarned = false;
        
        isWrite = nargin > 1 && ischar(outfile);
            
        if isWrite
            
            if exist(outfile,'file') && (nargin < 3 || all(logical(isAppend(:))))
                permission = 'a';
            else
                permission = 'w';
            end
            
            fout = fopen(outfile,permission);
        end

        for ii = 1:nBlocks
            tic;
            blockStart = ftell(fin);
            
            timestamps(((ii-1)*N+1):(ii*N)) = fread(fin,[N 1],'int32')/header.SampleRate;
            rawElectrodeData = fread(fin,[N nElectrodeChannels],'uint16');
            electrodeData(((ii-1)*N+1):(ii*N),:) = double(rawElectrodeData-32768)*0.195;
            auxiliaryData(((ii-1)*(N/4)+1):(ii*N/4),:) = fread(fin,[N/4 nAuxiliaryChannels],'uint16=>double')*0.0000374;
            supplyData(ii,:) = fread(fin,[1 nSupplyChannels],'uint16=>double')*0.0000748;
            temperatureData(ii,:) = fread(fin,[1 header.NTemperatureSensors],'uint16=>double')/100;
            
            usbAnalogDataBlock = fread(fin,[N nUSBAnalogChannels],'uint16');
            
            switch header.BoardMode
                case 0
                    usbAnalogDataBlock = double(usbAnalogDataBlock)*0.000050354;
                case 1
                    usbAnalogDataBlock = double(usbAnalogDataBlock-32768)*0.00015259;
                case 13
                    usbAnalogDataBlock = double(usbAnalogDataBlock-32768)*0.0003125;
                otherwise
                    if ~isWarned
                        isWarned = true;
                        warning('Unsupported board mode %d, USB Analog Input Data will be unscaled.\n',header.BoardMode);
                    end
            end
            
            usbAnalogData(((ii-1)*N+1):(ii*N),:) = usbAnalogDataBlock;
            
            if isAnyUSBDigitalChannelEnabled
                usbDigitalData(((ii-1)*N+1):(ii*N),:) = dec2bin(fread(fin,[N 1],'uint16'),16) == '1';
            end
            
            blockEnd = ftell(fin);
            
            assert(blockEnd - blockStart == blockSizeBytes,'Something has gone very, very wrong');
            
            if isWrite
                fwrite(fout,rawElectrodeData','uint16'); % klustakwik files are channel-major
            end
            
            toc;
        end
        
        fclose(fin);

        auxiliaryTimestamps = timestamps(4:4:end);
        supplyTemperatureTimestamps = timestamps(N:N:end);
    catch err
        toc;
        fclose(fin);
        rethrow(err);
    end
end