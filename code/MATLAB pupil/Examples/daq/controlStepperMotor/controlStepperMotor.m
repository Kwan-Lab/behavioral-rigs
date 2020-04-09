%% Control Stepper Motor using Digital Outputs
%
% This example shows how to control a stepper motor using digital output
% ports.

% Copyright 2012-2014 The MathWorks, Inc.

%% Discover Devices Supporting Digital Output
% To discover a device that supports digital output:
%
% * Issue |daq.getDevices| in the Command window.
% * Click on the device name in the list returned by the command.
devices = daq.getDevices

%%
% This example uses a National Instruments(R) ELVIS II with ID |Dev2|.
% Verify that its digital subsystem supports the |OutputOnly| measurement
% type.
devices(10)

%% Hardware Setup Description
% This example uses a Portescap 20M020D1U 5V 18 Degree Unipolar Stepper
% Motor.  The TTL signals produced by the digital I/O system are amplified
% by a Texas Instruments ULN2003AIN High Voltage High Current Darlington
% Transistor Array, as shown in this schematic:

%%
% 
% <<../controlStepperMotor_setup.png>>
% 

%% Add Digital Output Only Channels
%
% Create a session, and add 4 digital channels on port 0, lines 0-3.  Set
% the measurement type to |OutputOnly|.  These are connected to the four
% control lines for the stepper motor.
s = daq.createSession('ni');
addDigitalChannel(s,'Dev2','port0/line0:3','OutputOnly')

%% Define Motor Steps
% Refer to the Portescap motor wiring diagram describing the sequence of
% 4 bit patterns. Send this pattern sequentially to the motor to produce
% counterclockwise motion. Each step turns the motor 18 degrees. Each cycle
% of 4 steps turns the motor 72 degrees. Repeat this sequence five times to
% rotate the motor 360 degrees.
step1 = [1 0 1 0];
step2 = [1 0 0 1]; 
step3 = [0 1 0 1];
step4 = [0 1 1 0];

%% Rotate Motor
% Use |outputSingleScan| to output the sequence to turn the motor 72
% degrees counterclockwise.
outputSingleScan(s,step1); 
outputSingleScan(s,step2); 
outputSingleScan(s,step3); 
outputSingleScan(s,step4); 

%% 
% Repeat sequence 50 times to rotate the motor 10 times counterclockwise.
for motorstep = 1:50
    outputSingleScan(s,step1); 
    outputSingleScan(s,step2); 
    outputSingleScan(s,step3); 
    outputSingleScan(s,step4); 
end

%% 
% To turn the motor 72 degrees clockwise, reverse the order of the
% steps.
outputSingleScan(s,step4); 
outputSingleScan(s,step3); 
outputSingleScan(s,step2); 
outputSingleScan(s,step1);

%% Turn Off All Outputs
% After you use the motor, turn off all the lines to allow the motor to
% rotate freely.
outputSingleScan(s,[0 0 0 0]);
