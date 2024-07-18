close all; clear; 

addpath("Tags\");
addpath("Lags\");
addpath("HelperFuncs\");
addpath("MTAG_Lib_Ding\");

%% CHANGE THIS STUFF

% Same depid and filepath from data_extraction.m
depid = "mn24_010a";
filepath = "C:\Users\tyson\Documents\ESTAR\DTAG Drift\Data\";
filename = "mn24_010a_sliced";

% tag_name is used to label plots, so you know which tag is which
tag_name = "D407";

%% Import Tags

fullpath = filepath + depid + "\" + filename + ".mat";
d407 = standardTag(fullpath, tag_name);

tags = TagCluster({d407},false);

%% Do data processing

% Calibrate and verify magnetometers
tags = tags.calibrate_magnetometers();
tags = tags.normalize_magnetometers();
tags = tags.adjust_balls();


% Generate eulers 
tags = tags.eulers();

%% Make Plots
for i = 1:length(tags.Tags)
    tags.Tags{i}.plot_core();
end

%tags.plot_magnetometer_balls();
%tags.plot_accels("Acceleration All Tags");
%tags.plot_mags("Magnetometer All Tags");
%tags.plot_headings("Headings");
%tags.plot_eulers("Eulers");