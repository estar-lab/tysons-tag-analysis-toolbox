%% Post-processing: example script
% This script guides the user through analyzing the calibrated data, through
% various segmentation and parsing methods. These methods are added to the
% postProcLib library of the toolbox as they are generated.

%% Add folder to the path (perform once before running any section)

addpath('orientLib\')
addpath(genpath('postProcLib'))

%% Diving extraction

% Extract data and set filtering parameters
depth = TagData.depth;      % [m] animal depth (negative when underwater)
depth_min = -0.5;   % [m] minor depth threshold, to isolate when the animal is
                    % at the surface
depth_maj = -8;    % [m] major depth threshold, to isolate dives that exceed a
                    % minimum magnitude, keeping dives that exceed the threshold
                    % -10m is a good initial value for deep-diving whales
dur_min = 3;        % [s] minimum duration of dives, for anomaly rejection
fs = TagData.sampleFreq;    % [Hz] sampling frequency of the data

% Extract dives
[desc_idx, asc_idx, dive_durs] = dive_extract(depth, depth_min, depth_maj, ...
    dur_min, fs);

% Segment dives into ascent, descent, and bottom swimming

% Show extracted dives
time = TagData.timeSec;
figure
hold on
plot(time, depth, 'LineWidth', 1)
for i = 1:length(desc_idx)
    drng = desc_idx(i):asc_idx(i);
    plot(time(drng), depth(drng), 'r', 'LineWidth', 1)
end
hold off
xlabel('Time (s)'); ylabel('Depth (m)'); legend('Surface', 'Dive');

%% Diving segmentation - primary (deep) dives [run previous section]

% Set filtering parameters (explanations are included in the documentation for
% dive_segment)
fluke_per = TagData.flukePeriodMedian;  % Get animal's nominal fluking period

% Deep dive parameters
deep_pars = ([]);
deep_pars.drate_min = 0.25;         % Minor depth rate threshold
deep_pars.drate_maj = 0.5;          % Major depth rate threshold
deep_pars.fdur_min = 10;            % Feature minimum duration

% Shallow dive parameters
shal_pars = ([]);
shal_pars.sh_frac = 0.33;           % Frac. of deepest dive to use for threshold
shal_pars.drate_min = 0.08;         % Minor depth rate threshold
shal_pars.drate_maj = 0.20;         % Major depth rate threshold
shal_pars.fdur_min = 5;             % Feature minimum duration

% Use extracted dive data to segment dives into ascents, descents, and flat
[desc_bnd, asc_bnd, flat_bnd, surf_bnd] = dive_segment(depth, desc_idx, ...
    asc_idx, fluke_per, fs, deep_pars, shal_pars);

% Show segemented dives
figure
hold on
for i = 1:size(surf_bnd, 1)
    srng = surf_bnd(i,1):surf_bnd(i,2);
    p_s = plot(time(srng), depth(srng), 'b', 'LineWidth', 1);
end
for i = 1:size(desc_bnd, 1)
    drng = desc_bnd(i,1):desc_bnd(i,2);
    p_d = plot(time(drng), depth(drng), 'r', 'LineWidth', 1);
end
for i = 1:size(asc_bnd, 1)
    arng = asc_bnd(i,1):asc_bnd(i,2);
    p_a = plot(time(arng), depth(arng), 'g', 'LineWidth', 1);
end
for i = 1:size(flat_bnd, 1)
    frng = flat_bnd(i,1):flat_bnd(i,2);
    p_f = plot(time(frng), depth(frng), 'k', 'LineWidth', 1);
end
hold off
xlabel('Time (s)'); ylabel('Depth (m)');
legend([p_s, p_d, p_a, p_f], 'Surface', 'Descent', 'Ascent', 'Flat');

