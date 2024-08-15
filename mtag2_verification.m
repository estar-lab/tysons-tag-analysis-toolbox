% This script is used to verify functionality of the MTAG2 PCB
close all; clear;

%% Manage libraries
addpath(genpath("Tags\"));

%% Data Settings
filepath = "C:\Users\tyson\Documents\ESTAR\Data\MTAG2-081424-1632";
filename = "data105.csv";

% Using for naming plots
tag_name = "MTAG2";

% Specifies which tag to construct. Do not change in this script. 
tag_type = "mTag2";

%% Import Tag
fullpath = filepath + "\" + filename;
tag = tag_importer(fullpath, tag_type, tag_name);
clear filename filepath fullpath tag_name tag_type

%% Make acceleration plot


%% Clean up libraries
rmpath(genpath("Tags\"));