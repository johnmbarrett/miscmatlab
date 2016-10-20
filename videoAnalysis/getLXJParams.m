function params = getLXJParams(filename)
    params = strsplit(filename,{'_' '.'});
    params = cellfun(@str2double,params(2:end-1));
end