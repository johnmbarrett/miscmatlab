classdef CompressorDaemon < handle
    properties
        WorkingDirectory;
        ProcessedAVIs;
        Timer;
    end

    methods
        function self = CompressorDaemon(folder)
            if nargin < 1
                self.WorkingDirectory = pwd;
            else
                self.WorkingDirectory = folder;
            end
            
            self.ProcessedAVIs = {};
            
            % TODO : start timer
        end
        
        function compressAVIs(self)
            foldersToCheck = {self.WorkingDirectory};
            
            while ~isempty(foldersToCheck)
                folder = foldersToCheck{1};
                foldersToCheck(1) = [];
                
                cd(folder);
                
                files = dir;
                
                foldersToCheck = [foldersToCheck cellfun(@(s) [folder '\' s],{files([files.isdir] & ~strncmpi('.',{files.name},1)).name},'UniformOutput',false)]; %#ok<AGROW>
                
                filenames = {files.name};
                
                avis = filenames(~cellfun(@isempty,regexp(filenames,'\.avi$','once')));
                
                for ii = 1:numel(avis)
                    tic;
                    avi = [folder '\' avis{ii}];
                    
                    if any(strcmp(avi,self.ProcessedAVIs))
                        fprintf('INFO: Skipping already processed file %s\n',avi);
                        toc;
                        continue
                    end
                    
                    [status,output] = system(['handle ' avi]);
                    
                    if status ~= 0
                        if ii == numel(avis)
                            warnStr = 'this is the last file in the folder, so I''m going to skip in case it''s currently being written to.';
                        else
                            warnStr = 'this is not the last file so I''m assuming no-one has an open handle to it.';
                        end
                        
                        warning('Unable to run handle.exe for file %s, %s\n',avi,warnStr);
                        
                        if ii == numel(avis)
                            toc;
                            continue
                        end
                    elseif ~isempty(strfind(avi,output))
                        fprintf('INFO: File %s currently open in another process, skipping...\n',avi);
                        toc;
                        continue
                    end
                    
                    [~,aviName] = fileparts(avi); % TODO : these variable names are crap
                    
                    status = system(sprintf('avconv -i %s.avi -vcodec h264 -preset veryslow -crf 0 %s.mp4',aviName,aviName));
                    
                    if status ~= 0
                        warning('avconv failed for file %s, check output for details.\n',avi);
                        toc;
                        continue
                    end
                    
                    self.ProcessedAVIs{end+1} = avi;
                    
                    toc;
                end
            end
        end
    end
end