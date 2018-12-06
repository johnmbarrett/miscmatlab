dirs = datetime({    ...
%     '20180521'  ...
%     '20180522'  ...
%     '20180523'  ...
%     '20180524'  ...
%     '20180525'  ...
%     '20180528'  ...
%     '20180529'  ...    '20180530'  ...
%     '20180531'  ...
%     '20180625'  ...
%     '20180626'  ...
% 4 wild types -- first successful replication
%     '20180702'  ...
%     '20180703'  ...
%     '20180704'  ...
%     '20180705'  ...
%     '20180706'  ...
%     '20180709'  ...
%     '20180710'  ...
%     '20180711'  ...
%     '20180712'  ...
%     '20180713'  ...
% bi fl-M1 PSAM/PSEM round 1
    '20180806'  ...
    '20180807'  ...
    '20180808'  ...
    '20180809'  ...
    '20180810'  ...
    '20180813'  ...
    '20180814'  ...
    '20180815'  ...
    '20180816'  ...
    '20180817'  ...
    '20180820'  ... end of round 1/beginning of round 2
    '20180821'  ... 
    '20180822'  ... 
    '20180823'  ... 
    '20180824'  ... 
    },'InputFormat','yyyyMMdd','TimeZone','America/Chicago');

nDirs = numel(dirs);

% treatment = cat(3,zeros(5,2,100000),[0 1; 0 1; 1 0; 0 1; 1 0],[1 0; 1 0; 0 1; 1 0; 0 1],zeros(5,2));
treatment = cat(3,repmat([1;0;1;0;0;0;0;0],1,2,5),[0 0; 1 0; 0 0; 0 1; zeros(4,2)],[0 0; 0 1; 0 0; 1 0; zeros(4,2)],[0 0; 1 0; 0 0; 0 1; zeros(4,2)],[0 0; 0 1; 0 0; 1 0; zeros(4,2)],[0 0; 0 1; 0 0; 1 0; zeros(4,2)],[1 0; 0 0; 0 1; 0 0; 0 0; 1 1; 1 1; 0 0],[0 1; 0 0; 1 0; 0 0; 0 0; 1 1; 1 1; 0 0],[1 0; 0 0; 0 1; 0 0; 0 0; 1 1; 1 1; 0 0],[0 1; 0 0; 1 0; 0 0; 0 0; 1 1; 1 1; 0 0],[1 0; 0 0; 0 1; 0 0; 0 0; 1 1; 1 1; 0 0]);
uniqueTreatments = unique(treatment);
nTreatments = numel(uniqueTreatments);

allDates = dirs(1):dirs(end);
allMice = {};
maxSessions = 0;
allFiles = cell(0,5);

topDir = 'Z:\LACIE\DATA\John\Videos\Behaviour\';

getNames = @(S) arrayfun(@(s) s.name,S,'UniformOutput',false);

for ii = 1:nDirs
    dayDir = [topDir datestr(dirs(ii),'yyyymmdd');];
    cd(dayDir);
    
    cages = dir;
    cages = cages([cages.isdir] & ~strncmp({cages.name},'.',1));
    nCages = numel(cages);
    
%     allCages = union(allCages,{cages.name});
    
    for jj = 1:numel(cages)
        cd([dayDir '\' cages(jj).name]);
        
        files = union(getNames(dir('*.BIN')),getNames(dir('*.txt')));
        files = files(~strcmp('notes.txt',files));
        nFiles = numel(files);
        
        for kk = 1:nFiles
            tokens = regexp(files{kk},'(.+)_session_([0-9]+)','tokens');
            mouse = tokens{1}{1};
            session = str2double(tokens{1}{2});
            
            allMice = union(allMice,sprintf('Cage %s mouse %s',cages(jj).name,mouse));
            maxSessions = max(maxSessions,session);
            
            allFiles(end+1,:) = {files{kk} dirs(ii) cages(jj).name mouse session}; %#ok<SAGROW>
        end
    end
end
%%
fuckYouMatlab = cell(size(allFiles,1),1);

for ii = 1:numel(fuckYouMatlab)
    fuckYouMatlab{ii} = [datestr(allFiles{ii,2}) ' ' allFiles{ii,3} ' ' allFiles{ii,4} ' ' num2str(allFiles{ii,5})];
end

[uniqueSessions,~,sessionIndices] = unique(fuckYouMatlab);
[~,~,extensions] = cellfun(@fileparts,allFiles(:,1),'UniformOutput',false);
isBinary = contains(extensions,'BIN');
goodIndices = find(isBinary);
goodIndices = union(goodIndices,find(ismember(sessionIndices,setdiff(1:numel(uniqueSessions),sessionIndices(goodIndices)))));
assert(isequal(uniqueSessions(sessionIndices(goodIndices)),uniqueSessions));
allFiles = allFiles(goodIndices,:);

if maxSessions ~= size(treatment,2)
    warning('check treatment');
end

%%

fields = {'nTrials' 'nResponses' 'responseRate' 'responsesPerHour' 'reactionTime' 'totalReaches' 'appropriateReaches' 'inVainReaches'};
nFields = numel(fields);

structInitialiser = cell(1,2*nFields);
structInitialiser(1:2:end) = fields;

nDates = numel(allDates);
nMice = numel(allMice);
structInitialiser(2:2:end) = repmat({num2cell(nan(nMice,maxSessions,nDates,nTreatments))},1,nFields);

performance = struct(structInitialiser{:},'isResponded',cell(nMice,maxSessions,nDates,nTreatments),'reachISIs',cell(nMice,maxSessions,nDates,nTreatments));
        
%%

hs = gobjects(5,1);

for nn = 1:size(allFiles,1)
    tic;
    filename = sprintf('%s\\%s\\%s\\%s',topDir,datestr(allFiles{nn,2},'yyyymmdd'),allFiles{nn,3},allFiles{nn,1});
    [~,~,extension] = fileparts(allFiles{nn,1});
    
    switch extension
        case '.BIN'
%             [timestamps,licks,responses,distance,state] = loadStructArrayFile(filename,12,[4 2 2 2 1 1],[true(1,3) false(1,3)]);
            [timestamps,~,licks,responses,distance,state] = loadStructArrayFile(filename,16,[4 4 2 2 2 1 1],[true(1,4) false(1,3)]);
            timestamps = (timestamps-timestamps(1))/1e6;
        case '.txt'
            [timestamps,~,state,~,successIndices,successTimes,learningCurve,phase,~,~,~,~,responses,licks] = loadRotencFile(filename,'Columns',{'timestamps' 'state' 'lickometer' 'totalRewards' 'phase' 'threshold'}); % TODO : really need to move away from loadRotencFile for this
        otherwise
            error('Well this is unexpected.');
    end

    witholdingStarts = [1; find(state(1:end-1) ~= 1 & state(2:end) == 1)+1];
    availableStarts = find(state(1:end-1) ~= 2 & state(2:end) == 2)+1;
    timeoutStarts = find(state(1:end-1) == 2 & state(2:end) ~= 2)+1;
    
    if numel(availableStarts) < numel(witholdingStarts)
        witholdingStarts(end) = [];
    elseif numel(timeoutStarts) < numel(witholdingStarts)
        witholdingStarts(end) = [];
        availableStarts(end) = [];
    elseif numel(timeoutStarts) < numel(availableStarts)
        timeoutStarts(end+1) = numel(timestamps); %#ok<SAGROW>
        state(end) = 4; % if we timed out in the available period, obviously that counts as ignored
    end

    assert(numel(witholdingStarts) == numel(availableStarts) && numel(availableStarts) == numel(timeoutStarts));
    assert(all(witholdingStarts < availableStarts & availableStarts < timeoutStarts));
    
    ii = find(ismember(allMice,sprintf('Cage %s mouse %s',allFiles{nn,3},allFiles{nn,4})));
    jj = allFiles{nn,5};
    kk = find(allDates == allFiles{nn,2});
    ll = treatment(ii,jj,ismember(dirs,allDates(kk)))+1; % TODO : better
    
    nTrials = numel(availableStarts);
    performance(ii,jj,kk,ll).nTrials = nTrials;

    isResponded = state(timeoutStarts) == 3;
    isIgnored = state(timeoutStarts) == 4;

    assert(all(isResponded | isIgnored) && ~any(isResponded & isIgnored));

    performance(ii,jj,kk,ll).isResponded = isResponded;
    performance(ii,jj,kk,ll).nResponses = sum(isResponded);
    performance(ii,jj,kk,ll).responseRate = 100*performance(ii,jj,kk,ll).nResponses/nTrials;
    performance(ii,jj,kk,ll).responsesPerHour = 3600*performance(ii,jj,kk,ll).nResponses/(timestamps(end)-timestamps(1));
    
    reachTimes = timestamps(find(diff(licks) > 0)+1);
    performance(ii,jj,kk,ll).totalReaches = numel(reachTimes);
    
    reactionTime = inf(nTrials,1);
    appropriateReaches = zeros(nTrials,1);
    inVainReaches = zeros(nTrials,1);
    reachISIs = cell(nTrials,1);
    
    figure;
    hold on;
    
    maxTime = 0;
    
    for mm = 1:nTrials
        t0 = timestamps(witholdingStarts(mm));
        t1 = timestamps(availableStarts(mm));
        t2 = timestamps(timeoutStarts(mm));
        
        if mm == nTrials
            t3 = timestamps(end);
        else
            t3 = timestamps(witholdingStarts(mm+1));
        end
        
        maxTime = max(maxTime,t3-t0);
        
        fill([t0 t1 t1 t0]-t0,mm-[1 1 0 0],[6 6 6]/7,'EdgeColor','none');
        fill([t1 t2 t2 t1]-t0,mm-[1 1 0 0],[5 5 5]/7,'EdgeColor','none');
        fill([t2 t3 t3 t2]-t0,mm-[1 1 0 0],[4 4 4]/7,'EdgeColor','none');
        
        inVainReachTimes = reachTimes(reachTimes >= t0 & reachTimes < t1);
        inVainReaches(mm) = numel(inVainReachTimes);
        
        if ~isempty(inVainReachTimes)
            plot(inVainReachTimes-t0,repmat(mm-0.5,1,inVainReaches(mm)),'LineStyle','none','Marker','^','MarkerEdgeColor','k','MarkerFaceColor','r');
        end
        
        appropriateReachTimes = reachTimes(reachTimes >= t1 & reachTimes < t2);
        
        appropriateReaches(mm) = numel(appropriateReachTimes);
        
        plot(appropriateReachTimes-t0,repmat(mm-0.5,1,appropriateReaches(mm)),'LineStyle','none','Marker','^','MarkerEdgeColor','k','MarkerFaceColor','g');
        
        if ~isempty(appropriateReachTimes)
            reactionTime(mm) = appropriateReachTimes(1) - availableStarts(mm);
        end
        
        postReachTimes = reachTimes(reachTimes >= t2 & reachTimes < t3);
        
        plot(postReachTimes-t0,repmat(mm-0.5,1,numel(postReachTimes)),'LineStyle','none','Marker','^','MarkerEdgeColor','k','MarkerFaceColor','g');
        
        allReaches = [inVainReachTimes; appropriateReachTimes; postReachTimes];
        
        reachISIs{mm} = diff(allReaches);
    end
    
    performance(ii,jj,kk,ll).reachISIs = vertcat(reachISIs{:});
    
    hs(1) = fill(NaN,NaN,[6 6 6]/7,'EdgeColor','none');
    hs(2) = fill(NaN,NaN,[5 5 5]/7,'EdgeColor','none');
    hs(3) = fill(NaN,NaN,[4 4 4]/7,'EdgeColor','none');
    hs(4) = plot(NaN,NaN,'LineStyle','none','Marker','^','MarkerEdgeColor','k','MarkerFaceColor','g');
    hs(5) = plot(NaN,NaN,'LineStyle','none','Marker','^','MarkerEdgeColor','k','MarkerFaceColor','r');
    
    legend(hs,{'Withholding' 'Available' 'Timeout' 'Lick/Reach Response' 'In-vain lick/reach'},'Location','NorthEast');
    title(sprintf('Date %s cage %s mouse %s session %d',datestr(allFiles{nn,2},'yyyymmdd'),allFiles{nn,3},allFiles{nn,4},allFiles{nn,5}));
    xlabel('Time (s)');
    xlim([0 maxTime]);
    ylabel('Trial #');
    ylim([0 nTrials]);
    
    jbsavefig(gcf,'%s_session_%d_trial_plot',allFiles{nn,4},jj);
    close(gcf);
    
    performance(ii,jj,kk,ll).reactionTime = median(reactionTime);
    performance(ii,jj,kk,ll).appropriateReaches = median(appropriateReaches);
    performance(ii,jj,kk,ll).inVainReaches = median(inVainReaches);
    toc;
end

%%

% ylabels = {'# Trials' '# Responded Trials' '% Responded Trials' 'Responded Trials/Hour' 'Reaction Time (s)' '# Reaches' '# Reaches Per Trial' '# In Vain Reaches'};
% markers = 'os';
% lineStyles = {'-' '--'};
% 
% % for hh = 1:2
%     for ii = 3 %1:nFields
%         figure
%         hold on;
%         
%         for jj = 1:nTreatments
% %             mx = allDates;
%             x = (1:(maxSessions*nDates)); %datetime(kron(datenum(allDates),ones(1,maxSessions)),'ConvertFrom','datenum','TimeZone','America/Chicago');
% 
%             y = permute(reshape([performance(:,:,:,jj).(fields{ii})],size(performance(:,:,:,jj))),[2 3 1]);
% %             my = permute(nanmedian(y,1),[2 3 1]);
%             y = reshape(y,maxSessions*nDates,nMice);
%             
%             set(gca,'ColorOrderIndex',1);
% 
%             h = plot(x,y,'LineStyle','-','Marker',markers(jj));
% 
%             set(gca,'ColorOrderIndex',1);
% 
% %             h = plot(mx,my,'LineStyle',lineStyles{jj});
% 
%             legend(h,allMice);
% 
%             ylabel(ylabels{ii});
%         end
%     end
% % end

%%

ylabels = {'# Trials' '# Responded Trials' '% Responded Trials' 'Responded Trials/Hour' 'Reaction Time (s)' '# Reaches' '# Reaches Per Trial' '# In Vain Reaches'};
colours = distinguishable_colors(nMice);
markers = 'os';
lineStyles = {'-' '--'};

for ii = 1:nFields
    figure
    hold on;
    
    hs = gobjects(nMice+2,1);

    for hh = 1:nMice        
        for jj = 1:nTreatments
            for kk = 1:ceil(nDirs/5)
                dirIndex = ((kk-1)*5+1):min(nDirs,5*kk);
                
                treatmentIndex = find(treatment(hh,:,dirIndex) == uniqueTreatments(jj));
                
                if isempty(treatmentIndex)
                    continue
                end
                
                [~,sessionIndex,dateIndex] = ind2sub(size(treatment(hh,:,dirIndex)),treatmentIndex);
                
                x = dateIndex + (2*sessionIndex-3)/10 + (kk-1)*7;
                
                performanceIndex = sub2ind(size(performance),hh*ones(size(x)),sessionIndex,reshape(arrayfun(@(d) find(ismember(allDates,d)),dirs(dirIndex(dateIndex))),size(x)),jj*ones(size(x)));

                y = [performance(performanceIndex).(fields{ii})];

                h = plot(x,y,'Color',colours(hh,:),'LineStyle',lineStyles{jj},'Marker',markers(jj));
            end
        end
    end
    
    for jj = 1:nMice
        hs(jj) = plot(NaN,NaN,'Color',colours(jj,:),'LineStyle',lineStyles{1},'Marker',markers(1));
    end
    
    for jj = 1:nTreatments
        hs(jj+nMice) = plot(NaN,NaN,'Color',[0 0 0],'LineStyle',lineStyles{jj},'Marker',markers(jj));
    end

    legend(hs,[allMice {'Saline' 'PSEM'}]); % TODO : treatment names

    ylabel(ylabels{ii});
end

%%

dTreatment = squeeze(diff(treatment,[],2));
nSwitchTrials = sum(abs(dTreatment),2);
switchResponseRate = arrayfun(@(n) zeros(n,2),nSwitchTrials,'UniformOutput',false);

%%

for ii = 1:nMice
    switchDays = find(dTreatment(ii,:));
    
    for jj = 1:nTreatments
        dateIndex = find(ismember(allDates,dirs(switchDays)))';
        [~,sessionIndex,~] = ind2sub([1 maxSessions numel(switchDays)],find(treatment(ii,:,switchDays) == uniqueTreatments(jj)));
        performanceIndex = sub2ind(size(performance),ii*ones(size(sessionIndex)),sessionIndex,dateIndex,jj*ones(size(sessionIndex)));
        switchResponseRate{ii}(:,jj) = vertcat(performance(performanceIndex).responseRate);
    end
end

%%

markers = 'osd^v<>x+*.ph';

figure;

hold on;

hs = gobjects(nMice+1,1);

for ii = 1:nMice
    for jj = 1:size(switchResponseRate{ii},1)
        h = plot([1 2],switchResponseRate{ii}(jj,:),'Color',[0.75 0.75 0.75],'Marker',markers(ii+1));
        
        if jj == 1
            hs(ii) = h;
        end
    end
end

hs(end) = plot([1 2],median(vertcat(switchResponseRate{:})),'Color','b','LineWidth',2,'Marker','o');

set(gca,'XTick',[1 2],'XTickLabel',{'Saline' 'PSEM'});

xlim([0 3]);

include = ~arrayfun(@(h) isa(h,'matlab.graphics.GraphicsPlaceholder'),hs);

legend(hs(include),[allMice(include(1:end-1)) {'Median'}]);