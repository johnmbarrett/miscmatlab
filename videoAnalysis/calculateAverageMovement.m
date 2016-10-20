function movement = calculateAverageMovement(lxjFiles,lutFile,baselineFrames,scale)
    nFiles = numel(lxjFiles);
    
    if isempty(lutFile)
        n = ceil(sqrt(numel(lxjFiles)));
        x = kron(0:n-1,ones(1,n))';
        y = repmat(0:n-1,1,n)';
    elseif isnumeric(lutFile) && numel(lutFile) == 2 && all(isfinite(lutFile) & lutFile >= 1)
        x = kron(0:lutFile(1)-1,ones(1,lutFile(2)))';
        y = repmat(0:lutFile(2)-1,1,lutFile(1))';
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
    
    miniArraySize = round(arraySize(1:2)*scale);
    bigArraySize = [miniArraySize(1)*(1+max(y)) miniArraySize(2)*(1+max(x)) arraySize(3:4)];
    
    bigVideo = zeros(bigArraySize);
    bigZScore = zeros(bigArraySize);
    sumZScore = zeros(bigArraySize(1:2));
    movement = zeros(max(y)+1,max(x)+1);
    
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
        
        M = cellfun(@(A) mean(A(:,:,baselineFrames,:),3),data,'UniformOutput',false);
        S = cellfun(@(A) std(A(:,:,baselineFrames,:),[],3),data,'UniformOutput',false);
        Z = cellfun(@(A,m,s) bsxfun(@rdivide,bsxfun(@minus,A,m),s),data,M,S,'UniformOutput',false);
        
        for jj = 1:numel(Z)
            Z{jj}(isnan(Z{jj})) = 0;
            Z{jj}(isinf(Z{jj})) = max(Z{jj}(isfinite(Z{jj})));
        end
        
        save([path name '_zscore.mat'],'-v7','Z'); % this is the fastest way even though it is really slow
        
        minZ = min(cellfun(@(A) min(A(:)),Z));
        maxZ = max(cellfun(@(A) max(A(:)),Z));
        
        writer = VideoWriter([path name '_zscore.avi']); %#ok<TNMLP>
        writer.FrameRate = 30; % TODO : pass in
        
        open(writer);
        
        for jj = 1:arraySize(4)
            for kk = 1:size(data{jj},3) % account for dropped frames
                writeVideo(writer,uint8(255*(Z{jj}(:,:,kk)-minZ)/(maxZ-minZ)));
                bigVideo(yidx,xidx,kk,jj) = imresize(data{jj}(:,:,kk),scale);
                bigZScore(yidx,xidx,kk,jj) = imresize(Z{jj}(:,:,kk),scale);
            end
        end
        
        close(writer);
        
        sumZ = zeros(arraySize(1:2));
        
        for jj = 1:numel(Z)
            sumZ = sumZ + sum(abs(Z{jj}),3)/numel(Z);
        end
        
        sumZScore(yidx,xidx) = imresize(sumZ,scale);
        movement(y(ii)+1,x(ii)+1) = mean(sumZ(:));
        
        clear data M S Z;
        
        if exist('fin','var')
            fclose(fin);
        end
        
        toc;
    end
    
    dirs = strsplit(pwd,{'\' '/'});
    lastDir = dirs{end};
    
    save([lastDir '_movement.mat'],'movement');
    
    writer1 = VideoWriter([lastDir '_zscore.avi']);
    writer1.FrameRate = 30;
    open(writer1);
    
    writer2 = VideoWriter([lastDir '_all_positions.avi']);
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