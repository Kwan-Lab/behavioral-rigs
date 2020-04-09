function GetPupilVideo (v,s,filename,foldername)
% Each trigger from USB-201 starts a new video, and saves previous one with
% prefix 'filename'. Filename needs to have path as well.
% Run it before Presentation code. Time Event matches in the code.
% FrameRate is 10Hz.
% Requires:
%           DAQ trigger
%           Image Acquisition Toolbox, Image Acquisition Toolbox Support
% Package for Teledyne DALSA Sapera Hardwareand "GigE Vision Hardware"
% support package for camera video recording.
% Check 'imaqhwinfo', should have '" InstalledAdaptors: {'gige'} '"
% Detailed help can be found 'Hardware-Triggered Acquisition with a GigE
% Vision Camera'

% 11/24/2018

%%
global tt

% Connect to Camera
maxTrial = 500;                % Maximum possible trialNum for 'for loop'
cam = getselectedsource(v);
v.ROIPosition = [0 0 320 200];
v.LoggingMode = 'disk';
v.DiskLogger = VideoWriter(filename, 'Uncompressed AVI')

cam.PacketSize = 9000;            % Max avaliable/optimum value.
cam.ExposureMode = 'Timed';       % Set exposure time and mode
triggerconfig(v, 'immediate');      %Default is also 'immediate'
cam.AcquisitionFrameRate = 20;    %10 frames per second. (Max 19.29)

% Specify number of frames to acquire
v.FramesPerTrigger = inf; % 10 frames per second = Records for up
% to 30 seconds for each trial

% DAQ detection start
lh = addlistener(s,'DataAvailable', @stopWhenExceedOneV);
s.NotifyWhenDataAvailableExceeds = 1;
s.IsNotifyWhenDataAvailableExceedsAuto = true;
s.IsContinuous  = true;
startBackground(s);
%% Start Trials / Experiment
cd(foldername)
tt.tend =0;
tt.nextTrial = 0;
FS = stoploop({'Pupil Recording is running', 'Click OK to STOP'}) ; % Set up the stop box
start(v); % start recording
tic




for trialNum=1:maxTrial
    fprintf('Trial # %d started\n', trialNum-1);
    disp('waiting trigger to start next video recording')
    while tt.nextTrial==0
        if FS.Stop()
            trialNum = maxTrial+1;
            tt.nextTrial = 1;
        end

    end
    
    stop(v);
    tic
    data  = getdata(v, v.FramesAvailable,'native' ,'cell'); % After getting the data, start recording immediately.
    disp('data saved');
    TriggerDelayTime = toc;
    tic
    trigger(v);
    startTime=toc;
    pause(0.01);
    fname = [filename,'_',num2str(trialNum-1,'%.3d'),'.mat'];
    save(fname, 'data','TriggerDelayTime', 'startTime');
    
        
    clear data fname nextTrial

    
    
    TriggerDelayTime = toc;
    start(v);pause(0.01);
    tt.nextTrial=0;
    
    if trialNum >=maxTrial %end loop
        stop(v);
        disp('Task is stopped.')
        return
end
%if tt.nextTrial == 1
    stop(v)
%end
save('starttime.mat',  'startTime');
end