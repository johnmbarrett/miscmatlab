function [values, isTriggered, isCameraTriggered, isDelaying, isFlashing, params, paramIndices] = parseORSDataFile(filename,chunkSize)
    if nargin < 2
        chunkSize = 2^19; % seems to be the fastest on my laptop according to some quick tests
    end
    
    fin = fopen(filename, 'r');
    closeFile = onCleanup(@() fclose(fin));
    
    magicBytes = fread(fin,[1 4],'char=>char');
    
    if numel(magicBytes) ~= 4 || ~strcmp(magicBytes,'ORS!')
        fseek(fin, 0, -1);
        [values, isTriggered, isCameraTriggered, isDelaying, isFlashing, params, paramIndices] = parseORSTextDataFile(fin, filename);
        return
    end

    [values, isTriggered, isCameraTriggered, isDelaying, isFlashing, params, paramIndices] = parseORSBinaryDataFile(fin, chunkSize);
end

function [values, isTriggered, isCameraTriggered, isDelaying, isFlashing, params, paramIndices] = parseORSBinaryDataFile(fin, chunkSize)
    fseek(fin, 0, 1);
    
    nBytes = ftell(fin);
    
    fseek(fin, 4, -1);
    
    % these may be used for something eventually
    majorVersion = fread(fin, 1, 'uint16=>double');
    minorVersion = fread(fin, 1, 'uint16=>double');
    fprintf('Reading ORS Data File (format version %d.%d)...\n', majorVersion, minorVersion);
    
    headerBytes = fread(fin, 1, 'uint8=>double');
    statusBytes = fread(fin, 1, 'uint8=>double');
    dataBytes = fread(fin, 1, 'uint8=>double');
    paramBytes = fread(fin, 1, 'uint8=>double');
    preambleBytes = fread(fin, 1, 'uint8=>double');
    
    fseek(fin, headerBytes, -1);
    
    preamble = fread(fin, [preambleBytes 1], 'uint8=>uint8');
    
    assert(ftell(fin) == headerBytes+preambleBytes, 'Should be at the start of the data frame now');
    
    sampleCounter = 0;
    sampleByteCounter = 0;
    preambleCounter = 0;
    paramCounter = 0;
    paramByteCounter = 0;
    
    maxSamples = ceil(nBytes/(statusBytes + dataBytes));
    maxParams = ceil(nBytes/(preambleBytes + paramBytes));
    
    params = struct(    ...
        'isCamEnabled',         cell(maxParams,1),  ...
        'isLEDEnabled',                 [],                 ...
        'isLEDYokedToCamera',           [],                 ...
        'thresholdPolarity',            [],                 ...
        'camPeriod',                    [],                 ...
        'ledDelay',                     [],                 ...
        'ledDuration',                  [],                 ...
        'ledPeriod',                    [],                 ...
        'startThreshold',               [],                 ...
        'stopThreshold',                [],                 ...
        'deadTime',                     [],                 ...
        'ledIPI',                       [],                 ...
        'ledNPulses',                   [],                  ...
        'isConstantCameraFrameRate',    []                  ...
        );
    
    paramIndices = zeros(maxParams,1);
    
    values = zeros(maxSamples,1);
    isTriggered = zeros(maxSamples,1);
    isCameraTriggered = zeros(maxSamples,1);
    isDelaying = zeros(maxSamples,1);
    isFlashing = zeros(maxSamples,1);
    
    progressLogFormatString = sprintf('Read up to data byte %%0%dd of %%d in %%f seconds\\n', floor(log(nBytes)/log(10))+1);
    
    assert(dataBytes <= 8, 'Data samples must have a maximum of 64 bit precision');
    
    dataPrecision = sprintf('uint%d', dataBytes*8);
    
    start = tic;
    tic; % for the first call to toc
    
    theBytes = fread(fin, chunkSize, 'uint8=>uint8');
    currentPos = ftell(fin);
    nextSample = 0;
    
    while numel(theBytes) > 0 % feof only becomes true if you read *past* the end of the file, not if you read *up to* the end of the file
        fprintf(progressLogFormatString, currentPos-headerBytes-preambleBytes, nBytes-headerBytes-preambleBytes, toc);
        
        tic;
        
        for ii = 1:numel(theBytes)
            nextByte = theBytes(ii);
            
            if sampleByteCounter == 0 && preambleCounter == 0 && nextByte == preamble(1)
                preambleCounter = 1;
                nextSample = [nextByte; uint8(zeros(statusBytes+dataBytes-1,1))];
                continue;
            end
                
            if preambleCounter > 0 && preambleCounter < preambleBytes
                % in version <=1.2 this should never happen, but check it 
                % was actually the start of the preamble for future safety
                if nextByte ~= preamble(preambleCounter+1)
                    sampleByteCounter = preambleCounter + 1;
                    nextSample(sampleByteCounter) = nextByte; %#ok<AGROW>
                    preambleCounter = 0;
                    continue;
                else
                    preambleCounter = preambleCounter + 1;
                    nextSample(preambleCounter) = nextByte; %#ok<AGROW>
                    continue;
                end
            end
            
            if preambleCounter == preambleBytes
                if paramByteCounter == 0
                    paramCounter = paramCounter + 1;
                    rawParams = uint8(zeros(paramBytes,1));
                end
                    
                paramByteCounter = paramByteCounter + 1;
                rawParams(paramByteCounter) = nextByte;
                
                if paramByteCounter == paramBytes
                    params(paramCounter).isCamEnabled = logical(rawParams(1));
                    params(paramCounter).isLEDEnabled = logical(rawParams(2));
                    params(paramCounter).isLEDYokedToCamera = logical(rawParams(3));
                    params(paramCounter).thresholdPolarity = logical(rawParams(4));
                    params(paramCounter).camPeriod = double(typecast(rawParams(5:6),'uint16'));
                    params(paramCounter).ledDelay = double(typecast(rawParams(7:8),'uint16'));
                    params(paramCounter).ledDuration = double(typecast(rawParams(9:10),'uint16'));
                    params(paramCounter).ledPeriod = double(typecast(rawParams(11:12),'uint16'));
                    params(paramCounter).startThreshold = double(typecast(rawParams(13:14),'uint16'));
                    params(paramCounter).stopThreshold = double(typecast(rawParams(15:16),'uint16'));
                    params(paramCounter).deadTime = double(typecast(rawParams(17:18),'uint16'));

                    if majorVersion > 1 || minorVersion > 0
                        params(paramCounter).ledIPI = double(typecast(rawParams(19:20),'uint16'));
                        params(paramCounter).ledNPulses = double(typecast(rawParams(21:22),'uint16'));
                    end
                    
                    if majorVersion > 1 || minorVersion > 1
                        params(paramCounter).isConstantCameraFrameRate = logical(rawParams(23));
                    end

                    paramIndices(paramCounter) = sampleCounter;
                    preambleCounter = 0;
                    paramByteCounter = 0;
                end
                
                continue;
            end

            if sampleByteCounter == 0
                nextSample = uint8(zeros(statusBytes+dataBytes,1));
            end
            
            sampleByteCounter = sampleByteCounter + 1;
            nextSample(sampleByteCounter) = nextByte; %#ok<AGROW>
            
            if sampleByteCounter == statusBytes+dataBytes
                sampleCounter = sampleCounter + 1;

                isTriggered(sampleCounter) = logical(bitand(nextSample(1), 1));
                isCameraTriggered(sampleCounter) = logical(bitand(nextSample(1), 2));
                isDelaying(sampleCounter) = logical(bitand(nextSample(1), 4));
                isFlashing(sampleCounter) = logical(bitand(nextSample(1), 8));

                values(sampleCounter) = double(typecast(nextSample(statusBytes+1:end), dataPrecision));
                
                sampleByteCounter = 0;
            end
        end
        
        theBytes = fread(fin, chunkSize, 'uint8=>uint8');
        currentPos = ftell(fin);
    end
    
    fprintf('Parsed ORS Data File in %f seconds\n', toc(start));
    
    params(paramCounter+1:end) = [];
    paramIndices(paramCounter+1:end) = [];
    
    values(sampleCounter+1:end) = [];
    values = 5*values/1023;
    
    isTriggered(sampleCounter+1:end) = [];
    isCameraTriggered(sampleCounter+1:end) = [];
    isDelaying(sampleCounter+1:end) = [];
    isFlashing(sampleCounter+1:end) = [];
end

function [values, isTriggered, isCameraTriggered, isDelaying, isFlashing, params, paramIndices] = parseORSTextDataFile(fin, filename)
    tic;
    if isunix %# Linux, mac
        [~, result] = system(['wc -l', filename]);
        nLines = str2double(result);
    elseif ispc %# Windows
        nLines = str2double(perl('countlines.pl', filename));
    else
        error('...');
    end
    toc;
    
    disp(nLines);
    
    dataLines = cell(nLines,5);
    nDataLines = 0;
    
    paramLines = cell(nLines,11);
    paramIndices = zeros(nLines,1);
    nParamLines = 0;
    
    paramRegex = 'P\t(.+)\t(.+)\t(.+)\t(.+)\t(.+)\t(.+)\t(.+)\t(.+)\t(.+)\t(.+)\t(.+)';
    dataRegex = '([^P]+)\t(.+)\t(.+)\t(.+)\t(.+)';
    progressLogFormatString = sprintf('Parsed line %%0%dd of %%d in %%f seconds\\n', floor(log(nLines)/log(10))+1);
    
    tic;
    for ii = 1:nLines
        line = fgetl(fin);
        
        if line(1) == 'P'
            nParamLines = nParamLines+1;
            paramIndices(nParamLines) = nDataLines;
            tokens = regexp(line, paramRegex, 'tokens');
            paramLines(nParamLines,:) = tokens{1};
        else
            nDataLines = nDataLines + 1;
            tokens = regexp(line, dataRegex, 'tokens');
            dataLines(nDataLines,:) = tokens{1};
        end
        
        fprintf(progressLogFormatString, ii, nLines, toc);
        tic;
    end
    
    paramLines(nParamLines+1:end,:) = [];
    paramIndices(nParamLines+1:end,:) = [];
    dataLines(nDataLines+1:end,:) = [];
    
    convertBool = @(s) strcmp(s,'True');
    convertPolarity = @(s) strcmp(s,'ThresholdPolarity.POSITIVE');
    
    tic;
    params = struct(    ...
        'isCamEnabled',         cellfun(convertBool, paramLines(:,1), 'UniformOutput', false),      ...
        'isLEDEnabled',         cellfun(convertBool, paramLines(:,2), 'UniformOutput', false),      ...
        'isLEDYokedToCamera',   cellfun(convertBool, paramLines(:,3), 'UniformOutput', false),      ...
        'thresholdPolarity',    cellfun(convertPolarity, paramLines(:,4), 'UniformOutput', false),  ...
        'camPeriod',            num2cell(str2double(paramLines(:,5))),                              ...
        'ledDelay',             num2cell(str2double(paramLines(:,6))),                              ...
        'ledDuration',          num2cell(str2double(paramLines(:,7))),                              ...
        'ledPeriod',            num2cell(str2double(paramLines(:,8))),                              ...
        'startThreshold',       num2cell(str2double(paramLines(:,9))),                              ...
        'stopThreshold',        num2cell(str2double(paramLines(:,10))),                             ...
        'deadTime',             num2cell(str2double(paramLines(:,11)))                              ...
        );
    fprintf('Converted parameter lines to Matlab types in %f seconds\n', toc);
    
    values = str2double(dataLines(:,1));
    isTriggered = cellfun(convertBool, dataLines(:,2));
    isCameraTriggered = cellfun(convertBool, dataLines(:,3));
    isDelaying = cellfun(convertBool, dataLines(:,4));
    isFlashing = cellfun(convertBool, dataLines(:,5));
    fprintf('Converted data lines to Matlab types in %f seconds\n', toc);
end