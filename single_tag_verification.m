close all; clear; 

addpath(genpath("Tags\"));
addpath(genpath("Lags\"));
addpath(genpath("HelperFuncs\"));
addpath(genpath("MTAG_Lib_Ding\"));

%% CHANGE THIS STUFF

% Same depid and filepath from data_extraction.m
filepath = "E:\Data\slide_test";

% The filename of the data that you want to import
filename = "220528T121826.csv";

% tag_name is used to label plots, so you know which tag is which
tag_name = "MTAG";

%% Import Tags (MORE STUFF TO CHANGE)

fullpath = filepath + "\" + filename;

% Must specify a tag type
% Options: 
%   "D3"
%   "D4"
%   "uTag"
%   "dataLogger"
%   "sliced_tag" (this is to be used if you ran the tag through a the
%   TagSlicer first)
% MTAGs are currently not supported
tag_type = "mTag";
tag1 = tag_importer(fullpath, tag_type, tag_name);

% I only care about data between 0 - 200000 seconds
% Change this range
range = [0 1000000];

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

%% Clean up libaries

rmpath(genpath("Tags\"));
rmpath(genpath("Lags\"));
rmpath(genpath("HelperFuncs\"));
rmpath(genpath("MTAG_Lib_Ding\"));