function varargout = loadStructArrayFile(filename,structSize,structFormat,isUnsigned)
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
    
    fclose(fin);
    
    if nargout == 1
        varargout{1} = A;
        return
    end
    
    for ii = 1:max(nargout,size(A,2))
        varargout{ii} = A(:,ii); %#ok<AGROW>
    end
end