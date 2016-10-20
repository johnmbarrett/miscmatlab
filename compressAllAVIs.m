function compressAllAVIs(isRecursive)
    files = dir;
    avis = files(arrayfun(@(f) strcmp(f.name(max(1,end-3):end),'.avi'),files));
    
    
    for ii = 1:numel(avis)
        fprintf('Copying AVI file %s to temporary file',avis(ii).name);
        
        writer = VideoWriter('temp.avi'); %#ok<TNMLP>
        reader = VideoReader(avis(ii).name); %#ok<TNMLP>
        
        writer.FrameRate = reader.FrameRate;
        
        open(writer);
        
        while hasFrame(reader)
            writeVideo(writer,readFrame(reader));
            fprintf('.');
        end
        
        fprintf('\nFinished copying, deleting temporary file...\n');
        
        close(writer);
        
        clear reader; % this releases the file handle
        
        try
            delete(avis(ii).name);

            fprintf('\nFinished deleting, moving temporary file to %s...\n',avis(ii).name);

            movefile('temp.avi',avis(ii).name);

            fprintf('Done!\n\n');
        catch err
            logMatlabError(err, 'Encountered error deleting original file and moving compressed copy:\n');
            backupFile = sprintf('temp %s',avis(ii).name);
            fprintf('Moving temporary file to %s\n',backupFile);
            movefile('temp.avi',backupFile);
        end
    end
    
    if nargin < 1 || ~isRecursive
        return
    end
        
    dirs = files([files.isdir]);
    
    for ii = 1:numel(dirs)
        if strcmp(dirs(ii).name,'.') || strcmp(dirs(ii).name,'..')
            continue
        end
        
        cd(dirs(ii).name);
        
        try
            fprintf('Entered folder %s\n\n',dirs(ii).name);
            compressAllAVIs(true);
            cd ..;
            fprintf('Left folder %s\n\n',dirs(ii).name);
        catch err
            logMatlabError(err,sprintf('Encountered error compressing AVIs in dir %s\n',dirs(ii).name));
            cd ..;
        end
    end
end