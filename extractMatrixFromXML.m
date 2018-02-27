function M = extractMatrixFromXML(xmlMatrixStruct)
    dimsize = xmlMatrixStruct.Dimsize;
    
    if isstruct(dimsize) % TODO : more arg checking
        dimsize = {dimsize};
    end

    sz = cellfun(@(A) str2double(A.Text),dimsize);
    
    if numel(sz) == 1
        sz(2) = 1;
    end
    
    i32 = xmlMatrixStruct.I32;
    
    if isstruct(i32)
        i32 = {i32};
    end
    
    M = cellfun(@(A) str2double(A.Val.Text),i32);
    
    assert(prod(sz) == numel(M));
    
    M = reshape(M,sz(2),sz(1))';
end