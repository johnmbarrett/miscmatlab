classdef LUTReader
    properties(Constant=true)
        LUTs = struct([]);
    end
    
    methods(Static=true)
        function value = get(key,index,isInterp)
%             key = strrep(key,{':' '\' '/' ' '},'_');
            
            if ~isfield(LUTReader.LUTs,key)
                if ~exist(key,'file')
                    warndlg(sprintf('Unable to find look-up table with filename %s.',key));
                    value = NaN;
                    return
                end
                
                fin = fopen(key);
                fseek(fin,0,1);
                bytes = ftell(fin);
                fseek(fin,0,-1);

                lut = fread(fin,[bytes/16 2],'double');
                
                LUTReader.LUTs(1).(key) = lut; %#ok<STRNU>
            else
                lut = LUTReader.LUTs.(key);
            end
            
            if nargin > 2 && isInterp
                value = interp1(lut(:,1),lut(:,2),index);
                return
            end
            
            value = nan(size(index));
            
            for ii = 1:numel(value)
                if index(ii) < lut(1,1)
                    value(ii) = lut(1,2);
                else
                    value(ii) = lut(find(lut(:,1) <= index(ii),1,'last'),2);
                end
            end
        end
    end
end