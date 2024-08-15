% This script is used to verify functionality of the MTAG2 PCB
close all; clear;

%% Manage libraries
addpath(genpath("Tags\"));
addpath(genpath("HelperFuncs\"));

%% Data Settings
filepath = "C:\Users\tysonlin\Documents\Data\mtag2-081524-1103";
filename = "data108.csv";

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
rmpath(genpath("Tags\"));
rmpath(genpath("HelperFuncs\"));