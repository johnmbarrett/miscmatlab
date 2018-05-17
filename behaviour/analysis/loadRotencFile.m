function [timestamps,angle,state,threshold,successIndices,successTimes,learningCurve,phase,cuePeriod,cumulativeRewards,cumulativeSuccesses,cumulativeFailures,totalRewards,lickometer] = loadRotencFile(filename,nColumns,varargin) % TODO : better control over output arguments
    [~,~,ext] = fileparts(filename);
    
    if nargin >= 2
        if isnumeric(nColumns) % backwards compatibility
            if ~any(cellfun(@(s) ischar(s) && strcmp(s,'Columns'),varargin))
                varargin = [{'Columns' nColumns} varargin];
            else
                warning('Old-style nColumns argument provided along with new-style name-value pair arguments, nColumns will be ignored');
            end
        elseif ischar(nColumns)
            varargin = [{nColumns} varargin];
        else
            error('I don''t understand what is happening any more.');
        end
    end
    
    parser = inputParser;
    addParameter(parser,'Columns',10,@(x) (isnumeric(x) && isscalar(x) && isfinite(x) && round(x) == x && x > 0 && x < 11) || iscellstr(x));
    addParameter(parser,'Format','unspecified',@(x) ischar(x) && any(strncmpi(x,{'b' 't'},1)));
    addParameter(parser,'PlotData',false,@(x) islogical(x) && isscalar(x));
    addParameter(parser,'StructSize',32,@(x) (isnumeric(x) && isscalar(x) && isfinite(x) && round(x) == x && x > 0));
    addParameter(parser,'StructFormat',[4 4 1 1 4 4 2 2 2 2],@(x) isnumeric(x) && isvector(x) && all(ismember(x,[1 2 4 8])));
    addParameter(parser,'StructIsUnsigned',[true false(1,4) true(1,5)],@(x) islogical(x) && isvector(x));
    addParameter(parser,'SuccessStates',2,@(x) (isnumeric(x) && isvector(x) && all(isfinite(x) & x >= 0))); % TODO : this should even really be here
    
    parser.parse(varargin{:});
    
    columns = parser.Results.Columns;
    
    defaultColumns = {'timestamps' 'angle' 'state' 'phase' 'threshold' 'cuePeriod' 'cumulativeRewards' 'cumulativeSuccesses' 'cumulativeFailures' 'totalRewards'};
    
    if isnumeric(columns)
        switch columns
            case 4
                columns = defaultColumns([1:3 5]);
            case 9
                columns = defaultColumns([1:3 5:end]);
            otherwise
                columns = defaultColumns(1:columns);
        end
    end
    
    nColumns = numel(columns);
    
    if strncmpi(parser.Results.Format,'b',1) || any(strcmpi(ext,{'.bin' '.dat'}))
        A = loadRotencBinaryFile(filename,parser.Results.StructSize,parser.Results.StructFormat,parser.Results.StructIsUnsigned);
    else
        [A,nColumns] = loadRotencTextFile(filename,nColumns);
        
        columns = columns(1:nColumns);
    end
    
    if isempty(A)
        t0 = zeros(0,1);
    else
        t0 = A(1,1);
    end
    
    % TODO : tidy this up a bit, also error checking
    timestamps = (A(:,strcmp(columns,'timestamps'))-t0);
    
%     [timestamps,uniqueIndices] = unique(timestamps);
    if timestamps(end) < timestamps(end-1) % probably a corrupted sample
        warning('Last line of %s may be corrupted, dropping last sample',filename);
        timestamps(end) = [];
        A(end,:) = [];
    end
    
    possibleOverflows = find(nextpow2(timestamps(2:end)) < 32 & nextpow2(timestamps(1:end-1)) == 32)+1;
    
    for ii = 1:numel(possibleOverflows)
        timestamps(possibleOverflows(ii):end) = timestamps(possibleOverflows(ii):end)+2^32;
    end
    
    if ~issorted(timestamps)
        warning('File %s may be corrupted, please check',filename);
    end
    
    timestamps = timestamps/1e6;
    
    angle = 360*A(:,strcmp(columns,'angle'))/4096;
    state = A(:,strcmp(columns,'state'));
    threshold = 360*A(:,strcmp(columns,'threshold'))/4096;
    
    if isnumeric(parser.Results.Columns) && nColumns == 4 % TODO : I really should have put a header with a version number
        successIndices = find(diff(state) == 1);
        phase = zeros(numel(timestamps),1); % can't be nan because otherwise unique(phase) doesn't work
        cuePeriod = nan(numel(timestamps),1);
        cumulativeRewards = nan(numel(timestamps),1);
        cumulativeSuccesses = nan(numel(timestamps),1);
        cumulativeFailures = nan(numel(timestamps),1);
        totalRewards = nan(numel(timestamps),1);
        lickometer = nan(numel(timestamps),1);
    else %if nColumns >= 9
        successIndices = find(~ismember(state(1:end-1),parser.Results.SuccessStates) & ismember(state(2:end),parser.Results.SuccessStates));
        phase = A(:,strcmp(columns,'phase'));
        cuePeriod = A(:,strcmp(columns,'cuePeriod'));
        cumulativeRewards = A(:,strcmp(columns,'cumulativeRewards'));
        cumulativeSuccesses = A(:,strcmp(columns,'cumulativeSuccesses'));
        cumulativeFailures = A(:,strcmp(columns,'cumulativeFailures'));
        totalRewards = A(:,strcmp(columns,'totalRewards'));
        lickometer = A(:,strcmp(columns,'lickometer'));
    end
    
    successTimes = timestamps(successIndices);
    learningCurve = cumsum(ones(size(successIndices)));
    
    [~,filePrefix] = fileparts(filename);
    saveFile = sprintf('%s_learning_curve',filePrefix);
    save([saveFile '.mat'],'timestamps','angle','state','threshold','successIndices','successTimes','learningCurve','phase','cuePeriod','cumulativeRewards','cumulativeSuccesses','cumulativeFailures','totalRewards');
    
    if ~parser.Results.PlotData
        return
    end
       
    figure
    subplot(1,2,1);
    plot(timestamps,angle,timestamps,threshold);
    hold on;
    
    line(repmat(timestamps(successIndices),1,2)',repmat(ylim',1,numel(successIndices)),'Color','k','LineStyle','--');
    xlabel('Time (s)');
    ylabel('Angle (degrees)');
    legend({'Wheel' 'Threshold'},'Location','Best');
    subplot(1,2,2);
    plot(successTimes,learningCurve);
    xlabel('Time (s)');
    ylabel('# Rewards');
    
    saveas(gcf,saveFile,'fig');
    close(gcf);
end

function A = loadRotencBinaryFile(filename,structSize,structFormat,isUnsigned)
    fin = fopen(filename);
    
    fseek(fin,0,1);
    
    nBytes = ftell(fin);
    nRows = floor(nBytes/structSize);
    
    if nRows*structSize ~= nBytes
        warning('structSize does not exactly divide number of bytes.  File may be corrupted.');
    end
    
    fseek(fin,0,-1);
    
    B = fread(fin,[structSize nRows],'uint8=>uint8');
    
    cumBytes = [0 cumsum(structFormat)];
    
    A = zeros(nRows,10);
    
    for ii = 1:numel(structFormat)
        type = sprintf('%sint%d',repmat('u',1,isUnsigned(ii)),8*structFormat(ii));
        column = reshape(B((cumBytes(ii)+1):cumBytes(ii+1),:),[],1);
        column = typecast(column,type);
        A(:,ii) = double(column);
    end
    
    dt = abs(diff(A(:,2))./diff(A(:,1)));
    bad = dt > 4096/1e3; % greater than one full turn per millisecond is obviously a glitch
    
    if ~any(bad)
        return
    end
    
    warning('Possible glitches detected in file %s - smallest unsavory dtheta/dt was %f. Interpolating corresponding theta values where dtheta/dt is not less than this.',filename,max(dt(bad)));
    
    bad = find(bad)+1;
    bad = bad(1:2:end); % assuming glitches don't happen on successive samples, there will always be two bad values, one where it first when wrong and one where it went back to baseline, so always take the first of each pair
    notBad = setdiff(1:nRows,bad);
    
    A(bad,2) = interp1(A(notBad,1),A(notBad,2),A(bad,1),'pchip');
end

function [A,nColumns] = loadRotencTextFile(filename,nColumns)
    fin = fopen(filename);
    delimiters = {',' '\t'};
    
    if ~isnumeric(nColumns) || ~isscalar(nColumns) || isnan(nColumns)
        s = fgetl(fin);
        
        while s(1) == '='
            s = fgetl(fin);
        end
        
        s = fgetl(fin); % skip the first non-comment line in case it's wrong
        
        if ~ischar(s)
            warning('ugggggggggggggggggggggggggggggggggh');
            nColumns = 10;
        else
            nColumns = numel(strsplit(s,delimiters));
        end
        
        fseek(fin,0,-1);
    end
    
%     A = zeros(0,nColumns);
%     
%     while ~feof(fin)
%         tic;
%         s = fgetl(fin);
%         
%         
%         
%         if s(1) == '='
%             continue
%         end
%         
%         s = strsplit(s,delimiters);
%         
%         if numel(s) ~= nColumns || any(cellfun(@isempty,s))
%             toc;
%             continue
%         end
%         
%         A(end+1,:) = str2double(s); %#ok<AGROW>
%         toc;
%     end
%     
%     fclose(fin);
%     
%     return
    
    A = textscan(fin,strjoin(repmat({'%f'},1,nColumns),'\t'),'CommentStyle','=','Delimiter',delimiters); 
    
    nLines = cellfun(@numel,A);

    if std(nLines) ~= 0
        minLines = min(nLines);
        maxLines = max(nLines);

        assert(maxLines == minLines + 1,'File corrupted, please inspect manually.');

        fseek(fin,0,-1);

        firstLine = '=';
        
        while isempty(firstLine) || firstLine(1) == '='
            firstLine = fgetl(fin);
        end
        
        secondLine = fgetl(fin);
        badColumns = find(nLines == maxLines);

        isFirstLineRight = numel(strsplit(firstLine,delimiters)) == numel(strsplit(secondLine,delimiters));

        for ii = badColumns
            if isFirstLineRight
                A{ii} = A{ii}(1:end-1,:);
            else
                A{ii} = A{ii}(2:end,:);
            end
        end
    end
    
    fclose(fin);
    
    A = double([A{:}]);
end