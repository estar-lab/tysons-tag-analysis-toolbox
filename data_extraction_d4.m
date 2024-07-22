clear; close all;

lib = "DTAG4_Analysis\";
fullpath = genpath(lib);
addpath(fullpath);

% Pick an appropriate deployment id. Usually you would follow the standard
% DTAG protocol of: 2-letter Latin species initials, 2-digit year, underscore,
% 3-digit Julian day of year, 1-letter animal of the day.
% Use julian_day() if you need to convert a date to a day number.

%% CHANGE THIS STUFF

% The variables 'depid' and 'filepath' mean the same thing, and you
% to use the same values across all scripts. Make sure you set these variables before running 
% any script that has them. 
% 
% A note on what to set them to - if your file hierarchy looks like this:
% .
% ├── mn24_010a
% │   ├── mn24_010a002.dtg
% │   └── mn24_010a002.bin
% │   └── mn24_010a002.xml
% │   └── (more files)
% ├── more data directories
% 
% 'depid' would be would be 'mn24_010a'. The naming convention here follows
% 'depid'XXX.filetype. So it is important that the foldername matches the name of your files. 
% 
% 'filepath' would be the path into the folder that contains the folder mn24_010a\. For me that happens to be
% "C:\Users\tyson\Documents\ESTAR\DTAG Drift\Data\"

depid = 'mn24_010a';

% Give the directory where the raw data is.
filepath = 'C:\Users\tyson\Documents\ESTAR\DTAG Drift\Data\';

%% Continue with script

recdir = [filepath, depid];

% Read in the raw data, for example using one of the following:
% X = d3readswv_commonfs(recdir,depid,5) ;		% decimates to a common 5 Hz sampling rate
% or
% X = d3readswv_commonfs(recdir,depid,25) ;		% decimates to a common 25 Hz sampling rate
% or
% X = d3readswv(recdir,depid,5) ;		% decimates each channel by a factor of 5
% If you need to find out what the original sampling rates are of the different sensors, use:
% X = d3readswv(recdir,depid,'info')
X = d3readswv_commonfs(recdir,depid,50);

%% Generate sensor structures for each of the data types.
% Note that the sensor channels may change if your tag was recording a different
% set of sensors (e.g., ECG, light). Use d3channames if in doubt.

A0 = sens_struct([X.x{1:3}],X.fs(1),depid,'acc') ;	% acceleration
M = sens_struct([X.x{4:6}],X.fs(4),depid,'mag') ;	% magnetometer
T0 = sens_struct(X.x{7},X.fs(7),depid,'temp') ;	    % temperature
P0 = sens_struct(X.x{8},X.fs(8),depid,'press') ;	% pressure

ratio = A0.sampling_rate/P0.sampling_rate;
A0.data = downsample(A0.data,ratio);
A0.sampling_rate = P0.sampling_rate;
T0.data = downsample(T0.data,T0.sampling_rate/A0.sampling_rate);
P0.data = downsample(P0.data,P0.sampling_rate/A0.sampling_rate);
T0.sampling_rate = A0.sampling_rate;
P0.sampling_rate = A0.sampling_rate;

time_rv = (0:(length(M.data) - 1))/(X.fs(1)*60); % Time in minutes

lengths = [length(A0.data) length(M.data) length(T0.data) length(P0.data) length(time_rv)];
lim = min(lengths);
A0.data = A0.data(1:lim,:);
M.data = M.data(1:lim,:);
T0.data = T0.data(1:lim,:);
P0.data = P0.data(1:lim,:);
time_rv = time_rv(1:lim);

%%
figure

axs(1) = subplot(311);
plot(time_rv,P0.data)
xlabel('Time (min)')
ylabel('Pressure')

axs(2) = subplot(312);
plot(time_rv,A0.data)
xlabel('Time (min)')
ylabel('Raw Acceleration')

axs(3) = subplot(313);
plot(time_rv,M.data)

xlabel('Time (min)')
ylabel('Raw Magnetometer')

linkaxes(axs, 'x')

%% Calibrate the Data 

CAL = d4findcal(recdir,depid) ;  % get the calibration constants for this tag

%% Make sure M is centered
figure
mag = M.data;
plot3(mag(:,1),mag(:,2),mag(:,3),'.')
hold on
plot3(1,0,0,'rx')
plot3(0,0,1,'rx')
hold off
axis equal
xlabel('x')
ylabel('y')
zlabel('z')
view([0,90])
view([90,0])
Mmag = sqrt(sum(M.data.^2,2));
histogram(Mmag)
idx_cal = find(~isnan(A0.data(:,1)) & P0.data>0.5 & Mmag<0.7);
% idx_cal = find(~isnan(P0.data>0.5&Mmag<0.3));
[mag, idx_cal] = mag_calib(M.data, A0.data, -P0.data,idx_cal);
M.data = mag;

%% Calibrate Temperature, Pressure and Acceleration

T = apply_cal(T0,CAL.TEMP) ;			% apply cal to the temperature

% The temperature measurement is internal to the tag and is not very
% accurate. It cannot be used as a water temperature measurement without
% careful calibration. It is however useful for compensating temperature
% effects in the sensors. This is why it has to be calibrated first.

P = apply_cal(P0,CAL.PRESS,T) ;		% apply cal to the pressure

% Apply the calibration and map to get the final tag-frame accelerometer data:
A = apply_cal(A0,CAL.ACC) ;

% Plot the pressure and check if it is correct when the animal surfaces.
figure
time = (1:length(P.data))/P.sampling_rate/3600; % Unit hour.

subplot(311)
plot(time, P.data)
xlabel('time [hour]')
ylabel('depth [meter]')

subplot(312)
time_p = (1:length(P.data))/P.sampling_rate/3600; % Unit hour.
plot(time, A.data)
xlabel('time [hour]')
ylabel('Accel [m/s^2]')

subplot(313)
time_p = (1:length(P.data))/P.sampling_rate/3600; % Unit hour.
plot(time, M.data)
xlabel('time [hour]')
ylabel('Mag []')

%% Save Data
filename = depid + ".mat";
fullpath = recdir + "\" + filename;
save(fullpath, 'A', 'M','P','time');