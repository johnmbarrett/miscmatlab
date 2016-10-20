function varargout = pawtControl(varargin)
% PAWTCONTROL MATLAB code for pawtControl.fig
%      PAWTCONTROL, by itself, creates a new PAWTCONTROL or raises the existing
%      singleton*.
%
%      H = PAWTCONTROL returns the handle to a new PAWTCONTROL or the handle to
%      the existing singleton*.
%
%      PAWTCONTROL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PAWTCONTROL.M with the given input arguments.
%
%      PAWTCONTROL('Property','Value',...) creates a new PAWTCONTROL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before pawtControl_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to pawtControl_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pawtControl

% Last Modified by GUIDE v2.5 05-Aug-2016 17:09:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pawtControl_OpeningFcn, ...
                   'gui_OutputFcn',  @pawtControl_OutputFcn, ...
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


% --- Executes just before pawtControl is made visible.
function pawtControl_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pawtControl (see VARARGIN)

% Choose default command line output for pawtControl
handles.output = hObject;
handles.debug = false;

values = get(handles.chooseCOMPortListbox,'String');
ports = getAvailableComPort;
values{end+(1:numel(ports))} = ports{:};
set(handles.chooseCOMPortListbox,'String',values);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pawtControl wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = pawtControl_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in chooseCOMPortListbox.
function chooseCOMPortListbox_Callback(hObject, eventdata, handles)
% hObject    handle to chooseCOMPortListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns chooseCOMPortListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from chooseCOMPortListbox
if get(hObject,'Value') > 2
    enabled = 'on';
else
    enabled = 'off';
end

set(handles.sendParamsButton,'Enable',enabled);


% --- Executes during object creation, after setting all properties.
function chooseCOMPortListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to chooseCOMPortListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function startThreshEditbox_Callback(hObject, eventdata, handles)
% hObject    handle to startThreshEditbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of startThreshEditbox as text
%        str2double(get(hObject,'String')) returns contents of startThreshEditbox as a double
validateAndApplyNumericTextEntry(hObject,handles.startThreshSlider);


% --- Executes during object creation, after setting all properties.
function startThreshEditbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startThreshEditbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function stopThreshEditbox_Callback(hObject, eventdata, handles)
% hObject    handle to stopThreshEditbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stopThreshEditbox as text
%        str2double(get(hObject,'String')) returns contents of stopThreshEditbox as a double
validateAndApplyNumericTextEntry(hObject,handles.stopThreshSlider);


% --- Executes during object creation, after setting all properties.
function stopThreshEditbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stopThreshEditbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function deadTimeEditbox_Callback(hObject, eventdata, handles)
% hObject    handle to deadTimeEditbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of deadTimeEditbox as text
%        str2double(get(hObject,'String')) returns contents of deadTimeEditbox as a double
validateAndApplyNumericTextEntry(hObject,handles.deadTimeSlider);


% --- Executes during object creation, after setting all properties.
function deadTimeEditbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to deadTimeEditbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in risingEdgeRadioButton.
function risingEdgeRadioButton_Callback(hObject, eventdata, handles)
% hObject    handle to risingEdgeRadioButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of risingEdgeRadioButton


% --- Executes on button press in fallingEdgeRadioButton.
function fallingEdgeRadioButton_Callback(hObject, eventdata, handles)
% hObject    handle to fallingEdgeRadioButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of fallingEdgeRadioButton


% --- Executes on slider movement.
function startThreshSlider_Callback(hObject, eventdata, handles)
% hObject    handle to startThreshSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
set(handles.startThreshEditbox,'String',num2str(get(hObject,'Value')));


% --- Executes during object creation, after setting all properties.
function startThreshSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startThreshSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function stopThreshSlider_Callback(hObject, eventdata, handles)
% hObject    handle to stopThreshSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
set(handles.stopThreshEditbox,'String',num2str(get(hObject,'Value')));


% --- Executes during object creation, after setting all properties.
function stopThreshSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stopThreshSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function deadTimeSlider_Callback(hObject, eventdata, handles)
% hObject    handle to deadTimeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
set(handles.deadTimeEditbox,'String',num2str(get(hObject,'Value')));


% --- Executes during object creation, after setting all properties.
function deadTimeSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to deadTimeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in sendParamsButton.
function sendParamsButton_Callback(hObject, eventdata, handles)
% hObject    handle to sendParamsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startThresh = uint16(round(1023*get(handles.startThreshSlider,'Value')/5));
stopThresh = uint16(round(1023*get(handles.stopThreshSlider,'Value')/5));
deadTime = uint16(get(handles.deadTimeSlider,'Value'));
thresholdPolarity = uint8(get(handles.risingEdgeRadioButton,'Value'));

data = num2cell([typecast(startThresh,'uint8') typecast(stopThresh,'uint8') thresholdPolarity typecast(deadTime,'uint8')]);

ports = get(handles.chooseCOMPortListbox,'String');
port = ports{get(handles.chooseCOMPortListbox,'Value')};

fprintf('Sending data to port %s: %#02X 0x%02X 0x%02X 0x%02X 0x%02X 0x%02X 0x%02X\n',port,data{:});

s = serial(port,'BaudRate',115200);
fopen(s);
c = onCleanup(@() fclose(s));
fwrite(s,[data{:}],'uint8');
