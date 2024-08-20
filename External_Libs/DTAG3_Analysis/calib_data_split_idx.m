function calib_data_split_idx(TagData, itv_hr, tdata_fldname)
%CALIB_DATA_SPLIT_IDX Splits TagData structure into smaller sub-structures
%   TagData can be too large for long datasets, so the temporal fields are split
%   into smaller per-interval subsections (user-defined, units of hours).
%   Non-temporal components are split into a separate structure, and both
%   temporal and non-temporal structures are saved into the given directory's
%   tagdata folder.

% Generate save folder if it does not exist
if exist(tdata_fldname, 'dir') ~= 7
    mkdir(tdata_fldname)
end

% Generate interval size
itv = itv_hr*3600*TagData.sampleFreq;

% Get indices to split by
idxlst = (0:floor(TagData.dataLength/itv))*itv + 1;
if idxlst(end) < TagData.dataLength
    idxlst(end + 1) = TagData.dataLength + 1;   % Add 1 to match indexing later
end

% Get field names, separate out nontemporal fields
f = fieldnames(TagData);
is_tt = cellfun(@(a) size(TagData.(a), 1) == TagData.dataLength, f);
TagData_nonTemporal = ([]);
for i = 1:length(f)
    if ~is_tt(i)
        TagData_nonTemporal.(f{i}) = TagData.(f{i});
        TagData = rmfield(TagData, f{i});
    end
end

% Iterate through indices and sequentially save slices of temporal data
ft = fieldnames(TagData);
for i = 1:(length(idxlst) - 1)
    TagData_temp = ([]);
    idx1 = idxlst(i);
    idx2 = idxlst(i + 1) - 1;
    for j = 1:length(ft)
        TagData_temp.(ft{j}) = TagData.(ft{j})(idx1:idx2,:);
    end
    % Generate filename with leading zeros and save
    fname = ['TagData_', num2str(i, '%03d'), '.mat'];
    save([tdata_fldname, fname], 'TagData_temp')
end

% Save non-temporal data
save([tdata_fldname, 'TagData_nonTemporal.mat'], 'TagData_nonTemporal')

end