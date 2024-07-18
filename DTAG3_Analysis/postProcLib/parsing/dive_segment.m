function [desc_bnd, asc_bnd, flat_bnd, surf_bnd] = dive_segment(depth, ...
    desc_idx, asc_idx, fluke_per, fs, deep_pars, shal_pars)
%DIVE_SEGMENT Segment dives into ascent, descent and flat swimming
%   Takes inputs from dive_extract to further segment animal dives.
%   Inputs:
%       depth:      [m] animal depth (negative when underwater)
%       desc_idx:   indices at which the animal starts its dives (vector)
%       asc_idx:    indices at which the animal ends its dives (vector)
%       fluke_per:  [s] nominal fluke period. If used with data from the TagData
%                   structure, this would be TagData.flukePeriodMedian
%       fs:         [Hz] sampling frequency of the data
%       * Deep dive parameters (deep_pars."parameter"):
%       drate_min:  [m/s] minor depth rate threshold, to identify periods of
%                   dives that exceed this minimum depth rate magnitude that
%                   could be periods of ascent or descent
%       drate_maj:  [m/s] major depth rate threshold, to filter out ascents and
%                   descents that do not exceed this theshold, keeping only the
%                   features with (generally) large depth change rates
%       fdur_min:   [s] minimum feature duration, to keep only the features that
%                   exceed this threshold, filtering out transient ascents and
%                   descents
%       * Shallow dive parameters (shal_pars."parameter"):
%       sh_frac:    fraction of deepest dive to use as a threshold to segment
%                   dives into deep and shallow (e.g. 0.33): above (smaller
%                   than) fraction is classified as shallow, below (larger than)
%                   fraction is classified as deep
%       drate_min:  [m/s] minor depth rate threshold, to identify periods of
%                   dives that exceed this minimum depth rate magnitude that
%                   could be periods of ascent or descent
%       drate_maj:  [m/s] major depth rate threshold, to filter out ascents and
%                   descents that do not exceed this theshold, keeping only the
%                   features with (generally) large depth change rates
%       fdur_min:   [s] minimum feature duration, to keep only the features that
%                   exceed this threshold, filtering out transient ascents and
%                   descents
%   Outputs:
%       desc_bnd:   p x 2 array of indices indicating descent bounds. The
%                   first column corresponds to the start of each interval, and
%                   the second corresponds to the end, where p is the number of
%                   intervals found.
%       asc_bnd:    q x 2 array of indices indicating ascent bounds. The
%                   first column corresponds to the start of each interval, and
%                   the second corresponds to the end, where q is the number of
%                   intervals found.
%       flat_bnd:   r x 2 array of indices indicating flat (underwater) period
%                   bounds. The first column corresponds to the start of each 
%                   interval, and the second corresponds to the end, where r is
%                   the number of intervals found. Flats are assumed to be dive
%                   portions that do not correspond to ascents or descents.
%       surf_bnd:   s x 2 array of indices indicating surfacing period bounds.
%                   The first column corresponds to the start of each interval,
%                   and the second corresponds to the end, where s is the number
%                   of intervals found. Surfacings are assumed to be any portion
%                   of the data that are not descents, ascents, or underwater
%                   flat swimming periods.

%% Prepare data, split dives into deep and shallow

% Get length of dataset and number of dives
m = length(depth);
n = length(desc_idx);

% Smooth depth to reduce npise and remove fluking effects
whf = round(fluke_per*fs); % Half-window for filter
depth_sm = savGol(depth, whf, whf, 2);

% Get furthest depths of each dive, split into deep and shallow dives
dives_df = zeros(n, 1);
for i = 1:n
    dives_df(i) = min(depth(desc_idx(i):asc_idx(i)));
end
is_shallow = dives_df > shal_pars.sh_frac*min(dives_df);

% Generate boolean vectors indicating the deep and shallow dives
dive_bool_d = zeros(m, 1, 'logical');
dive_bool_s = zeros(m, 1, 'logical');
for i = 1:n
    if is_shallow(i)
        dive_bool_s(desc_idx(i):asc_idx(i)) = 1;
    else
        dive_bool_d(desc_idx(i):asc_idx(i)) = 1;
    end
end

% Compute numerical derivative of depth
depth_rate = diff(depth_sm)*fs; depth_rate = [depth_rate; depth_rate(end)];


%% Segment deep dives

% Extract parameters
drate_min = deep_pars.drate_min;
drate_maj = deep_pars.drate_maj;
fdur_min = deep_pars.fdur_min;

% Use numerical derivative to flag potential features, combine with dive boolean
% to extract possible features during deep dives
% Descents
desc_bool_d = (depth_rate <= -drate_min) & dive_bool_d;
[desc_id1, desc_id2] = feature_filt(depth_rate, desc_bool_d, drate_maj, ...
    fdur_min, fs, 1);
% Ascents
asc_bool_d = (depth_rate >= drate_min) & dive_bool_d;
[asc_id1, asc_id2] = feature_filt(depth_rate, asc_bool_d, drate_maj, ...
    fdur_min, fs, 1);
% Flat
% Make flats anything in dives that is not ascents or descents
flat_bool_d = dive_bool_d;
for i = 1:length(desc_id1)
    flat_bool_d(desc_id1(i):desc_id2(i)) = 0;
end
for i = 1:length(asc_id1)
    flat_bool_d(asc_id1(i):asc_id2(i)) = 0;
end
[flat_id1, flat_id2] = feature_filt(depth_rate, flat_bool_d, drate_maj, ...
    fdur_min, fs, 0);


%% Segment shallow dives

% Extract parameters
drate_min = shal_pars.drate_min;
drate_maj = shal_pars.drate_maj;
fdur_min = shal_pars.fdur_min;

% Use numerical derivative to flag potential features, combine with dive boolean
% to extract possible features during deep dives
% Descents
desc_bool_s = (depth_rate <= -drate_min) & dive_bool_s;
[desc_is1, desc_is2] = feature_filt(depth_rate, desc_bool_s, drate_maj, ...
    fdur_min, fs, 1);
% Ascents
asc_bool_s = (depth_rate >= drate_min) & dive_bool_s;
[asc_is1, asc_is2] = feature_filt(depth_rate, asc_bool_s, drate_maj, ...
    fdur_min, fs, 1);
% Flat
% Make flats anything in dives that is not ascents or descents
flat_bool_s = dive_bool_s;
for i = 1:length(desc_is1)
    flat_bool_s(desc_is1(i):desc_is2(i)) = 0;
end
for i = 1:length(asc_is1)
    flat_bool_s(asc_is1(i):asc_is2(i)) = 0;
end
[flat_is1, flat_is2] = feature_filt(depth_rate, flat_bool_s, drate_maj, ...
    fdur_min, fs, 0);


%% Define surface indices
% Surface indices are anything not in a dive
surf_bool = ones(m, 1, 'logical');
% Modify boolean to ensure beginning and end are included in indices for surface
surf_bool(1) = 0; surf_bool(end+1) = 0;
for i = 1:n
    surf_bool(desc_idx(i):asc_idx(i)) = 0;
end
[surf_ix1, surf_ix2] = feature_filt(depth_rate, surf_bool, drate_maj, ...
    fdur_min, fs, 0);


%% Export results

% desc_bnd = [desc_ix1, desc_ix2];
% asc_bnd = [asc_ix1, asc_ix2];
% flat_bnd = [flat_ix1, flat_ix2];
% surf_bnd = [surf_ix1, surf_ix2];

desc_bnd = [[desc_id1, desc_id2]; [desc_is1, desc_is2]];
asc_bnd = [[asc_id1, asc_id2]; [asc_is1, asc_is2]];
flat_bnd = [[flat_id1, flat_id2]; [flat_is1, flat_is2]];
surf_bnd = [surf_ix1, surf_ix2];

% Plot for debugging, uncomment only if necessary
% figure
% ax(1) = subplot(211);
% hold on
% for i = 1:size(surf_bnd, 1)
%     srng = surf_bnd(i,1):surf_bnd(i,2);
%     p_s = plot(srng/fs, depth(srng), 'b', 'LineWidth', 1);
% end
% for i = 1:size(desc_bnd, 1)
%     drng = desc_bnd(i,1):desc_bnd(i,2);
%     p_d = plot(drng/fs, depth(drng), 'r', 'LineWidth', 1);
% end
% for i = 1:size(asc_bnd, 1)
%     arng = asc_bnd(i,1):asc_bnd(i,2);
%     p_a = plot(arng/fs, depth(arng), 'g', 'LineWidth', 1);
% end
% for i = 1:size(flat_bnd, 1)
%     frng = flat_bnd(i,1):flat_bnd(i,2);
%     p_f = plot(frng/fs, depth(frng), 'k', 'LineWidth', 1);
% end
% hold off
% xlabel('Rel. Time (s)'); ylabel('Depth (m)');
% legend([p_s, p_d, p_a, p_f], 'Surface', 'Descent', 'Ascent', 'Flat');
% ax(2) = subplot(212);
% plot((1:length(depth_rate))/fs, depth_rate)
% xlabel('Rel. Time (s)'); ylabel('Depth Rate (m/s)');
% linkaxes(ax, 'x')

end

%% -------------------------------------------------------------------------- %%
function [ix1, ix2] = feature_filt(drate, feat_bool, drate_maj, fdur_min, fs, notflat)
%FEATURE_FILT Helper function to filter out small magnitude or short features
%   notflat = 1 for ascents and descents, 0 otherwise
%   Returns lists of beginning (ix1) and ending (ix2) indices.

% Find toggles in feature boolean
feat_diff = diff(feat_bool);

% Find boolean value changes and interval durations
ix1 = find(feat_diff == 1);
ix2 = find(feat_diff == -1);
durs = (ix2 - ix1)/fs;

% % Find long segments
% long_feats = durs >= fdur_min;

% Find features with major prominences (for ascents/descents, does nothing for
% flats or surfacings)
if notflat
    % Find features with strong ascents or descents
    hrate_bool = abs(drate) >= drate_maj;
    maj_feats = cellfun(@(a,b) any(hrate_bool(a:b)), num2cell(ix1), ...
            num2cell(ix2));
    % Find long segments
    long_feats = durs >= fdur_min;
    keep = long_feats & maj_feats;
    % Remove features that do not pass the thresholds
    ix1(~keep) = [];
    ix2(~keep) = [];
% else
%     keep = long_feats;
end

end