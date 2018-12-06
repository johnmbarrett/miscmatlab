function [params,sequence] = readParameterFile(parameterFile)
    if nargin < 1 || ~ischar(parameterFile) || isempty(parameterFile)
        [file, path] = ...
            uigetfile('*.*', 'Get the Parameter Files');
        parameterFile = [path,file];
    end

    paramStruct = xml2struct(parameterFile);
    params = extractMatrixFromXML(paramStruct.LVData.Cluster.Array{1});
    sequence = extractMatrixFromXML(paramStruct.LVData.Cluster.Array{2});
end



























