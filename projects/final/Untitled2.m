f = warndlg('Push the button to stop the loop.', 'Stop the loop.'); % Simple GUI
cnt = 1;
while 1
    cnt = cnt + 1;
    if ~ishandle(f) % Begin added parts
        break
    end
    drawnow % End added parts
end