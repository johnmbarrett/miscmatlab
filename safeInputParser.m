classdef safeInputParser < inputParser
    methods
        function parse(self,varargin)
            parse@inputParser(self);
            
            defaults = self.Results;
            
            isSuccessful = false;
            
            while ~isSuccessful
                try
                    parse@inputParser(self,varargin{:});
                    
                    isSuccessful = true;
                catch err
                    param = regexp(err.message,'The value of ''(.+)'' is invalid','tokens');
                    
                    if isempty(param)
                        error(err);
                    end
                    
                    param = param{1}{1};
                    
                    valueIndex = find(strcmpi(param,varargin))+1;
                    
                    if varargin{valueIndex} == defaults.(param)
                        error('The default value for %s doesn''t pass validation, you dumbass',param);
                    end
                    
                    warning('Invalid value supplied for %s, using default value',param);
                    
                    varargin{valueIndex} = defaults.(param);
                end
            end
        end
    end
end