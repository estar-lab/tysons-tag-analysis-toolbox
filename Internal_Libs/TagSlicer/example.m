close all; clear;

addpath(genpath("Internal_Libs\TagSlicer\"));

%% CHANGE THIS STUFF

% The variables 'depid' and 'filepath' mean the same thing, and you
% to use the same values across all scripts. Make sure you set these variables before running 
% any script that has them. 
% 
% A note on what to set them to - if your file hierarchy looks like this:
% .
% ├── mn24_010a
% │   ├── mn24_010a002.dtg
% │   └── mn24_010a002.bin
% │   └── mn24_010a002.xml
% │   └── (more files)
% ├── more data directories
% 
% 'depid' would be would be 'mn24_010a'. The naming convention here follows
% 'depid'XXX.filetype. So it is important that the foldername matches the name of your files. 
% 
% 'filepath' would be the path into the folder that contains the folder mn24_010a\. For me that happens to be
% "C:\Users\tyson\Documents\ESTAR\DTAG Drift\Data\"

%depid = 'mn24_010a';
depid = '220528T121826';

% Give the directory where the raw data is.
filepath = 'E:\Data\slide_test';

% How many partitions do you want, and what are their names?
% The number of names in this array is the number of partitions
% 
% So therefore, if you only want a portion of your dataset, 
% this array would only contain one name
% 
% Examples:
%   partition_names = {"mn24_010a_sliced"};
%   partition_names = {"mn24_010a_part1", "mn24_010a_part2"};
partition_names = {"220528T121826_sliced"};

%% Do the slicing
filename = strcat(depid,".mat");

tag = D4(strcat(filepath,depid,"\",filename),"tag");
tag = tag.adjust();

tag_slicer(strcat(filepath,depid),tag,partition_names);

%% Clean up libaries
rmpath(genpath("TagSlicer\"));