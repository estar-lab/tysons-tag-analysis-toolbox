function TagData = calib_data_merge_fields(fname)
%CALIB_DATA_MERGE Specialized function to re-merge TagData components
%   TagData components that were split into multiple variables in one file are
%   merged here into one complete TagData variable, for use with processing and
%   re-plotting of data

% Load file of saved calibrated data
load(fname)

% Iterate through list of TagData variables and re-merge into main structure
var_list = who('TagData*');
TagData = ([]);
for i = 1:length(var_list)
    temp = eval(var_list{i});
    f = fieldnames(temp);
    for j = 1:length(f)
        TagData.(f{j}) = temp.(f{j});
    end
end

TagData = orderfields(TagData);

end