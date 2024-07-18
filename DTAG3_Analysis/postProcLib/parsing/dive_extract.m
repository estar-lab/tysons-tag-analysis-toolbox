function [desc_idx, asc_idx, dive_durs] = dive_extract(depth, depth_min, ...
    depth_maj, dur_min, fs)
%DIVE_EXTRACT Extracts the dive indices and durations for an animal
%   Assumes depth is negative down (decreased elevation => more negative depth).
%   Inputs:
%       depth:      [m] animal depth (negative when underwater)
%       depth_min:  [m] minor depth threshold, to isolate when the animal is at
%                       the surface (usually negative)
%       depth_maj:  [m] major depth threshold, to isolate dives that exceed a
%                   minimum magnitude, keeping dives that exceed the threshold
%                   (usually negative)
%       mindur:     [s] minimum duration of dives, for anomaly rejection
%       fs:         [Hz] sampling frequency of the data
%   Outputs:
%       desc_idx:   indices at which the animal starts its dives (vector)
%       asc_idx:    indices at which the animal ends its dives (vector)
%       dive_durs:  [s] durations of each dive in seconds

% Get length of dataset
m = length(depth);

% Set boolean for when animal is at the surface
surf_bool = depth > depth_min; % Check if animal is at surface (vs. depth_min)
dive_bool = depth < depth_maj; % Check if animal is in deepwater (vs. depth_maj)
surf_diff = diff(surf_bool);

% Get surfacings
p = 0; % Initialize dive count (for indexing)
desc_idx = []; % Initialize index array of dive beginnings
asc_idx = []; % Initialize index array of dive endings
for i = 1:(m - 1)
%     det = Stime(i+1) - Stime(i);
    if surf_diff(i) == -1                    % start of dive
        p = p + 1;
        desc_idx(p) = i;
    elseif ((surf_diff(i) == 1) && (p > 0)) % end of dive
        asc_idx(p) = i;
    end
end
% Force vertical vectors
asc_idx = asc_idx(:);
desc_idx = desc_idx(:);

% Following if statement to handle incomplete last dive
if surf_bool(asc_idx(p)) == 0
    asc_idx(p) = length(depth);
%     disp('Final Dive Incomplete!!')
end

% Filter dives and generate list of dive times
dive_durs = (asc_idx - desc_idx)/fs;
long_dives = dive_durs >= dur_min;
deep_dives = cellfun(@(a,b) any(dive_bool(a:b)), num2cell(desc_idx), ...
    num2cell(asc_idx));
keep = long_dives & deep_dives;
desc_idx(~keep) = [];
asc_idx(~keep) = [];
dive_durs(~keep) = [];
% disp(['Number of dives = ', num2str(length(desc_idx))])

end