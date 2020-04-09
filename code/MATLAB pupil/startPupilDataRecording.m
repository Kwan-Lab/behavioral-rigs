
%%%%  Start Pupil Size Data Aqusition

%% Check Camera connection
fprintf('Please start NBS code AFTER entering subject ID.\nNow, setting up camera and DAQ might take a minute or so.\nProcessing...\n');

v = videoinput('gige', 1, 'Mono8');
if isempty(v)
    warning(' Camera is not properly connected/ check adapter.');
    % check details in 'GetPupilVideo.m'
else
    disp('1/2: Camera is working correctly.');
end

%% Check DAQ connection
s = daq.createSession('mcc');
t = addAnalogInputChannel(s,'Board0', 0, 'Voltage'); % Gets input from 5th, 32 from NBS DAQ

%adding another channel for save code
z = addAnalogInputChannel(s, 'Board0', 1, 'Voltage');

if isempty(s)
    
    warning(' DAQ is not properly connected/ check adapter.');
else
    disp(' 2/2: DAQ is working correctly.');
end
%% Create fileName & Ask for the subject number - Matched to NBS
prompt = {'Subject Name/ID:';'Phase'};
title = 'Enter subject ID';
dims = [1 35];
definput = {'1800';'2'};
temp = newid(prompt,title,dims,definput); %modified version of 'inputdlg'
subj  = temp{1};
phaseID = str2double(temp{2});
if phaseID ==1; phase='phase2_algo1_WithPupil';
elseif phaseID==2; phase='phase2_algo2_WithPupil'; end
[c] = clock;

Sesname = ['M', subj,'_'...
    phase,'_',num2str(c(1)-2000,'%.2d'),num2str(c(2),'%.2d'),num2str(c(3),'%.2d'),...
    num2str(c(4),'%.2d'),num2str(c(5),'%.2d')];

foldername = ['C:\Users\kwanlab\Documents\rawPupilData\',Sesname]; % Fila=eFormat matched to the PRESENTATION LOGFILE
filename   = fullfile(foldername,[Sesname,'.avi']);
if exist(filename)
    error('This filename was used before, please check the folder!')
else
    mkdir(foldername)
end

GetPupilVideo_whole(v,s,filename,foldername);


delete(v);
clear all
close all
clear global
