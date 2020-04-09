function getDAQinput

s = daq.createSession('mcc')
% addAnalogInputChannel(s,'Dev1',0,'Voltage');
% ch = addCounterInputChannel (s,'Dev1','ctr0','EdgeCount');
t = addAnalogInputChannel(s,'Board0', 0, 'Voltage');

%%
lh = addlistener(s,'DataAvailable', @stopWhenExceedOneV)
s.NotifyWhenDataAvailableExceeds = 1;
s.IsNotifyWhenDataAvailableExceedsAuto = true;
s.IsContinuous  = true;
startBackground(s);
warning('off')

while s.IsRunning  
    pause(0.5)
    fprintf('While loop: Scans acquired = %d\n', s.ScansAcquired)
end

fprintf('Acquisition has terminated with %d scans acquired\n', s.ScansAcquired);


%% FOR TESTING PURPOSES 
devices = daq.getDevices
s.DurationInSeconds = 5;
[data, time] = s.startForeground();
plot(time, data);