close all; clear; 

addpath("Tags\");
addpath("Lags\");
addpath("HelperFuncs\");
addpath("MTAG_Lib_Ding\");

%% CHANGE THIS STUFF

% Same depid and filepath from data_extraction.m
filepath = "C:\Users\tyson\Documents\ESTAR\DTAG Drift\Data\mn24_010a\";

% The filename of the data that you want to import
filename = "mn24_010a_sliced.mat";

% tag_name is used to label plots, so you know which tag is which
tag_name = "D407";

%% Import Tags (MORE STUFF TO CHANGE)

fullpath = filepath + "\" + filename;

% The constructor you must use here changes
% D4 : D4()
% D3 : D3()
% MTAG: mTag();
% any tag that has been sliced : standardTag();
tag1 = standardTag(fullpath, tag_name);

% I only care about data between 0 - 200000 seconds
% Change this range
range = [0 14000];

tags = TagCluster({tag1},false, range);

%% Do data processing

% Calibrate and verify magnetometers
tags = tags.calibrate_magnetometers();
tags = tags.normalize_magnetometers();
tags = tags.adjust_balls();

% Generate eulers 

tags = tags.eulers();

%% Make Plots
for i = 1:length(tags.Tags)
    tags.Tags{i}.plot_core("Raw Euler Angles");
end

tags = tags.correct_eulers();

for i = 1:length(tags.Tags)
    tags.Tags{i}.plot_core("sin(Euler Angles)");
end

% tags.plot_magnetometer_balls();
% tags.plot_accels("Acceleration All Tags");
% tags.plot_mags("Magnetometer All Tags");
% tags.plot_headings("Headings");
% tags.plot_eulers("Eulers");