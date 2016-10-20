function stacks = openTIFFStacks(files)
    if ischar(files)
        files = {files};
    elseif ~iscell(files)
        error('First argument must be a TIFF file or a cell array of TIFF files');
    end
    
    stacks = cellfun(@TIFFStack,files,'UniformOutput',false);
end