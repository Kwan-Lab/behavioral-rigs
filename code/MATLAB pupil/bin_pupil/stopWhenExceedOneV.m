function nextTrial = stopWhenExceedOneV(src, event)
global tt
%global lhDelay

% tic
if any(event.Data(:,1)> 4)
    %tic
    disp('Event listener: Detected voltage exceeds 1, Trigger Received.')
    % Continuous acquisitions need to be stopped explicitly.
    tt.nextTrial = 1;
    % event.Data
    %figure;
    %plot(event.TimeStamps, event.Data(:,1))
    %lhDelay = toc;
else
    %         disp('Event listener: Continuing to acquire')
end

if tt.tend==1
    src.stop();
end

%


