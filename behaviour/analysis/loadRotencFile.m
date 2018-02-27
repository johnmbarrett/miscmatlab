function [timestamps,angle,state,threshold,successIndices,successTimes,learningCurve,phase,cuePeriod,cumulativeRewards,cumulativeSuccesses,cumulativeFailures,totalRewards] = loadRotencFile(filename,nColumns, isNoPlot)
    [~,~,ext] = fileparts(filename);
    
    if nargin < 2
        nColumns = NaN;
    end
    
    if (nargin > 1 && strcmp(nColumns,'bin')) || any(strcmpi(ext,{'.bin' '.dat'}))
        nColumns = 10;
        A = loadRotencBinaryFile(filename);
    else
        [A,nColumns] = loadRotencTextFile(filename,nColumns);
    end
    
    if isempty(A)
        t0 = zeros(0,1);
    else
        t0 = A(1,1);
    end
    
    timestamps = (A(:,1)-t0);
    
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
    
    angle = 360*A(:,2)/4096;
    state = A(:,3);
    threshold = 360*A(:,4+(nColumns>4))/4096;
    
    if nColumns == 4
        successIndices = find(diff(state) == 1);
        phase = zeros(numel(timestamps),1); % can't be nan because otherwise unique(phase) doesn't work
        cuePeriod = nan(numel(timestamps),1);
        cumulativeRewards = nan(numel(timestamps),1);
        cumulativeSuccesses = nan(numel(timestamps),1);
        cumulativeFailures = nan(numel(timestamps),1);
        totalRewards = nan(numel(timestamps),1);
    elseif nColumns >= 9
        successIndices = find(state(1:end-1) == 1 & state(2:end) == 2);
        phase = A(:,4);
        cuePeriod = A(:,6);
        cumulativeRewards = A(:,7);
        cumulativeSuccesses = A(:,8);
        cumulativeFailures = A(:,9);
        
        if nColumns >= 10
            totalRewards = A(:,10);
        else
            totalRewards = nan(numel(timestamps),1);
        end
    else
        error('dsfkjfdgkjdsgkjsfdgjgf');
    end
    
    successTimes = timestamps(successIndices);
    learningCurve = cumsum(ones(size(successIndices)));
    
    [~,filePrefix] = fileparts(filename);
    saveFile = sprintf('%s_learning_curve',filePrefix);
    save([saveFile '.mat'],'timestamps','angle','state','threshold','successIndices','successTimes','learningCurve','phase','cuePeriod','cumulativeRewards','cumulativeSuccesses','cumulativeFailures','totalRewards');
    
    if nargin < 3 || isNoPlot
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

function A = loadRotencBinaryFile(filename)
    fin = fopen(filename);
    
    fseek(fin,0,1);
    
    nBytes = ftell(fin);
    structSize = 32;
    nRows = nBytes/structSize;
    
    fseek(fin,0,-1);
    
    B = fread(fin,[structSize nRows],'uint8=>uint8');
    
    bytes = [4 4 1 1 4 4 2 2 2 2];
    unsigned = [1 0 0 0 0 1 1 1 1 1];
    
    cumBytes = [0 cumsum(bytes)];
    
    A = zeros(nRows,10);
    
    for ii = 1:10
        type = sprintf('%sint%d',repmat('u',1,unsigned(ii)),8*bytes(ii));
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