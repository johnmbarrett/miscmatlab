function varargout = vitalcam(varargin)
% EX_GUIDE_TIMERGUI - Execute graphic updates at regular intervals
%   MATLAB code for ex_guide_timergui.fig
%      EX_GUIDE_TIMERGUI, by itself, creates a new EX_GUIDE_TIMERGUI 
%      or raises the existing singleton*.
%
%      H = EX_GUIDE_TIMERGUI returns the handle to a new EX_GUIDE_TIMERGUI
%      or the handle to the existing singleton*.
%
%      EX_GUIDE_TIMERGUI('CALLBACK',hObject,eventData,handles,...) calls
%      the local function named CALLBACK in EX_GUIDE_TIMERGUI.M with 
%      the given input arguments.
%
%      EX_GUIDE_TIMERGUI('Property','Value',...) creates a new 
%      EX_GUIDE_TIMERGUI or raises the existing singleton*.
%      Starting from the left, property value pairs are applied to the 
%      GUI before ex_guide_timergui_OpeningFcn gets called.
%      An unrecognized property name or invalid value makes property
%      application stop.  All inputs are passed to 
%      ex_guide_timergui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows
%      only one instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES, TIMER

% Last Modified by GUIDE v2.5 19-May-2016 14:58:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @vitalcam_OpeningFcn, ...
                   'gui_OutputFcn',  @vitalcam_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ex_guide_timergui is made visible.
function vitalcam_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ex_guide_timergui (see VARARGIN)

% Choose default command line output for ex_guide_timergui
handles.output = hObject;

% START USER CODE
% Create a timer object to fire at 1/10 sec intervals
% Specify function handles for its start and run callbacks
% handles.updateDisplay = timer(...
%     'ExecutionMode', 'fixedRate', ...       % Run timer repeatedly
%     'Period', 0.1, ...                        % Initial period is 1 sec.
%     'TimerFcn', {@update_display,hObject}); % Specify callback function

handles.getVideo = timer(...
    'ExecutionMode', 'fixedRate', ...       % Run timer repeatedly
    'Period', 0.04, ...                        % Initial period is 1 sec.
    'TimerFcn', {@get_video,hObject}); % Specify callback function
% Initialize slider and its readout text field
set(handles.threshslider,'Min',-255,'Max',255,'SliderStep',[1/512 1/512],'Value',0)
set(handles.threshbox,'String',...
    num2str(get(handles.threshslider,'Value')))
set(handles.leddurbox,'String',...
    num2str(get(handles.leddurslider,'Value')))
set(handles.leddelaybox,'String',...
    num2str(get(handles.leddelayslider,'Value')))
% Create a surface plot of peaks data. Store handle to it.
handles.liveStream = imshow(uint8(zeros(1024,1280,3)),'Parent',handles.display);
handles.cam = NaN; % TODO: use EmptyVideoStream instead

set(handles.chooseroi,'Enable','off');
set(handles.startbtn,'Enable','off');
set(handles.stopbtn,'Enable','off');
handles.roi = nan(1,4);
handles.inbuffer = zeros(ceil(5/get(handles.getVideo,'Period')),1);
handles.outbuffer = zeros(ceil(5/get(handles.getVideo,'Period')),1);
hold(handles.respmonitor,'on');
handles.rawsignal = plot(handles.respmonitor,linspace(-5,-get(handles.getVideo,'Period'),numel(handles.inbuffer)),handles.inbuffer);
handles.filteredsignal = plot(handles.respmonitor,linspace(-5,-get(handles.getVideo,'Period'),numel(handles.inbuffer)),handles.outbuffer);
handles.threshold = line(handles.respmonitor,[-5 0],[1 1]*get(handles.threshslider,'Value'),'Color','r');
validchars = ['a':'z' '0':'9'];
handles.task = ws.dabs.ni.daqmx.Task(validchars(randi(36,1,32)));
handles.task.createAOVoltageChan('Dev1',0);
handles.task.start;

% % TODO : constructor
% handles.evm = EVMFilter(30,1,1/60,5/60,1,1,256,256,'butter');

handles.logdump = fopen('dump.txt','w');
handles.logto = handles.logdump;

setappdata(hObject,'a',1);
setappdata(hObject,'b',1);
% END USER CODE

% Update handles structure
guidata(hObject,handles);


% --- Outputs from this function are returned to the command line.
function varargout = vitalcam_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in startbtn.
function startbtn_Callback(hObject, eventdata, handles)
% hObject    handle to startbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% START USER CODE
% Only start timer if it is not running
set(handles.chooseroi,'Enable','off');

% if ~isvalid(handles.liveStream)
%     handles.liveStream = imshow(uint8(zeros(1024,1280,3)));
% end

if strcmp(get(handles.getVideo, 'Running'), 'off')
    start(handles.getVideo);
end

% if strcmp(get(handles.updateDisplay, 'Running'), 'off')
%     start(handles.updateDisplay);
% end
% END USER CODE


% --- Executes on button press in stopbtn.
function stopbtn_Callback(hObject, eventdata, handles)
% hObject    handle to stopbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% START USER CODE
% Only stop timer if it is running
set(handles.chooseroi,'Enable','on');

if strcmp(get(handles.getVideo, 'Running'), 'on')
    stop(handles.getVideo);
end

% if strcmp(get(handles.updateDisplay, 'Running'), 'on')
%     stop(handles.updateDisplay);
% end
% END USER CODE


% --- Executes on slider movement.
function threshslider_Callback(hObject, eventdata, handles)
% hObject    handle to threshslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% % START USER CODE
% % Read the slider value
period = get(handles.threshslider,'Value');
% % Timers need the precision of periods to be greater than about
% % 1 millisecond, so truncate the value returned by the slider
% period = floor(1000*period)/1000;
% % Set slider readout to show its value
set(handles.threshbox,'String',num2str(period))
% % If timer is on, stop it, reset the period, and start it again.
% % wasRunning = strcmp(get(handles.updateDisplay,'Running'),'on');
% % 
% % if wasRunning
% %     stop(handles.updateDisplay);
% % end
% 
% if strcmp(get(handles.getVideo, 'Running'), 'on')
%     stop(handles.getVideo);
%     set(handles.getVideo,'Period',period)
%     start(handles.getVideo)
% else               % If timer is stopped, reset its period only.
%     set(handles.getVideo,'Period',period)
% end

% if wasRunning
%     start(handles.updateDisplay);
% end
% END USER CODE


% --- Executes during object creation, after setting all properties.
function threshslider_CreateFcn(hObject, eventdata,handles)
% hObject    handle to threshslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(groot,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% START USER CODE
function get_video(hObject,eventdata,hfigure)
% Timer timer1 callback, called each time timer iterates.
% Gets surface Z data, adds noise, and writes it back to surface object.
tic;
handles = guidata(hfigure);
fprintf(handles.logto,'Retrieved handles in %f seconds\n',toc);

tic;
if isnan(handles.cam)
    return;
end

if ~handles.cam.hasFrame()
    set(handles.startbtn,'Enable','off');
    return;
end

frame = handles.cam.readFrame();
fprintf(handles.logto,'Retrieved frame in %f seconds\n',toc);
% frame = frame(240+(-127:128),320+(-127:128),:);

% tic;
% frame = handles.evm.filter(frame);
% toc;

switch get(handles.threshtypemenu,'Value')
    case 1
        t = get(handles.threshslider,'Value');
    case 2
        t = get(handles.threshslider,'Value');
    case 3
        if get(handles.applyfilterbox,'Value') == 0
            m = nanmean(handles.outbuffer);
            s = nanstd(handles.outbuffer);
        else
            m = nanmean(handles.inbuffer);
            s = nanstd(handles.inbuffer);
        end
        
        t = m+s*get(handles.threshslider,'Value');
end

set(handles.threshold,'YData',[t t]);

tic;
if ~any(isnan(handles.roi))
    x = max(1,floor(handles.roi(1)));
    y = max(1,floor(handles.roi(2)));
    w = max(1,floor(handles.roi(3)));
    h = max(1,floor(handles.roi(4)));
    v = mean(mean(mean(frame(y:y+h,x:x+w,:),1),2),3);
    
    handles.inbuffer = [handles.inbuffer(2:end); v];
    
    b = getappdata(hfigure,'b');
    p = numel(b);
    
    a = getappdata(hfigure,'a');
    q = numel(a)-1;
    
    % the transpose in the indices for a prevents errors when a is scalar
    w = (sum(b.*handles.inbuffer(end:-1:end-p+1))-sum(a((2:end)').*handles.outbuffer(end:-1:end-q+1)))/a(1);
    
    handles.outbuffer = [handles.outbuffer(2:end); w];
    
    if get(handles.applyfilterbox,'Value') == 0
        u = handles.inbuffer(end-1:end);
    else
        u = handles.outbuffer(end-1:end);
    end
    
    isPositiveSlope = logical(get(handles.posslopebutton,'Value'));
    
    if isPositiveSlope && (u(2) > t && u(1) <= t) || ...
      ~isPositiveSlope && (u(2) < t && u(1) >= t)
        sendTrigger = timer('ExecutionMode','singleShot','StartDelay',get(handles.leddelayslider,'Value')/1000,'TimerFcn', ...
        {@sendLEDPulse handles.task get(handles.leddurslider,'Value')});
        start(sendTrigger);
    end
end

fprintf(handles.logto,'Saved ROI to buffer in %f seconds\n',toc);

tic;
guidata(hfigure,handles);
fprintf(handles.logto,'Saved handles in %f seconds\n',toc);

% function update_display(hObject,eventdata,hfigure)
% tic;
% handles = guidata(hfigure);
% fprintf(handles.logto,'Retrieved handles in %f seconds\n',toc);
% tic;
set(handles.liveStream,'CData',frame);

if size(frame,3) == 1
    colormap(handles.display,gray(255));
end

fprintf(handles.logto,'Showed camera image in %f seconds\n',toc);
tic;
fprintf(handles.logto,'Summed ROI in %f seconds\n',toc);
tic;
% plot(handles.respmonitor,t,handles.outbuffer);

if get(handles.diffcheckbox,'Value') == 0
    ydataRaw = handles.inbuffer;
    ydataFiltered = handles.outbuffer;
else
    ydataRaw = [NaN; diff(handles.inbuffer)];
    ydataFiltered = [NaN; diff(handles.outbuffer)];
end

set(handles.rawsignal,'YData',ydataRaw)
set(handles.filteredsignal,'YData',ydataFiltered)
% arrayfun(@(h,ii) set(h,'YData',ydata(:,ii)),handles.rawsignal,(1:2)');
fprintf(handles.logto,'Plotted ROI sum in %f seconds\n',toc);
tic;
drawROI(handles);
fprintf(handles.logto,'Drew ROI in %f seconds\n',toc);
% END USER CODE

function sendLEDPulse(~,~,task,duration)
samplingRate = 1250; % TODO: not this
samples = ceil(duration*samplingRate/1000);
task.writeAnalogData([5*ones(samples,1); zeros(samples,1)]);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% START USER CODE
% Necessary to provide this function to prevent timer callback
% from causing an error after GUI code stops executing.
% Before exiting, if the timer is running, stop it.
try
    if strcmp(get(handles.getVideo, 'Running'), 'on')
        stop(handles.getVideo);
    end

    % if strcmp(get(handles.updateDisplay, 'Running'), 'on')
    %     stop(handles.updateDisplay);
    % end
    % Destroy timer
    delete(handles.getVideo)
    % delete(handles.updateDisplay)
    delete(handles.cam);

    handles.task.stop;
    handles.task.clear;

    fclose(handles.logdump);
    delete('dump.txt');
catch err
    warning('Error while closing: %s\n',err.message);
end
% END USER CODE

% Hint: delete(hObject) closes the figure
delete(hObject);


function chooseroi_Callback(hObject,eventdata,handles)
roi = imrect(handles.display);
wait(roi);
handles.roi = getPosition(roi);
delete(roi);
drawROI(handles);

guidata(hObject,handles);

function drawROI(handles)
    if any(isnan(handles.roi))
        return;
    end
    
x = handles.roi(1);
y = handles.roi(2);
w = handles.roi(3);
h = handles.roi(4);
line(handles.display,[x x+w x+w x; x+w x+w x x],[y y y+h y+h; y y+h y+h y],'Color','r');


% --- Executes on button press in diffcheckbox.
function diffcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to diffcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of diffcheckbox
% switch get(hObject,'Value')
%     case 0
%         handles.logto = handles.logdump;
%     case 1
%         handles.logto = 1;
% end
% 
% guidata(hObject,handles)


% --- Executes on selection change in videosourcemenu.
function videosourcemenu_Callback(hObject, eventdata, handles)
% hObject    handle to videosourcemenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns videosourcemenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from videosourcemenu

if strcmp(get(handles.getVideo, 'Running'), 'on')
    stop(handles.getVideo);
end

if ~isnan(handles.cam)
    delete(handles.cam);
end

switch get(hObject,'Value')
    case 1
        handles.cam = NaN;
        set(handles.startbtn,'Enable','off');
        set(handles.stopbtn,'Enable','off');
        return;
    case 2
        handles.cam = ThorCam;
        set(handles.getVideo,'Period',0.04);
    case 3
        try
            handles.cam = VideoFileStream;
        catch err
            if strcmp(err.identifier,'VideoFileStream:NoInputFile')
                set(hObject,'Value',1) % TODO : does this reinvoke the callback?
            else
                rethrow(err);
            end
        end
end

set(handles.startbtn,'Enable','on');
set(handles.stopbtn,'Enable','off');

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function videosourcemenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to videosourcemenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function threshbox_Callback(hObject, eventdata, handles)
% hObject    handle to threshbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of threshbox as text
%        str2double(get(hObject,'String')) returns contents of threshbox as a double
validateAndApplyNumericTextEntry(hObject,handles.threshslider);


% --- Executes on button press in filterbutton.
function filterbutton_Callback(hObject, eventdata, handles)
% hObject    handle to filterbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
waitfor(fdatool);

if evalin('base','exist(''Hd'',''var'')')
    G = evalin('base','Hd.ScaleValues');
    SOS = evalin('base','Hd.sosMatrix');
    [b,a] = sos2tf(SOS,G);
elseif evalin('base','exist(''G'',''var'') && exist(''SOS'',''var'')')
    [b,a] = evalin('base','sos2tf(SOS,G)');
else
    return;
end

setappdata(get(hObject,'Parent'),'a',a(:))
setappdata(get(hObject,'Parent'),'b',b(:))

% --- Executes on button press in applyfilterbox.
function applyfilterbox_Callback(hObject, eventdata, handles)
% hObject    handle to applyfilterbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of applyfilterbox



function leddurbox_Callback(hObject, eventdata, handles)
% hObject    handle to leddurbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of leddurbox as text
%        str2double(get(hObject,'String')) returns contents of leddurbox as a double
validateAndApplyNumericTextEntry(hObject,handles.leddurslider);

% --- Executes during object creation, after setting all properties.
function leddurbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to leddurbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function leddurslider_Callback(hObject, eventdata, handles)
% hObject    handle to leddurslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
set(handles.leddurbox,'String',num2str(get(hObject,'Value')));

% --- Executes during object creation, after setting all properties.
function leddurslider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to leddurslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function leddelayslider_Callback(hObject, eventdata, handles)
% hObject    handle to leddelayslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
set(handles.leddelaybox,'String',num2str(get(hObject,'Value')));

% --- Executes during object creation, after setting all properties.
function leddelayslider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to leddelayslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function leddelaybox_Callback(hObject, eventdata, handles)
% hObject    handle to leddelaybox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of leddelaybox as text
%        str2double(get(hObject,'String')) returns contents of leddelaybox as a double
validateAndApplyNumericTextEntry(hObject,handles.leddelayslider);

% --- Executes during object creation, after setting all properties.
function leddelaybox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to leddelaybox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in threshtypemenu.
function threshtypemenu_Callback(hObject, eventdata, handles)
% hObject    handle to threshtypemenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns threshtypemenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from threshtypemenu


% --- Executes during object creation, after setting all properties.
function threshtypemenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshtypemenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in threshbuttongroup.
function threshbuttongroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in threshbuttongroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
