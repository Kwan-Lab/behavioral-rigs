function nextTrial = endWhenExceedOneV(src, event)
global tt
if any(event.Data(:,2) > 4)
    disp('Event listener: Detected voltage exceeds 1, Trigger Received.')
    % Continuous acquisitions need to be stopped explicitly.
    tt.end = 1;
    tt.nextTrial = 1;
    %        plot(event.TimeStamps, event.Data)
else
    %         disp('Event listener: Continuing to acquire')
end

if tt.tend==1
    src.stop();
end
