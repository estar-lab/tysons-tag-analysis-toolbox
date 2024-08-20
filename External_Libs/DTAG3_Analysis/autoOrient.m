function TagData = autoOrient(TagData, pars)
%AUTOORIENT Automatic tag and animal orientation estimation method
%   This function uses the method developed by Ding Zhang to automatically
%   estimate the orientation of the tag with respect to a fluking animal, and
%   estimate the orientation of the animal along with its gait parameters

addpath(genpath([pwd, '/orientLib']), pwd);

%% Section 1. Unpack parameters.

% Extract tag data
% A_org = TagData.accelTagOrig;
% M_org = TagData.magTagOrig;
A_org = TagData.accelTag;
M_org = TagData.magTag;
sample_freq = TagData.sampleFreq;
Depth = TagData.depth;

wd_static = ceil(pars.wd_st*sample_freq);
wd_naive = ceil(pars.wd_n*sample_freq);
min_amplitude = pars.min_amplitude;
max_period = pars.max_period;
correction_method = pars.correction_method;
section_dur_min = pars.section_dur_min;
density_thrs = pars.density_thrs;
% plot_on = pars.plot_on;
% plot_on2 = pars.plot_on2;
plot_on = false;    % Turn off plotting as this is now handled outside calibration
plot_on2 = false;


%% Section 2. Find tag sliding times.

try
    % Give error for very short datasets.
    [sec_idx_list, in_density_forward, in_density_reverse, idx_breaks] =...
    find_tag_slide_times_func(A_org, Depth, sample_freq, section_dur_min,...
    density_thrs, plot_on);
    % Export data for plotting
    TagData.autoOrientPars = ([]);
    TagData.autoOrientPars.sec_idx_list = sec_idx_list;
    TagData.autoOrientPars.idx_breaks = idx_breaks;
    TagData.autoOrientPars.pars = pars;
    TagData.in_density_forward = in_density_forward;
    TagData.in_density_reverse = in_density_reverse;
catch
    % For a very short dataset, take it as one data segment for tag
    % orientation handling.
    disp("Error running tag shift detection, likely due to short dataset.")
    disp("Now taking the entire dataset as one data segment for fixing tag orientation")
    sec_idx_list = [1; length(A_org)];
end


%% Section 3. Correct rotation for data sections seperated tag sliding times.
% POTENTIALLY MOVE THE INITIAL VARIABLES TO THE PARAMETER STRUCTURE
% Plot control. When visualizing data, data points are plotted every 
% 'plot_interval', so the plot is not too dense.
%   I.e. plot(Acc(1:plot_interval:n,:))
% Set to '[]' (i.e. plot_interval = [], also is default) to use automatic plot
% interval, so a fix number of points are shown. Set to 0 to turn off plot.
plot_interval = 0;

% 1-by-1 scalar, defines the depth threshold for animal surfacing events, and 
% excludes those for orientation anlysis. This is because animals can sometimes
% perform confusing non-swimming behavior at the surface, affecting the method. 
% Set to '[]' (i.e. surf_depth = []) to include all data. 
% The default value is '[]'.
surf_depth = [];

% if strcmp(data_type, 'dolphin')
%     % Dolphin dataset has gyroscope data.
%     G2 = [];
% end

rot_mat_temp = cell(length(sec_idx_list) - 1, 1);
for i_sec = 1:length(sec_idx_list)-1
    i_s = sec_idx_list(i_sec);
    i_e = sec_idx_list(i_sec+1);
    i_use = i_s:i_e;
    rot_mat_temp{i_sec} = find_tag_orientation_func(A_org(i_use,:), Depth(i_use,:),...
        sample_freq, surf_depth, plot_interval, correction_method);
    % Handle case where rot_mat not computed
    if isempty(rot_mat_temp{i_sec})
        if i_sec == 1
            rot_mat_temp{i_sec} = eye(3);
        else
            rot_mat_temp{i_sec} = rot_mat_temp{i_sec - 1};
        end
    end
    A2(i_use,:) = A_org(i_use,:)*rot_mat_temp{i_sec};
    M2(i_use,:) = M_org(i_use,:)*rot_mat_temp{i_sec};

%     if strcmp(data_type, 'dolphin')
%         G2(i_use,:) = G_org(i_use,:)*rot_mat_temp{i_sec};
%     end  
end

%% Section 4. (Only when needed) Show data before orientation corrections:  
% all data or data for a particular section.
if plot_on2
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

%% Section 5. (Only when needed) Manually define dominant vectors for a data 
% segment to correct tag orientation, in case the automatic method's  
% performance is not ideal for a particular section.
% POTENTIALLY ENABLE THIS OPTION IN THE INTIAL PARAMETERS

% if 0
%     i_sec = 1;
%     i_s = sec_idx_list(i_sec);
%     i_e = sec_idx_list(i_sec+1);
%     i_use = i_s:i_e;
%     
%     choice = 'manual'; % 'manual' or 'auto'
%     
%     switch choice
%         case 'manual' 
%         D_flat = [-0.0165, 0.0057, 0.99948]; % Important.
%         D_descend = [-0.2924, 0.0768, 0.9627]; % Important.
%         D_ascend = [0.2803, -0.073, 0.9519]; % Secondary.
%         
%         rot_mat = find_tag_orientation_manual_func(A2(i_use,:), Depth(i_use,:),...
%             sample_freq, D_flat, D_ascend, D_descend, surf_depth, plot_interval);
%         
%         case 'auto'
%             rot_mat = find_tag_orientation_func(A_org(i_use,:), Depth(i_use,:),...
%                 sample_freq, surf_depth, plot_interval, correction_method);
%     end
%     
%     % Apply the rotation if happy with the orientation
%     A2(i_use,:) = A2(i_use,:)*rot_mat;
%     M2(i_use,:) = M2(i_use,:)*rot_mat;
% end

%% Section 6a. Naive method calculating roll, pitch, yaw and then dynamic pose.

[roll_niv, pitch_niv, yaw_niv, Ag_niv, As_niv] =...
    calc_rpy_naive(A2, M2, sample_freq, wd_naive);

[pitch_dp_nv, yaw_dp_nv, vector_dp_nv, ...
    roll_filt_nv, pitch_filt_nv, yaw_filt_nv] =...
    calc_dynamic_pose(roll_niv, pitch_niv, yaw_niv, wd_static);

%% Section 6b. Other method calculating roll, pitch, yaw and then dynamic pose.
% POTENTIALLY ENABLE THIS OPTION IN THE INITIAL PARAMETERS (RESULTS NOT GREAT)

% if 0
%   %% Magnetometer method.
%   [roll_mag, pitch_mag, yaw_mag, Ag_mag, As_mag, rt, bl_singular] =...
%     calc_rpy_magnetometer(A2, M2, sample_freq, wd_static, wd_naive);
% 
%   [pitch_dp_mag, yaw_dp_mag, vector_dp_mag,...
%     roll_filt_mag, pitch_filt_mag, yaw_filt_mag] =...
%     calc_dynamic_pose(roll_mag, pitch_mag, yaw_mag, wd_static);
% end

%% Section 7. Fluke and glide detection and characterization.

signal = pitch_dp_nv;

signal_name = "pitch_{dp}";
signal_unit = "deg";

[frequency_filt, amplitude_filt, period_filt, bool_active,...
    frequency_at_peaks, amplitude_at_peaks, period_at_peaks,...
    positive_peaks, negative_peaks] =...
    parse_gait(signal, sample_freq, min_amplitude, max_period,...
    plot_on, signal_name, signal_unit);

TagData.autoOrientPars.signal_name = signal_name;
TagData.autoOrientPars.signal_unit = signal_unit;


%% Section 8. Export results

% Save intermediate accel data for plotting
TagData.accelInterm = A_org;

% Compute median fluking period for yaw smoothing to reject fluking influence
period = 1/median(frequency_filt(frequency_filt > 0), 'omitnan');

% PRH results
TagData.pitch = pitch_niv;
TagData.roll = roll_niv;
TagData.head = yaw_niv;
yaw_rad = deg2rad(yaw_niv);
% disp('in try/catch')
% try         % Attempt to use smooth function from curvefit toolbox
%     yaw_sm = rad2deg(minimizedAngle(smooth(unwrap(yaw_rad), ...
%         2*period*sample_freq, 'sgolay')));
% catch       % Otherwise use savGol function from Matlab File Exchange
%     disp('secondary sgolay')
whf = round(period*sample_freq); % Compute half-window
yaw_sm = rad2deg(minimizedAngle(savGol(unwrap(yaw_rad), whf, whf, 2)));
% end
TagData.head_filt = yaw_sm;

% Corected accelerometer and magnetometer results
TagData.accelTag = A2;
TagData.magTag = M2;

% Fluking parameters
TagData.relPitch = signal;
TagData.upFluke = positive_peaks;
TagData.dnFluke = negative_peaks;
TagData.inactive = ~bool_active;
TagData.atpeakFreq = frequency_at_peaks;
TagData.filtFreq = frequency_filt;
TagData.atpeakAmp = amplitude_at_peaks;
TagData.filtAmp = amplitude_filt;
TagData.flukePeriodMedian = period;


%% Section 9. Plot results

disp('Plotting results ...')
auto_orient_res_plt(TagData);


end