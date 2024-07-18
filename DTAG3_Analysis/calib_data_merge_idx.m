function TagData = calib_data_merge_idx(tdata_fldname, fidx, itv_hr)
%CALIB_DATA_MERGE_IDX Merges split TagData files into main TagData structure
%   Merges TagData temporal sub-files into main TagData structure according to
%   provided file indices (fidx). If fidx is empty, merges the entire set of
%   files. Always merges non-temporal file into the structure, for supporting
%   information (sample frequency, auto orientation estimation parameters, etc).
%   itv_hr is used when fidx is not empty, but can be left empty if using
%   default index splitting (defaults to 1 [hr]).
%   Can also pass function with only recdir to process all files.

if nargin < 2; fidx = []; end
if nargin < 3; itv_hr = 1; end

% Get file contents from recording directory
fcont = dir([tdata_fldname, '*.mat']);

% Add non-temporal data to TagData structure
TagData = ([]);
load([fcont(end).folder, '/', fcont(end).name]) % non-temporal will always be last file
fnt = fieldnames(TagData_nonTemporal);
for i = 1:length(fnt)
    TagData.(fnt{i}) = TagData_nonTemporal.(fnt{i});
end

% Perform preprocessing on file index list
if isempty(fidx)
    fidx = 1:(length(fcont) - 1);   % Process all files if fidx is empty
    cust_fidx = false;
else
    % Ensure file indices are sorted (ascending)
    fidx = sort(fidx);
    
    % Ensure that no file index is out of range
    fidx(fidx >= length(fcont)) = [];
    
    cust_fidx = true;   % Set flag for later use
end

% Sequentially concatenate sub-files
for i = fidx
    load([fcont(i).folder, '/', fcont(i).name])
    if i == fidx(1)     % Initialization when temporal fields not created yet
        ft = fieldnames(TagData_temp);
        for j = 1:length(ft)
            TagData.(ft{j}) = TagData_temp.(ft{j});
        end
    else                % Concatenate data onto existing fields
        for j = 1:length(ft)
            TagData.(ft{j}) = [TagData.(ft{j}); TagData_temp.(ft{j})];
        end
    end
end

% When a custom fidx is used, ensure slide section indices are correctly
% modified or removed
if cust_fidx
    idx_breaks = TagData.autoOrientPars.idx_breaks;
    sec_idx_list = TagData.autoOrientPars.sec_idx_list;
    itv = itv_hr*3600*TagData.sampleFreq; % Compute interval length
    
    % Handle case where end is truncated
    if fidx(end) < (length(fcont) - 1)
        fin_idx = fidx(end)*itv; % Generate final index (without shifts)
        idx_breaks(idx_breaks > fin_idx) = [];
        sec_idx_list(sec_idx_list > fin_idx) = [];
    end
    
    % Handle case where beginning is truncated
    if fidx(1) ~= 1
        % Compute index shift and apply
        sft = itv*(fidx(1) - 1);
        idx_breaks = idx_breaks - sft;
        sec_idx_list = sec_idx_list - sft;
        
        % Cull non-positive indices
        idx_breaks(idx_breaks < 1) = [];
        sec_idx_list(sec_idx_list < 1) = [];
    end
    
    % Inject new indices back into TagData
    TagData.autoOrientPars.idx_breaks = idx_breaks;
    TagData.autoOrientPars.sec_idx_list = sec_idx_list;
end

% Order the fields in the TagData structure
TagData = orderfields(TagData);

end