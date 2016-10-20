function header = parseQCamHeader(file)
    if ischar(file)
        fin = fopen(file);
        cleanup = onCleanup(@() fclose(fin));
    else
        fin = file;
        oldPos = ftell(fin);
        cleanup = onCleanup(@() fseek(fin,oldPos,-1));
    end
    
    fseek(fin,0,-1);
    
    headerText = fread(fin,[1 512],'char=>char');
    
    fields = struct(    ...
        'name', {'Encoding-Version', 'Fixed-Header-Size', 'ROI', 'Frame-Size', 'Image-Encoding', 'Image-Format', 'Bytes-Per-Pixel', 'Temporal-Averaging', 'Exposure', 'Spatial-Binning', 'High-Sensitivity-Mode', 'Normalized-Gain', 'Absolute-Offset', 'File-Init-Timestamp', 'Header-Creation-Timestamp', 'User-Timing-Data', 'User-Defined-Header'}, ...
        'type', {'float', 'int', 'intvec', 'int', 'char', 'char', 'int', 'int', {'[0-9]+', @parseExposure}, {'[0-9x]+', @parseSpatialBinning}, 'logical', 'int', 'int', 'date', 'date', 'char', 'char'}  ...
        );
    
    header = struct([]);
    
    for ii = 1:numel(fields)
        field = fields(ii);
        
        if iscell(field.type)
            tokenRegexp = field.type{1};
            parseFun = field.type{2};
        else
            switch field.type
                case 'char'
                    tokenRegexp = '[^\[\r\n]+';
                    parseFun = @parseChar;
                case 'date'
                    tokenRegexp = '[0-9\-_:]+';
                    parseFun = @parseDate;
                case 'float'
                    tokenRegexp = '[0-9\.]+';
                    parseFun = @parseFloat;
                case 'int'
                    tokenRegexp = '[0-9]+';
                    parseFun = @parseInt;
                case 'intvec'
                    tokenRegexp = '[0-9, ]+';
                    parseFun = @parseIntVec;
                case 'logical'
                    tokenRegexp = '[^\[\r\n]+';
                    parseFun = @parseLogical;
                otherwise
                    tokenRegexp = '[^\[\r\n]+';
                    parseFun = @parseChar;
            end
        end
        
        regex = sprintf('%s: (%s)',field.name,tokenRegexp);
        
        token = regexp(headerText,regex,'tokens');
        
        fieldName = strrep(field.name,'-','');
        
        if isempty(token)
            header(1).(fieldName) = [];
            continue
        end
        
        header(1).(fieldName) = parseFun(token{1}{1});
    end
end
   
function s = parseChar(s)
    % the best function
end

function d = parseDate(s)
    try
        d = textscan(s,'%{MM-dd-uuuu_HH:mm:ss}D');
    catch
        s = strsplit(s,'_');
        d = textscan(s{1},'%{MM-dd-uuuu}D');
    end
    
    d = d{1};
end

function f = parseFloat(s)
    f = str2double(s);
end

function i = parseInt(s)
    i = str2double(s);
end

function v = parseIntVec(s)
    v = cellfun(@str2double,strsplit(s,', '));
end

function b = parseLogical(s)
    b = strncmp(s,'On',2);
end

function e = parseExposure(s)
    e = str2double(s)/1e9; % TODO : read unit as well
end

function b = parseSpatialBinning(s)
    b = cellfun(@str2double,strsplit(s,'x'));
end