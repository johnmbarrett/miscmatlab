function concatenateMATFiles(inFiles,outFile)
    s0 = load(inFiles{1});
    f = fields(s0);
    
    for jj = 1:numel(f)
        v = s0.(f{jj});

        if size(v,1) ~= 1
            v = reshape(v,[1 size(v)]);
        end
        
        s0.(f{jj}) = v;
    end
    
    for ii = 2:numel(inFiles)
        tic;
        si = load(inFiles{ii});
        
        for jj = 1:numel(f)
            v = s0.(f{jj});
            
            c = repmat({':'},1,ndims(v)-1);
            
            w = si.(f{jj});
            
            if size(w,1) ~= 1
                w = reshape(w,[1 size(w)]);
            end
            
            v(end+1,c{:}) = w; %#ok<AGROW>
            s0.(f{jj}) = v;
        end
        toc;
    end
    
    save(outFile,'-v7.3','-struct','s0');
end