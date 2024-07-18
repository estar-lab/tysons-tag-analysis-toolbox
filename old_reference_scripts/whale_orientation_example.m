function [filt_data] = filter_mtag_data(data, folder_root, print_fig_bool)
% This function is based on work by Ding Zhang, with only slight changes to
% the intrface by Gabriel Antoniak to make it work with the set-up
% organization scheme. This funtion is called by MTAG_Analysis, which is
% called from DQO_Data

addpath(genpath([pwd, '/MTAG_Library']), pwd);

if (nargin < 2)
   folder_root = './'; 
end

if (nargin < 3)
   print_fig_bool = false; 
end

filt_data = struct;
sample_freq = 50;

A_org = data.A;
M_org = data.M;
G_org = data.G;
Depth = data.Depth;

% Fluke period = 0.9 s
% Window sizes for pose calculations.
wd_static = ceil(3*sample_freq); % For magnetometer method.
wd_naive = ceil(0.5*sample_freq); % For naive method.

% Parameters for peak detections.
min_amplitude = 5; % [degree]
max_period = 3; % [s].

correction_method = 1;

% Define section length, the method assumes each section contains 1 or 0
% tag slides instance. If this value is too small, each section may not
% contain enough data to form a distribution. If this value is too big, the
% resolution of slide detection is low.
section_dur_min = 15; % [minute]

% Threshold for detecting tag slides, when inlier density drops below this
% threshold, a tag slide is detected. Higher threshold makes the method
% more sensitive, thus increase the amount of detected slides (including
% false positives too).
density_thrs = 0.45;

% Flag for plot control.
plot_on = true;
try
    % Give error for very short datasets.
    [sec_idx_list, in_density_forward, in_density_reverse] =...
        find_tag_slide_times_func(A_org, Depth, sample_freq, section_dur_min,...
        density_thrs, plot_on);
catch
    % For a very short dataset, take it as one data segment for tag
    % orientation handling.
    disp("Error running tag shift detection, likely due to short dataset.")
    disp("Now taking the entire dataset as one data segment for fixing tag orientation")
    sec_idx_list = [1; length(A_org)];
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Section 3. Correct rotation for each data section, seperated by
% identified tag sliding times.

% Plot control. When visualizing data, data
% points are plotted every 'plot_interval', so the plot is
% not too dense. I.e. plot(Acc(1:plot_interval:n,:))
% Set to '[]' (i.e. plot_interval = [], also is default) to
% use automatic plot interval, so a fix number of points are
% shown. Set to 0 to turn off plot.
plot_interval = 0;


% 1-by-1 scalar, defines the depth threshold for
% animal surfacing events, and excludes those for orientation
% anlysis. This is because animal can sometimes perform
% confusing non-swimming behavior at the surface, and
% confuses the method.
% Set to '[]' (i.e. surf_depth = []) to include all data.
% The default value is '[]'.
surf_depth = [];

% Initializations for the data after tag orientation correction.
A2 = [];
M2 = [];
rot_mat_temp = [];


% Dolphin dataset has gyroscope data.
G2 = [];


for i_sec = 1:length(sec_idx_list)-1
    i_s = sec_idx_list(i_sec);
    i_e = sec_idx_list(i_sec+1);
    i_use = i_s:i_e;
    rot_mat_temp{i_sec} = find_tag_orientation_func(A_org(i_use,:), Depth(i_use,:),...
        sample_freq, surf_depth, plot_interval, correction_method);
    A2(i_use,:) = A_org(i_use,:)*rot_mat_temp{i_sec};
    M2(i_use,:) = M_org(i_use,:)*rot_mat_temp{i_sec};
    G2(i_use,:) = G_org(i_use,:)*rot_mat_temp{i_sec};
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Section 4. (Only when needed) Show data before orientation corrections:
% all data or data for a particular section.
if 0
    %%
    surf_depth = [];
    plot_interval = [];
    choice = 'section'; % 'all_data' or 'section'
    
    switch choice
        case 'all_data'
            find_tag_orientation_func(A_org, Depth, sample_freq,...
                surf_depth, plot_interval, correction_method);
        case 'section'
            i_sec = 1;
            i_s = sec_idx_list(i_sec);
            i_e = sec_idx_list(i_sec+1);
            i_use = i_s:i_e;
            find_tag_orientation_func(A_org(i_use,:), Depth(i_use,:),...
                sample_freq, surf_depth, plot_interval, correction_method);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Section 5. (Only when needed) Manually define dominant vectors for a data
% segment to correct tag orientation, in case the automatic method's
% performance is not ideal for a particular section.

if 0
    i_sec = 1;
    i_s = sec_idx_list(i_sec);
    i_e = sec_idx_list(i_sec+1);
    i_use = i_s:i_e;
    
    choice = 'manual'; % 'manual' or 'auto'
    
    switch choice
        case 'manual'
            D_flat = [-0.0165, 0.0057, 0.99948]; % Important.
            D_descend = [-0.2924, 0.0768, 0.9627]; % Important.
            D_ascend = [0.2803, -0.073, 0.9519]; % Secondary.
            
            rot_mat = find_tag_orientation_manual_func(A2(i_use,:), Depth(i_use,:),...
                sample_freq, D_flat, D_ascend, D_descend, surf_depth, plot_interval);
            
        case 'auto'
            rot_mat = find_tag_orientation_func(A_org(i_use,:), Depth(i_use,:),...
                sample_freq, surf_depth, plot_interval, correction_method);
    end
    
    % Apply the rotation if happy with the orientation
    A2(i_use,:) = A2(i_use,:)*rot_mat;
    M2(i_use,:) = M2(i_use,:)*rot_mat;
    
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Section 6a. Naive method calculating roll, pitch, yaw and then dynamic pose.

[roll_niv, pitch_niv, yaw_niv, Ag_niv, As_niv] =...
    calc_rpy_naive(A2, M2, sample_freq, wd_naive);

[pitch_dp_nv, yaw_dp_nv, vector_dp_nv, ...
    roll_filt_nv, pitch_filt_nv, yaw_filt_nv] =...
    calc_dynamic_pose(roll_niv, pitch_niv, yaw_niv, wd_static);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Section 6b. Other methods calculating roll, pitch, yaw and then dynamic pose.

if 0
    %% Magnetometer method.
    [roll_mag, pitch_mag, yaw_mag, Ag_mag, As_mag, rt, bl_singular] =...
        calc_rpy_magnetometer(A2, M2, sample_freq, wd_static, wd_naive);
    
    [pitch_dp_mag, yaw_dp_mag, vector_dp_mag,...
        roll_filt_mag, pitch_filt_mag, yaw_filt_mag] =...
        calc_dynamic_pose(roll_mag, pitch_mag, yaw_mag, wd_static);
end


%% Magdwick's method, requires gyroscope data.
[As_mdg, Ag_mdg, roll_mdg_rad, pitch_mdg_rad, yaw_mdg_rad, rot_mat_mdg] =...
    madgwick_filt(A2, G2, M2, 1/sample_freq);

roll_mdg = rad2deg(roll_mdg_rad);
pitch_mdg = -rad2deg(pitch_mdg_rad);
yaw_mdg = rad2deg(yaw_mdg_rad);

[pitch_dp_mdg, yaw_dp_mdg, vector_dp_mdg,...
    roll_filt_mg, pitch_filt_mg, yaw_filt_mg] =...
    calc_dynamic_pose(roll_mdg, pitch_mdg, yaw_mdg, wd_static);

filt_data.specific_acceleration = As_mdg;
filt_data.acceleration = Ag_mdg;
filt_data.pitch_dynamic_pose = pitch_dp_mdg;
filt_data.yaw_dynamic_pose = yaw_dp_mdg;
filt_data.roll_dynamic_pose = asind(vector_dp_mdg(:, 1));
filt_data.vector_dynamic_pose = vector_dp_mdg;
filt_data.vector_pose = [ roll_filt_mg pitch_filt_mg yaw_filt_mg ];
filt_data.raw_vector_pose = [roll_mdg pitch_mdg yaw_mdg];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Section 7. Fluke and glide detection and characterization.
signal = pitch_dp_mdg;

plot_on = true;
signal_name = "pitch_{dp}";
signal_unit = "deg";

[frequency_filt, amplitude_filt, period_filt, bool_active,...
    frequency_at_peaks, amplitude_at_peaks, period_at_peaks,...
    positive_peaks, negative_peaks] =...
    parse_gait(signal, sample_freq, min_amplitude, max_period,...
    plot_on, signal_name, signal_unit);

filt_data.frequency = frequency_filt;
filt_data.amplitude = amplitude_filt;
filt_data.period    = period_filt;
filt_data.frequency_at_peaks = frequency_at_peaks;
filt_data.amplitude_at_peaks = amplitude_at_peaks;
filt_data.period_at_peaks = period_at_peaks;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Section 8. Plot depth, pose, gait signal, fluke frequency, and fluke
% amplitude.

time = (1:length(A_org))'/(sample_freq);
time_unit = 's';

fig = figure;
m_pk = 5;

lw = 1.2;
lw2 = 1.2;

font_size = 12;

i_p = 1;
ax_pk(i_p) = subplot(m_pk,1,i_p);
hold on
plot(time, Depth, 'k-', 'lineWidth', lw)
grid on
ylabel('Depth (m)', 'FontSize', font_size)


i_p = i_p + 1;
ax_pk(i_p) = subplot(m_pk,1,i_p);
hold on
plot(time, roll_niv, 'k-', 'lineWidth', lw)
plot(time, pitch_niv, 'b-', 'lineWidth', lw)
plot(time, yaw_niv, 'r-', 'lineWidth', lw)
grid on
ylabel('Orientation (deg)', 'FontSize', font_size)
legend('roll', 'pitch', 'yaw',...
    'FontSize', font_size, 'Orientation','horizontal')
legend('boxoff')


i_p = i_p + 1;
ax_pk(i_p) = subplot(m_pk,1,i_p);
plot(time, signal, 'k-', 'lineWidth', lw2)
hold on
plot(time, positive_peaks, '^')
plot(time, negative_peaks, 'v')
plot(time(~bool_active), signal(~bool_active), 'r.')

grid on
ylabel('Pitch_{dp} (deg)', 'FontSize', font_size)
legend('signal', 'positive peak', 'negative peak', 'inactive',...
    'FontSize', font_size, 'Orientation','horizontal')
legend('boxoff')


i_p = i_p + 1;
ax_pk(i_p) = subplot(m_pk,1,i_p);
plot(time, frequency_at_peaks, 'bo', 'lineWidth', lw2)
hold on
plot(time, frequency_filt, 'k-', 'lineWidth', lw2)
grid on
ylabel('Frequency (Hz)', 'FontSize', font_size)
legend('at-peak', 'filtered', 'FontSize', font_size, ...
    'Orientation','horizontal')
legend('boxoff')


i_p = i_p + 1;
ax_pk(i_p) = subplot(m_pk,1,i_p);
plot(time, amplitude_at_peaks, 'bx', 'lineWidth', lw2)
hold on
plot(time, amplitude_filt, 'k-', 'lineWidth', lw2)
grid on
xlabel(['Time (', time_unit, ')'], 'FontSize', font_size)
ylabel('Amplitude (deg)', 'FontSize', font_size)
legend('at-peak', 'filtered', 'FontSize', font_size, ...
    'Orientation','horizontal')
legend('boxoff')

linkaxes(ax_pk, 'x')

if print_fig_bool
    fig.Position = [0 0 1440 1440];
    savefig(sprintf('%sMTAG_Filtered_Data', folder_root))
    print('-dpng', sprintf('%sMTAG_Filtered_Data', folder_root))
end

end