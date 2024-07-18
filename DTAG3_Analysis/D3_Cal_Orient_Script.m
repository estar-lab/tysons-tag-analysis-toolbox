%% Script for processing and testing data sets

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

% Set recording name. This assumes the files have the same name structure as the
% folder (see the provided rec_name for an example)
% rec_name = 'gm22_222b'; % Pilot whale
% rec_name = 'bm22_060a'; % Blue whale
% rec_name = 'mn22_198a'; % humpback whale
% rec_name = 'HTest_345'; 
% rec_name = 'bb22_115e';
% rec_name = 'gm23_220a';
% rec_name = '2023-09-11-Nic-9am';
% rec_name = 'Tag405_TestV2';s
% rec_name = 'Tag302_Test';
% rec_name = 'pm23_205a';
% rec_name = 'bm22_060a';
% rec_name = 'tt23_177b';
% rec_name = 'Tag348_Test';
% rec_name = 'Tag340_Test';
% rec_name = 'bp22_068b';
% rec_name = 'DLT20001';
%rec_name = 'DLT20002';
rec_name = 'DTAG320H_test5';

% Set file paths
dir_name = sprintf('%s%s', data_dir, rec_name);
addpath(genpath(dir_name));

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
animal_type = 'dl';

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


%% OPTIONAL: Set parameters for manual orientation estimation method (NOT RECOMMENDED)

% Set initial estimated orientation of tag on deployment. orientTag has a
% structure of: [time_mounted, 0, pitch, roll, heading]. time_mounted is the
% time in seconds in the recording when the tag is mounted on the animal. pitch,
% roll, and heading represent the tag orientation with respect to the animal.
% orientTag can be left as all zeros if the tag orientation will be estimated by
% prhpredictor (on by default, to disable prhpredictor quit it when it appears
% using the provided controls)
orientTag = zeros(1,5);

% Set dive depth threshold for tag orientation estimator (prhpredictor)
TH = 10;

% Set computation method for tag orientation estimator (prhpredictor). Use 
% est_method = 1 for logging-diving animals, e.g. sperm whales. Use
% est_method = 2 for whales that make short dives while respiring, e.g., beaked
% whales
est_method = 2;

% Set dive direction constraint for tag orientation estimator (prhpredictor). 
% Use 'both' to use ascents and descents, 'ascent' to reject descents, and 
% 'descent' to reject ascents. This can be chosen to better match an animal's
% dive patterns.
dive_dir = 'descent';

% Set maximum condition threshold for tag orientation estimator (prhpredictor).
% Values range from [0, 1], where 0 rejects PRH predictions of all conditions
% and 1 accepts predictions of all conditions (lower is better).
trc = 0.25;

% Add parameters to manual orientaion estimation structure
mpars = ([]);
mpars.orientTag = orientTag;
mpars.TH = TH;
mpars.METHOD = est_method;
mpars.dive_dir = dive_dir;
mpars.trc = trc;


%% Export raw voltages - Can be run separately to test tag without calibration
% This allows tag data to be viewed even if the cal file for the tag is missing.
% Raw voltages are exported in this section

% Extract data structure
TagData.RawVolt = dtag3_test(dir_name, rec_name, df);

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


%% Analyze wav file (optional) - Only run after previous section has been run

% Get first audio file in folder for testing
au_list = dir([dir_name, '/', rec_name, '*.wav']);
au_fname = [au_list(1).folder, '/', au_list(1).name];
au_info = audioinfo(au_fname);

% Specify interval (necessary, data too large otherwise) and read audio
itv = [3 6]; % Set interval in minutes, 10 minute max duration recommended
[wav, wfs] = audioread(au_fname, 60*itv*au_info.SampleRate);

% Generate time vector for audio file
wfs_plot = 10000; % Set lower sample rate for plotting (to prevent crashes)
au_dec = au_info.SampleRate/wfs_plot;
au_time = itv(1):1/(60*wfs_plot):itv(2);

% Plot to examine audio gain data per channel
figure
wax(1) = subplot(211);
plot(au_time, wav(1:au_dec:end,1)); ylabel('Left (Frac. Full Range)');
title('Hydrophone Test (Note: Plot uses decimated data)')
wax(2) = subplot(212);
plot(au_time, wav(1:au_dec:end,2)); ylabel('Right (Frac. Full Range)');
xlabel('Time (min)');
linkaxes(wax, 'x')


%% MAIN CALIBRATION - Use this section to fully extract sensor data
% NOTE: THIS REQUIRES HAVING THE CAL FILE FOR THE TAG IN THE D3MATLAB/CAL FOLDER

% Perform data calibration
if strcmp(est_mthd, 'auto')
    TagData = calibrate_tag(dir_name, rec_name, df, apars, filt_pars, est_mthd);
else
    TagData = calibrate_tag(dir_name, rec_name, df, mpars, filt_pars, est_mthd);
end


%% Load calibration file and parse - For analysis and re-plotting

% Extract data structure (to obtain sampling frequency)
X = dtag3_test(dir_name, rec_name, df);
fs = X.fs(7); clear X;

% Set TagData folder name
tdata_fldname = [dir_name, '/tagdata_', num2str(fs), 'hz/'];

% Set file indices to load: TagData sub-files are numbered, and this allows for
% all or a subset of the sub-files to be used to rebuild TagData in the event of
% long recording sessions. Sub-files are 1-hour intervals (except last file).
% Set fidx = [] to use all files, otherwise, set fidx to CONTINUOUS list of
% integer indices to process (e.g. fidx = 2:4). Indices out of range are culled.
fidx = [];

% Load and merge calibrated data structures into original complete structure
TagData = calib_data_merge_idx(tdata_fldname, fidx);


%% Primary plot for Automatic Orientation Estimator

% Full plot of depth, pose, gait signal, fluke frequency, fluke amplitude
auto_orient_res_plt(TagData);


%% Secondary plots for Automatic Orientation Estimator (produces MANY plots)

% Inlier density plot for tag slip estimation <--- This sometimes breaks when a
% subset of the tag data is loaded instead of the entire session, if so just
% comment it out.
inlier_density_plt(TagData);

% Secondary gait parser

parse_gait_plt(TagData);

% Plot orientation info before corrections are applied
% Choose 'section' for the first section to be plotted, otherwise choose
% 'all_data' for all data to be plotted
% choice = 'section';
choice = 'section';
pre_orient_correct_plt(TagData, 'all_data')
% pre_orient_correct_plt(TagData, 'section')

%% Additional plots for comparing uncalibrated to calibrated tag data

fs = TagData.sampleFreq;

% Plot uncalibrated tag data
figure
ax1(1) = subplot(311);
plot(TagData.timeSec, TagData.accelTagOrig)
ylabel('Orig. A (g)'); title(['Uncalibrated Tag Data - ', num2str(fs), ' Hz']);
legend('X', 'Y', 'Z', 'Location', 'northwest');
ax1(2) = subplot(312);
plot(TagData.timeSec, TagData.magTagOrig); ylabel('Orig. M (\mu{}T)');
ax1(3) = subplot(313);
plot(TagData.timeSec, -TagData.depthOrig); ylabel('Orig. Depth (m)');
xlabel('Time (s)')
linkaxes(ax1, 'x')

% Plot calibrated tag data
figure 


ax2(1) = subplot(311);
plot(TagData.timeSec, TagData.accelTag)
ylabel('Calib. A (g)'); title(['Calibrated Tag Data - ', num2str(fs), ' Hz']);
legend('X', 'Y', 'Z', 'Location', 'northwest');
ax2(2) = subplot(312);
plot(TagData.timeSec, TagData.magTag); ylabel('Calib. M (\mu{}T)');
ax2(3) = subplot(313);
plot(TagData.timeSec, TagData.depth); ylabel('Calib. Depth (m)');
xlabel('Time (s)')
linkaxes(ax2, 'x')


