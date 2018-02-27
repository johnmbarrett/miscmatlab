classdef WSMapper < handle % or ws.UserCode or whatever the fuck?  Probably better to keep as much as possible outside of WaveSurfer's bullshit serialisation fuckery as possible
    properties(Access=protected)
        Angle_
        Figure_
        MapAxis_
        MapPattern_
        PowerLUT_
        XOffset_
        XScale_
        YOffset_
        YScale_
    end
    
    properties(Dependent=true)
        MapPattern
        PowerLUT
    end
    
    properties(Dependent=true,SetAccess=immutable)
        Rows
        Cols
    end
    
    methods
        function self = WSMapper()
            self.Figure_ = figure('Position',[100 100 450 450]); % oh Matlab, why don't you have *ANY* fucking layout managers?  it's twenty god damn eighteen for fuck's sake
            
            uicontrol(self.Figure_,                 ...
                'Callback', @self.openMapLoader,    ...
                'Position', [10 415 70 25],         ...
                'String',   'Load Map',             ...
                'Style',    'pushbutton'            ...
                );
            
            uicontrol(self.Figure_,                 ...
                'Callback', @self.saveMap,          ...
                'Position', [90 415 70 25],         ...
                'String',   'Save Map',             ...
                'Style',    'pushbutton'            ...
                );
                
            self.MapAxis_ = axes('Units','pixels','Position',[10 255 150 150],'XColor','none','YColor','none');
            
            uicontrol(self.Figure_,                 ...
                'Callback', @self.loadLUT,          ...
                'Position', [170 415 70 25],        ...
                'String',   'Load LUT',             ...
                'Style',    'pushbutton'            ...
                );
            
            uicontrol(self.Figure_,                 ...
                'Position', [250 415 190 25],       ...
                'String',   '',                     ...
                'Style',    'text'                  ...
                );
        end
        
        function map = get.MapPattern(self)
            map = self.MapPattern_;
        end
        
        function set.MapPattern(self,map)
            assert(self.validateMap(map),'Map pattern must be a matrix with integer entries from one to the number of elements in the matrix.'); % TODO : msgids, better error message
            
            self.MapPattern_ = map;
            
            imagesc(self.MapAxis_,self.MapPattern);
            colormap(self.MapAxis_,gray(numel(self.MapPattern_)));
            set(self.MapAxis_,'XTick',[],'YTick',[]);
        end
        
        function rows = get.Rows(self)
            rows = size(self.MapPattern_,1);
        end
        
        function cols = get.Cols(self)
            cols = size(self.MapPattern_,2);
        end
    end
    
    methods(Access=protected)
        function closeMapLoader(~,mapLoader,callback)
            close(mapLoader);
            callback();
        end
        
        function loadLUT(self)
            self.loadAnyFile({'lut' 'LUT'},'map','PowerLUT');
        end
        
        function data = loadAnyFile(dataFields,dataName,property)
            file = uigetfile(sprintf('Choose a %s file',dataName));
            
            if ~ischar(file)
                return
            end
            
            [path,filename,extension] = fileparts(file);
            
            fullFilename = [path filename extension];
            
            extension = extension(2:end);
            
            switch extension
                case 'mat'
                    fileContents = load(fullFilename);

                    fields = fieldnames(fileContents);

                    dataField = find(ismember(fields,dataFields),1);

                    if isempty(dataField)
                        isDataFound = false;

                        for ii = 1:numel(fields)
                            field = fields{ii};

                            if validator(fileContents.(field))
                                data = fileContents.(field);
                                isDataFound = true;
                                break;
                            end
                        end

                        if ~isDataFound
                            data = NaN; % hopefully NaN is never a valid data
                        end
                    else
                        data = fileContents.(fields{dataField});
                    end
                case {'txt' 'csv' 'xls' 'xlsx'}
                    data = importdata(fullFilename);
                otherwise % probably a binary file
                    precisions = {@double @single @int8 @int16 @int32 @int64 @uint8 @uint16 @uint32 @uint64 @char};
                    
                    selection = listdlg(cellfun(@func2str,precisions,'UniformOutput',false),'SelectionMode','single','PromptString','Enter data precision:');
                    
                    if numel(selection) ~= 1
                        data = [];
                        
                        return
                    end
                    
                    cols = inputdlg('Enter number of columns:');
                    
                    if numel(cols) ~= 1
                        data = [];
                        
                        return 
                    end
                    
                    cols = str2double(cols{1});
                    
                    if isnan(cols)
                        data = [];
                        
                        return
                    end
                    
                    fin = fopen(fullFilename);
                    
                    fseek(fin,0,1);
                    
                    nBytes = ftell(fin);
                    
                    precision = precisions(selection);
                    
                    x = precision(0); %#ok<NASGU>
                    
                    info = whos('x'); % I hate you matlab
                    
                    rows = nBytes/(info.bytes*cols);
                    
                    fseek(fin,0,-1);
                    
                    if ~isinteger(rows)
                        data = NaN;
                    else
                        data = fread(fin,[rows cols],[func2str(precision) '=>double']);
                    end
                    
                    fclose(fin);
            end
                
            try
                
                error('WSMapper:InvalidData','Could not find a valid %%s in file %s%s',filename,extension);
            end
        end
        
        function loadMapFromExpression(self)
            expression = inputdlg('Enter map expression:');
            
            if numel(expression) == 0
                errordlg('I told you to write something');
                
                return
            elseif numel(expression) > 1
                errordlg('How did you even manage this?');
                
                return
            end
            
            try
                map = eval(expression{1}); % haha
            catch err %#ok<NASGU>
                errordlg('I don''t know how but you really managed to fuck things up, didn''t you?');
                
                return
            end
            
            if ~self.validateMap(map)
                errordlg('That is not a map you fuck what is wrong with you.');
                
                return
            end
            
            self.MapPattern = map;
        end
        
        function loadMapFromFile(self)
            try
                map = self.loadAnyFile({'map' 'pattern'},@self.validateMap,'Choose a map file');
            catch err
                errordlg(sprintf(err.message,'map'));
                
                return
            end
            
            self.MapPattern = map;
        end
        
        function loadMapFromWorkspace(self)
            vars = evalin('base','whos');
            
            selection = listdlg('ListString',{vars.name},'SelectionMode','single','PromptString','Choose the map variable:');
            
            if isempty(selection)
                return
            end
            
            map = evalin('base',vars(selection).name);
            
            if ~self.validateMap(map)
                errordlg('Why did you think this was a good idea?');
                
                return
            end
            
            self.MapPattern = map;
        end
        
        function flashCenter(self)
            % flashes the centre of the map
        end
        
        function flashCorners(self)
            % flashes the corners of the map
        end
        
        function openMapLoader(self,varargin)
            mapLoader = figure('Position',[100 100 150 115]);
            
            funs = {                        ...
                @self.loadMapFromFile,      ...
                @self.loadMapFromWorkspace, ...
                @self.loadMapFromExpression ...
                };
            
            strings = {'From File' 'From Workspace' 'From Expression'};
            
            % TODO : menus would make more sense
            for ii = 1:3
                uicontrol(mapLoader,                                                    ...
                    'Callback', @(varargin) self.closeMapLoader(mapLoader,funs{ii}),    ...
                    'Position', [10 115-35*ii 130 25],                                   ...
                    'Style',    'pushbutton',                                           ...
                    'String',   strings{ii}                                             ...
                    );
            end
        end
        
        function saveMap(self)
            disp('no we forgot to implement the other one');
        end
        
        function isValid = validateMap(~,map) % TODO : some of these fuckos should be static but I can't be fucked right now
            isValid = isnumeric(map) && ismatrix(map) && isequal(sort(map(:)),(1:numel(map))');
        end
    end
end