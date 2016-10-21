function data = loadLXJOrMATFile(file)
    [~,~,extn] = fileparts(file);
    
    switch extn
        case '.lxj'
            fin = fopen(file{ii},'rb');

            [data,bytesRead] = fread(fin,prod(arraySize),'uint8=>uint8');

            [errno,msg] = ferror(fin);

            if errno ~= 0
                error('Encounted ERRNO %d (%s) while reading file %s.\n',errno,msg,file);
            end

            if bytesRead ~= prod(arraySize)
                error('File %s is incomplete: expected %d bytes but only read %d.\n',file,prod(arraySize),bytesRead);
            end

            data = reshape(data,arraySize);
            data = squeeze(mat2cell(data,arraySize(1),arraySize(2),arraySize(3),ones(arraySize(4),1)))';
        case '.mat'
            data = load(file,'VT');
            data = data.VT;
    end
end