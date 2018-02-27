% Script that generates the LED data and images for Cell (goal is to save
% the parameters so I do not have to type them in the future if I change
% the analysis code).

% initialize the folder to save info
clear;
inputPath = 'C:\Users\LSPS\Desktop\Karl_Projects\Experiments starting from 9_1_16\VM to ALM\10_26_16\KG0516\';
cd(inputPath);
path = 'C:\Users\LSPS\Desktop\Karl_Projects\Experiments starting from 9_1_16\VM to ALM\analyzedData\sCRACM\LED\';
folder = 'Cell516';
%%
% Generate header info
header.temperature = 34; %input('Input temperature of experiment (32 or 34): ','s');
header.internal = 'Cs'; %input('Input internal solution used (K or Cs): ','s');
header.drugs = 'TTX,4AP,CPP,ZD'; %input('Input drugs used for experiment (none, CPP, TTX, 4AP): ','s');
header.mouseType = 'Gad2'; %input('Input mouse line (Sepw, Tlx, WT, Gad2xSepw, etc.): ','s');
header.mouseNum = 3; %input('Input the mouse number ID: ','s');
header.slice = 4; %input('Input brain slice number: ','s');
header.distanceToMidline = 900; %input the distance of top of slice to midline in um
header.yFrac = 0.1; %input('Input cell yFrac: ','s');
header.Vm = -56; %input('Input resting membrane potential: ','s');
header.cellNum = 'KG0516'; %input('Input Cell number: ','s');
header.cellPos = 'ipsi_L2'; %input('Input location of the cell (i.e. ipsi_L23 or contra_L5): ','s');
header.cellDepth = -64; %input('Input cell depth in um: ','s');
header.cellType = 'IT'; % Presumed cell type based on labeling an morphology during patching ('Pyramidal' or 'Internueron')
header.Rm = 245;
header.Cm = 191;
header.Tau = 0.0013;
%%
% analyzed data
close all;
%%
LED_2000amp = pulse_analyzer(header.cellNum,[3,4,8],'-70','LED','VC',50);
%%
initialTrace = header.cellNum;
traces = [3 4 8];
holdingVolt = '-70';
recordMode = 'VC';
stimType = 'LED';
msWin = 50;
pulse_analyzer3; %(header.cellNum,[3,4,8],'-70','LED','VC',50);
%%
saveas(figure(1),strcat(path,folder,'\LED_2000amp.fig'));
close all;
save(strcat(path,folder,'\',folder,'.mat'),'header','LED_2000amp');
cd(strcat(path,folder));