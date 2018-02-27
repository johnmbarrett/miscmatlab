function parseTable(fin,fieldSpecification,delimiter)
    assert(iscell(fieldSpecification) && ismatrix(fieldSpecification) && size(fieldSpecification,2) == 2 && all(cellfun(@ischar,fieldSpecification(:))),'fieldSpecification must be a two-column cell array of strings');

    headerRegex = sprintf('((%s)(%s)?)+',strjoin(fieldSpecification{:,1}),delimiter);
    
    isHeaderFound = false;
    
    if ischar(fin)
        fin = fopen(fin,'r');
    end
    
    while ~isHeaderFound && ~feof(fin)
        s = fgetl(fin);
        
        isHeaderFound = ~isempty(regexp(s,headerRegex));
    end
end