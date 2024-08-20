% This script is used to verify functionality of the MTAG2 PCB
close all; clear;

%% Manage libraries
addpath(genpath("Internal_Libs\Tags\"));
addpath(genpath("Internal_Libs\HelperFuncs\"));

%% Data Settings
filepath = "H:\";
filename = "data7.csv";

% Used for naming plots
tag_name = "Unverified MTAG2";

% Specifies which tag to construct. Do not change in this script. 
tag_type = "mTag2";

%% Import Tag
fullpath = filepath + "\" + filename;
tag = tag_importer(fullpath, tag_type, tag_name);
clear filename filepath fullpath tag_name tag_type

%% Import Tag for Comparison
ref = tag_importer("ReferenceData\mtag2_accel.csv", "mTag2", "Correct MTAG2");

%% Make acceleration plot
tags = TagCluster({ref,tag}, false);
tags.plot_accels();

%% Temperature plot
tag.plot_temperatures();

%% Clean up libraries
rmpath(genpath("Internal_Libs\Tags\"));
rmpath(genpath("Internal_Libs\HelperFuncs\"));