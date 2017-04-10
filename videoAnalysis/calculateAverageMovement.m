function [movement,bigVideo,bigZScore] = calculateAverageMovement(lxjFiles,lutFile,baselineFrames,scale,rois,outputFilePrefix,noMatFile,noVideo,noIntermediaryFiles)
    nFiles = numel(lxjFiles);
    
    if isempty(lutFile)
        n = ceil(sqrt(numel(lxjFiles)));
        x = kron(0:n-1,ones(1,n))';
        y = repmat(0:n-1,1,n)';
    elseif isnumeric(lutFile) && numel(lutFile) == 2 && all(isfinite(lutFile(:)) & lutFile(:) >= 1)
        x = kron(0:lutFile(1)-1,ones(1,lutFile(2)))';
        y = flipud(repmat(0:lutFile(2)-1,1,lutFile(1))');
    else
        lut = importdata(lutFile);
        x = lut(2,1:nFiles);
        y = lut(1,1:nFiles);
    end
    
    [~,~,extn] = fileparts(lxjFiles{1});
    
    switch extn
        case '.lxj'
            paramss = cellfun(@(filename) getLXJParams(filename),lxjFiles,'UniformOutput',false);
            paramss = vertcat(paramss{:});
            arraySizes = paramss(:,2:end);

            assert(isequal(std(arraySizes),[0 0 0 0])); % TODO : what if false?
            
            arraySize = arraySizes(1,:);
        case '.mat'
            data = load(lxjFiles{1});
            arraySize = [size(data.VT{1}) numel(data.VT)]; % TODO : assumes no frame drop in first file
        otherwise
            error('Unrecognised file format %s\n',extn);
    end
    
    if isscalar(baselineFrames)
        baselineFrames = 1:nBaselineFrames;
    end
    
    data = cellfun(@double,loadLXJOrMATFile(lxjFiles{1}),'UniformOutput',false);
    
    if nargin < 5 || isempty(rois) || (isscalar(rois) && isnan(rois)) % TODO : better arg checking
        rois = [1 arraySize(1) 1 arraySize(2)];
    end
    
    miniArraySize = size(imresize(data{1}(rois(1,1):rois(1,2),rois(1,3):rois(1,4),1),scale)); % TODO : output montage for all rois
    
    nROIs = size(rois,1);
    
    if nargin < 8
        noVideo = false;
    end
    
    if nROIs > 1
        noVideo = true;
    end
    
    if ~noVideo
        bigArraySize = [miniArraySize(1)*(1+max(y)) miniArraySize(2)*(1+max(x)) arraySize(3:4) 1];
        bigVideo = zeros(bigArraySize);
        bigZScore = zeros(bigArraySize);
    end
    
    movement = zeros(max(y)+1,max(x)+1,nROIs);
    
    if nargin < 7
        noMatFile = false;
    end
    
    if nargin < 6 || isempty(outputFilePrefix)
        outputFilePrefix = '';
    else
        outputFilePrefix = ['_' outputFilePrefix];
    end
    
    for ii = 1:nFiles
        tic;
        [path,name,~] = fileparts(lxjFiles{ii});
        
        try
            data = cellfun(@double,loadLXJOrMATFile(lxjFiles{ii}),'UniformOutput',false);
        catch err
            warning('Encountered the following error trying to load file %s:-\n%s\nSkipping...\n',lxjFiles{ii},err.message);
            continue
        end
        
        yidx = y(ii)*miniArraySize(1)+(1:miniArraySize(1));
        xidx = x(ii)*miniArraySize(2)+(1:miniArraySize(2));
        
        originalZscoreFile = [path name '_zscore.mat'];
        
        if exist(originalZscoreFile,'file')
            load(originalZscoreFile,'Z');
            
            if ~iscell(Z{1})
                Z2 = cell(nROIs,1);
                
                for jj = 1:nROIs
                    r = rois(jj,:);
                    Z2{jj} = cellfun(@(A) A(r(1):r(2),r(3):r(4),:,:),Z,'UniformOutput',false);
                end
                
                Z = Z2;
            end
        else
            Z = cell(nROIs,1);
            
            for jj = 1:nROIs
                r = rois(jj,:);
                M = cellfun(@(A) mean(A(r(1):r(2),r(3):r(4),baselineFrames,:),3),data,'UniformOutput',false);
                S = cellfun(@(A) std(A(r(1):r(2),r(3):r(4),baselineFrames,:),[],3),data,'UniformOutput',false);
                Z{jj} = cellfun(@(A,m,s) bsxfun(@rdivide,bsxfun(@minus,A(r(1):r(2),r(3):r(4),:,:),m),s),data,M,S,'UniformOutput',false);
            end

            for jj = 1:numel(Z)
                for kk = 1:numel(Z{jj})
                    Z{jj}{kk}(isnan(Z{jj}{kk})) = 0;
                    Z{jj}{kk}(isinf(Z{jj}{kk})) = max(Z{jj}{kk}(isfinite(Z{jj}{kk})));
                end
            end

            if ~noMatFile && ~noIntermediaryFiles
                save([path name outputFilePrefix '_zscore.mat'],'-v7','Z'); % this is the fastest way even though it is really slow
            end
        end
        
        if ~noVideo
            minZ = min(cellfun(@(A) min(A(:)),Z{1}));
            maxZ = max(cellfun(@(A) max(A(:)),Z{1}));

            if ~noIntermediaryFiles
                writer = VideoWriter([path name outputFilePrefix '_zscore.avi']); %#ok<TNMLP>
                writer.FrameRate = 30; % TODO : pass in

                open(writer);
            end

            for jj = 1:arraySize(4)
                for kk = 1:size(data{jj},3) % account for dropped frames
                    if ~noIntermediaryFiles
                        writeVideo(writer,uint8(255*(Z{1}{jj}(:,:,kk)-minZ)/(maxZ-minZ)));
                    end
                    
                    bigVideo(yidx,xidx,kk,jj) = imresize(data{jj}(rois(1,1):rois(1,2),rois(1,3):rois(1,4),kk),scale);
                    bigZScore(yidx,xidx,kk,jj) = imresize(Z{1}{jj}(:,:,kk),scale);
                end
            end

            if ~noIntermediaryFiles
                close(writer);
            end
        end
        
        for jj = 1:numel(Z)
            sumZ = zeros(size(Z{jj}{1},1),size(Z{jj}{1},2));
            
            for kk = 1:numel(Z{jj})
                sumZ = sumZ + sum(abs(Z{jj}{kk}),3)/numel(Z{jj});
            end
        
            movement(y(ii)+1,x(ii)+1,jj) = mean(sumZ(:));
        end
        
        clear data M S Z;
        
        if exist('fin','var')
            fclose(fin);
        end
        
        toc;
    end
    
    dirs = strsplit(pwd,{'\' '/'});
    lastDir = dirs{end};
    
    save([lastDir outputFilePrefix '_movement.mat'],'movement');
    
    if noVideo
        return
    end
    
    writer1 = VideoWriter([lastDir outputFilePrefix '_zscore.avi']);
    writer1.FrameRate = 30;
    open(writer1);
    
    writer2 = VideoWriter([lastDir outputFilePrefix '_all_positions.avi']);
    writer2.FrameRate = 30;
    open(writer2);
    
    for ii = 1:size(bigZScore,4);
        for jj = 1:size(bigZScore,3)
            writeVideo(writer1,uint8(255*(bigZScore(:,:,jj,ii)+100)/300)); % TODO : choose scaling?
            writeVideo(writer2,uint8(bigVideo(:,:,jj,ii)));
        end
    end
    
    close(writer1);
    close(writer2);
end