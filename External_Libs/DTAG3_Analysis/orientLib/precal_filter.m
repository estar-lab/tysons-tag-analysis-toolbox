function TagData = precal_filter(TagData, filt_pars, is_testing)
%PRECAL_FILTER Applies filtering on raw tag data according to filter parameters
%   If filt_pars.lpf has nonzero elements:
%   Applies Savitsky-Golay filtering to data. Processes accelerometer,
%   magnetometer, and pressure data individually. Each component of lpf
%   represents the filter window used for each, format of [accel., mag., depth],
%   windows in seconds (recommended <1s).
%   If filt_pars.gapfill is true:
%   Attempts to gapfill sections using the provided maximum gap size and minimum
%   raw voltage threshold, in the format of: filt_pars.gf_vals = [max_gap,
%   d_depth_tr].
%   Set is_testing = 1 if you are only running this alongside the raw voltage
%   checker, set to 0 if using in the full calibration function.

if ~is_testing; fs = max(TagData.RawVolt.fs); end
rvx = TagData.RawVolt.x;

%% Process gapfilling first (Savitsky-Golay has problems with sharp turns)

% NON-FUNCTIONAL: WORK IN PROGRESS, COMMENTED OUT UNTIL COMPLETE

%-------------------    BEGIN CODE TO ADD TO MAIN SCRIPT    -------------------%

% % Set whether to attempt to gapfill data. Currently only depth is supported.
% % Default is gapfill = false, set to true if needed.
% gapfill = true;
% max_gap = 60;       % Set maximum fillable gap size in seconds
% d_depth_tr = 0;     % Set minimum threshold for detecting sharp changes in raw
%                     % voltage signal, may need to be tailored for each instance
% filt_pars.gapfill = gapfill;
% filt_pars.gf_vals = [max_gap, d_depth_tr];

% % Apply precalibration filtering to the raw voltage data to test effects, turn
% % off flag if you want to check raw data without filtering
% apply_prefilt = true;
% if apply_prefilt
%     TagData = precal_filter(TagData, filt_pars, 1);
% end

%--------------------    END CODE TO ADD TO MAIN SCRIPT    --------------------%

% % Extract pressure voltage reading and apply moving average mean to smooth for
% % differentiation
% fsr = TagData.RawVolt.fs(10);
% pvs = movmean(rvx{10}, round(fsr*0.5));
% 
% % Compute Savitsky-Golay smoothing of signal and compare
% whf = round(fsr*10);
% % pvs = savGol(rvx{10}, whf, whf, 2);
% 
% % Compute median filtered signal
% % pvs = medfilt1(rvx{10}, round(fsr*1), 'truncate');
% 
% % Compute de-meaned signal
% pv_dm = pvs - moveAvgFilt(pvs, round(fsr*10));
% 
% % Apply numerical differentiation
% d_pvs = [0; diff(pvs)*fsr];
% 
% % Compute dropoff response in de-meaned signal
% lgauss = lapl_gauss1(filt_pars.sig, fsr);
% pv_drop = conv(pv_dm, lgauss, 'same');
% 
% time_r = (1:length(pvs))'/(fsr);
% 
% figure
% ax(1) = subplot(311);
% hold on
% % plot(time_r, pvs)
% plot(time_r, rvx{10})
% plot(time_r, pvs)
% hold off
% ax(2) = subplot(312);
% % plot(time_r, savGol(d_pvs, whf, whf, 2))
% % plot(time_r, medfilt1(d_pvs, fsr*1, 'truncate'))
% % plot(time_r, medfilt1(abs(rvx{10} - pvs), round(fsr*10), 'truncate'))
% % plot(time_r, medfilt1(abs(pvsg - pvs), round(fsr*10), 'truncate'))
% plot(time_r, pv_dm)
% ax(3) = subplot(313);
% plot(time_r, pv_drop)
% xlabel('Time (min)')
% linkaxes(ax, 'x')


%% Process low-pass filtering last

lpf = filt_pars.lpf/2; % Cut in half to correctly compute half-windows for filt

% Process accelerometer filtering
if lpf(1)
    if ~is_testing
        whf = round(lpf(1)*fs); % Compute half-window
        TagData.accelTagOrig = savGol(TagData.accelTagOrig, whf, whf, 2);
    end
    fsr = TagData.RawVolt.fs(7); whf = round(lpf(1)*fsr);
    for i = 7:9; rvx{i} = savGol(rvx{i}, whf, whf, 2); end
end

% Process magnetometer filtering
if lpf(2)
    if ~is_testing
        whf = round(lpf(2)*fs); % Compute half-window
        TagData.magTagOrig = savGol(TagData.magTagOrig, whf, whf, 2);
    end
    fsr = TagData.RawVolt.fs(1); whf = round(lpf(2)*fsr);
    for i = 1:6; rvx{i} = savGol(rvx{i}, whf, whf, 2); end
end

% Process depth filtering
if lpf(3)
    if ~is_testing
        whf = round(lpf(3)*fs); % Compute half-window
        TagData.depthOrig = savGol(TagData.depthOrig, whf, whf, 2);
    end
    fsr = TagData.RawVolt.fs(10); whf = round(lpf(3)*fsr);
    rvx{10} = savGol(rvx{10}, whf, whf, 2);
end

%% Apply changes

TagData.RawVolt.x = rvx;

end