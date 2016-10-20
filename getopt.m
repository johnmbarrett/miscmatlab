function value = getopt(key,default,varargin)
    keyIndex = find(strcmp(key,varargin));
    
    if isempty(keyIndex)
        value = default;
        return
    end
    
    valueIndex = keyIndex + 1;

    if numel(varargin) < valueIndex
        value = default;
        return
    end
    
    value = varargin{valueIndex};
end