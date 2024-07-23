close all; clear;

lib = "DTAG3_Analysis\";
fullpath_lib = genpath(lib);
addpath(fullpath_lib);

%% FIRST-TIME SETUP: Run this section to select main tag data directory

% Use this function to select the main data directory (directory that contains
% the folders of all the tag sessions)
select_data_dir();

%% Set up environment and path to data - Perform this step every time

% Add DTag library to path
addpath(genpath('dtagLib/'), 'DTAG3_Analysis/orientLib/');

% Set main data directory
if ~exist('data_dir.mat', 'file')
    disp('No data directory file found: Run previous section')
end
dir_st = load('data_dir.mat');
data_dir = dir_st.dirname;

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
% rec_name = 'gm22_222b'; % Pilot whale
% rec_name = 'bm22_060a'; % Blue whale
% rec_name = 'mn22_198a'; % humpback whale
depid = 'DTAG320H_test7';

% Set file paths
filepath = sprintf('%s%s', data_dir, depid);
addpath(genpath(filepath));

% Set decimation factor. Leave at df=1 for no decimation, otherwise df should be
% set to an integer divisor of the main sampling frequency
df = 10;

% Set low-pass filtering windows. Format is [accel., mag., depth]. Default is
% [0, 0, 0], each corresponds to the window [s] used in Savitsky-Golay filtering
% applied before auto orientation estimation. Recommended < 0.5s windows. Use
% only when raw data is highly noisy.

lpf = [0 0 0];

% Add filter parameters to struct (addtl params will be added in later versions)
filt_pars = ([]);
filt_pars.lpf = lpf;

% Set orientation estimation method to 'manual' or 'auto'. 'auto' is recommended
est_mthd = 'auto';

%% RECOMMENDED: Set parameters for automatic orientation extraction method

% Set animal type to the lowercase abbreviation of the scientific name
% Examples:
%   NA Right Whale:     eg
%   Bottlenose Dolphin: tt
%   Humpback Whale:     mn
%   Sei Whale:          bb
%   Pilot Whale (SF):   gm
%   Blue Whale:         bm
%   Beluga:             dl
animal_type = 'mn';

% Boolean flag to load parameters generally known to work for this animal type.
% If this fails, you will need to enter the parameters manually
load_common = true;
if load_common      % Load common parameters if they exist
    try
        load(['orientLib/common_pars/', animal_type, '.mat']);
    catch
        disp('No common parameter set found - set parameters manually.')
    end
else                % Set the parameters manually
    % Window sizes for pose calculations
    wd_st = 15; % [s] For magnetometer method, set to roughly 3 * period.
    wd_n = 2.5; % [s] For naive method, set to roughly one-half period.
    
    % Parameters for peak detections, related to the gait of the animal.
    min_amplitude = 3; % [degree], Minimum allowed amplitude of fluke detection
    max_period = 25; % [s], Maximum fluke period generally observed
    
    % Method control. scalar value: 1, 2, or [] indicates 
    % the method to use when fitting to data. "1" works for the
    % case where the animal rolls more and does shallower dives.
    % '2' works for the case where the animal does deeper dives.
    % '[]' lets the program to decide which one to use by
    % checking which one gives more fitting inliers.
    % The default value is '[]', letting the program run in auto.
    correction_method = [];
end

% Define section length, the method assumes each section contains 1 or 0
% tag slides instance. If this value is too small, each section may not 
% contain enough data to form a distribution. If this value is too big, the
% resolution of slide detection is low.
section_dur_min = 15; % [minute], originally 15

% Threshold for detecting tag slides, when inlier density drops below this
% threshold, a tag slide is detected. Higher threshold makes the method
% more sensitive, thus increase the amount of detected slides (including
% false positives too).
density_thrs = 0.45; % originally 0.45

% Add parameters to automatic orientation estimation structure
apars = ([]);
apars.wd_st = wd_st;
apars.wd_n = wd_n;
apars.min_amplitude = min_amplitude;
apars.max_period = max_period;
apars.correction_method = correction_method;
apars.section_dur_min = section_dur_min;
apars.density_thrs = density_thrs;

%% Export raw voltages - Can be run separately to test tag without calibration
% This allows tag data to be viewed even if the cal file for the tag is missing.
% Raw voltages are exported in this section

% Extract data structure
TagData.RawVolt = dtag3_test(filepath, depid, df);

% Extract magnetometer 1 (M1), magnetometer 2 (M2), accelerometer (A), and
% pressure (P) data streams. Generate time vector to match data length
M1 = cell2mat(TagData.RawVolt.x(1:3)');
M2 = cell2mat(TagData.RawVolt.x(4:6)');
A = cell2mat(TagData.RawVolt.x(7:9)');
P = TagData.RawVolt.x{10};
time_rv = (0:(length(M1) - 1))/(TagData.RawVolt.fs(1)*60); % Time in minutes

% Plot to examine raw sensor voltage data
figure
ax(1) = subplot(411);
plot(time_rv, A(1:2:end,:)); ylabel('A Volt');
title('Onboard Sensor Test'); legend('X', 'Y', 'Z', 'Location', 'northwest');
ax(2) = subplot(412);
plot(time_rv, M1); ylabel('M1 Volt');
ax(3) = subplot(413);
plot(time_rv, M2); ylabel('M2 Volt');
ax(4) = subplot(414);
plot(time_rv, P(1:2:end)); ylabel('P Volt'); xlabel('Time (min)');
linkaxes(ax, 'x')

fs = max(TagData.RawVolt.fs);
disp(['Base sampling frequency: ', num2str(fs), 'Hz'])

%% MAIN CALIBRATION - Use this section to fully extract sensor data
% NOTE: THIS REQUIRES HAVING THE CAL FILE FOR THE TAG IN THE D3MATLAB/CAL FOLDER

% Perform data calibration
if strcmp(est_mthd, 'auto')
    TagData = calibrate_tag(filepath, depid, df, apars, filt_pars, est_mthd);
else
    TagData = calibrate_tag(filepath, depid, df, mpars, filt_pars, est_mthd);
end

%% Save Data to File
filename = depid + ".mat";
fullpath = filepath + "\" + filename;

save(fullpath, 'TagData');

%% Clean up libraries
rmpath(fullpath_lib);