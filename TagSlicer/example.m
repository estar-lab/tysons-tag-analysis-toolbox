close all; clear;

addpath("TagSlicer\");

%% CHANGE THIS STUFF

%depid = 'mn24_010a';
depid = 'mn24_010a';

% Give the directory where the raw data is.
filepath = 'C:\Users\tyson\Documents\ESTAR\DTAG Drift\Data\';

% How many partitions do you want, and what are there names?
% The number of names in this array is the number of partitions
partition_names = {"mn24_010a_sliced"};

%% Do the slicing
filename = strcat(depid,".mat");

tag = D4(strcat(filepath,depid,"\",filename),"tag");
tag = tag.adjust();

tag_slicer(strcat(filepath,depid),tag,partition_names);