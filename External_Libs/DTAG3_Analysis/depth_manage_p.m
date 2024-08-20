function depth = depth_manage_p(P, tr, sampleFreq, show_plot)
% The 'depth_manage_p' function takes pressure 'p' and the 
% 'max_dive_depth' of the maximum dive depth and the 'sampleFreq' sampling 
% frequency of corresponding dataset in. Here, 'tr' is the depth threshold above
% which peaks are preserved (-inf, 0]. Taking noise, depth 
% shift and depth scale into account, exporting 'depth' as output.

if nargin < 4
    show_plot = false;  % Show debug plot.
end

fs = round(sampleFreq);

% Filter data and find peaks.
P_filt = moveAvgFilt(P, 0.5*fs);
% P_filt = movmean(P, 0.5*sf);
[pks, locs] = findpeaks(P_filt, 'MinPeakProminence', 0.1);

% Add beginning/ending to peak indices in case recordings start/end in a dive
pks_begin = mean(P_filt(1:fs));
pks_end = mean(P_filt(end-fs+1:end));
pks = [pks_begin; pks; pks_end];
locs = [1; locs; length(P_filt)];

% Find and remove "false" peaks which happened during diving.
ppks = nan(3,1);
while(length(ppks)>2)
%     plot(locs, -pks); drawnow; pause(1);
    [ppks, llocs] = findpeaks(-pks, 'MinPeakProminence', 0.1);
    if ~sum(ppks > -tr); break; end
    pks(llocs(ppks > -tr)) = [];
    locs(llocs(ppks > -tr)) = [];
end

% Define beginning and ending 'pks'.
% pks_begin = mean(P_filt(1:fs));
% pks_end = mean(P_filt(end-fs+1:end));
% pks = [pks_begin; pks; pks_end];
% locs = [1; locs; length(P_filt)];

% Ensure shifts do not affect diving portions - this finds the large time
% segments when the animal is at depth, allowing for interpolation during
% descents and ascents without skewing a dive higher at the end
ldiff = diff(locs);
ldmode = mode(ldiff);
ldhigh_idx1 = find(ldiff >= 10*ldmode);
[ppks2, llocs2] = findpeaks(-P_filt, 'MinPeakProminence', 0.1);
locs_bnd = locs(ldhigh_idx1 + 1);
locs_add = zeros(size(locs_bnd));
for i = 1:length(locs_add)
    locs_add(i) = llocs2(find(llocs2 < locs_bnd(i), 1, 'last'));
end
pks_add = pks(ldhigh_idx1);
lp_sorted = sortrows([[locs; locs_add], [pks; pks_add]], 1);
locs_aug = lp_sorted(:,1);
pks_aug = lp_sorted(:,2);

% Correct potential mid-dive beginning/ending shift magnitudes
if diff(locs_aug(1:2)) > 10*ldmode; pks_aug(1:2) = 0; end
if diff(locs_aug(end-1:end)) > 10*ldmode; pks_aug(end-1:end) = 0; end

% Shift all data down.
% pks_interp = interp1(locs, pks, 1:length(P_filt));
pks_interp = interp1(locs_aug, pks_aug, 1:length(P_filt));
depth = P_filt - pks_interp';
% depth = abs(max_dive_depth)/max(abs(P_shift)) * P_shift;

% Plot if needed.
if show_plot
    t = (1:length(P))/fs;
    figure
    
    ax(1) = subplot(211);
    hold on
    plot(t, P)
    plot(t, P_filt, 'lineWidth', 2)
    plot(locs/fs, pks, 'ms', 'lineWidth',2)
    grid on; hold off; ylabel('depth orig. [m]');
    legend('raw', 'smoothed', 'peaks')
    
    ax(2) = subplot(212);
    hold on
    plot(t, depth, 'LineWidth', 2)
    plot(t, pks_interp, 'LineWidth', 2)
    grid on; hold off; ylabel('depth corr. [m]')
    legend('corrected', 'subtracted')
    
    xlabel('time [sec]')
    linkaxes(ax, 'x')
end

end