classdef StageMover < ws.UserClass
    properties(Access=protected)
        COMPort
        NPositions
        Positions
        SetPositionButtons
        SutterMP285
        SweepCounter
    end
    
    methods(Access=public)
        function self = StageMover(model)
            if ~isa(model,'ws.WavesurferModel')
                return;
            end
            
            fig = figure('Position',[100 100 300 400]);
            
            ports = getAvailableComPort; % TODO : detect changes in COM ports
            
            uicontrol(fig,                                      ...
                'HorizontalAlignment',  'left',                 ...
                'Position',             [10 370 60 15],         ...
                'String',               'COM Port:',            ...
                'Style',                'text'                  ...
                );
            
            uicontrol(fig,                                      ...
                'Callback', @self.updateCOMPort,                ...
                'Position', [70 370 220 20],                    ...
                'String',   [{'Choose a COM Port...'} ports],   ...
                'Style',    'popupmenu',                        ...
                'Value',    1                                   ...
                );
            
            uicontrol(fig,                                      ...
                'HorizontalAlignment',  'left',                 ...
                'Position',             [10 340 60 15],         ...
                'String',               '# Positions:',         ...
                'Style',                'text'                  ...
                );
            
            uicontrol(fig,                                      ...
                'Callback', @self.updateNPositions,             ...
                'Position', [70 340 220 20],                    ...
                'String',   '0',                                ...
                'Style',    'edit',                             ...
                'Value',    1                                   ...
                );
            
            self.Positions = zeros(0,3);
            self.SetPositionButtons = [];
            self.SutterMP285 = NaN;
            self.SweepCounter = 0;
        end
        
        function updateCOMPort(self,menu,varargin)
            self.COMPort = menu.String{menu.Value};
            
            if isa(self.SutterMP285,'serial');
                try
                    fclose(self.SutterMP285);
                catch err
                    logMatlabError(err,'Unable to close existing Sutter MP-285 interface:\n');
                end
            end
            
            try
                self.SutterMP285 = sutterMP285(self.COMPort);
            catch err
                logMatlabError(err,'Unable to open Sutter MP-285 interface:\n');
            end
        end
        
        function updateNPositions(self,editbox,varargin)
            self.NPositions = validateAndApplyNumericTextEntry(editbox,[],@(v) round(max(0,v)));
            self.Positions = [self.Positions(1:min(size(self.Positions,1),self.NPositions),:); zeros(max(0,self.NPositions-size(self.Positions,1)),3)];
            disp(self.Positions);
            
            if ~isempty(self.SetPositionButtons)
                delete(self.SetPositionButtons);
            end
            
            for ii = 1:self.NPositions % TODO : resize the figure if this gets really big
                button = uicontrol(get(editbox,'Parent'),                    ...
                    'Callback', {@self.updatePosition ii},          ...
                    'Position', [155-145*mod(ii,2) 340-30*ceil(ii/2) 135 20],                    ...
                    'String',   sprintf('Update Position #%d',ii),  ...
                    'Style',    'pushbutton'                        ...
                    );
                
                if ii == 1
                    self.SetPositionButtons = button;
                else
                    self.SetPositionButtons(end+1) = button;
                end
            end
        end
        
        function updatePosition(self,~,~,index)
            if ~isa(self.SutterMP285,'sutterMP285') % TODO : grey out buttons
                return
            end
            
            self.Positions(index,:) = getPosition(self.SutterMP285);
            disp(self.Positions);
        end
        
        % these are called in the frontend process
        function startingRun(self,wsModel,eventName)
            self.SweepCounter = 0;
        end
        
        function completingRun(self,wsModel,eventName)
        end
        
        function stoppingRun(self,wsModel,eventName)
        end
        
        function abortingRun(self,wsModel,eventName)
        end
        
        function startingSweep(self,wsModel,eventName)  
            self.SweepCounter = self.SweepCounter + 1;
            
            if self.NPositions < 1 || ~isa(self.SutterMP285,'sutterMP285') % TODO : grey out buttons
                return
            end
            
            moveTo(self.SutterMP285,self.Positions(mod(self.SweepCounter-1,self.NPositions)+1,:)); % TODO : random order
        end
        
        function completingSweep(self,wsModel,eventName)      
        end
        
        function stoppingSweep(self,wsModel,eventName)      
        end
        
        function abortingSweep(self,wsModel,eventName)
        end
        
        function dataAvailable(self,wsModel,eventName)
        end
        
        
        % this one is called in the looper process
        function samplesAcquired(self,looper,eventName,analogData,digitalData) 
        end
        
        % these are are called in the refiller process
        function startingEpisode(self,refiller,eventName)        
        end
        
        function completingEpisode(self,refiller,eventName)    
        end
          
        function stoppingEpisode(self,refiller,eventName)      
        end
        
        function abortingEpisode(self,refiller,eventName)        
        end
    end  % methods
end  % classdef