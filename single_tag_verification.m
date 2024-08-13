close all; clear; 
%% 
addpath(genpath("Tags\"));
addpath(genpath("Lags\"));
addpath(genpath("HelperFuncs\"));
addpath(genpath("MTAG_Lib_Ding\"));

%% CHANGE THIS STUFF

% Same depid and filepath from data_extraction.m
filepath = "C:\Users\tysonlin\Documents\Data\mn23_206a";

% The filename of the data that you want to import
filename = "mn23_206a";

% tag_name is used to label plots, so you know which tag is which
tag_name = "D4";

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
%   "mTag"
%   "mTag2"
tag_type = "D4";
tag1 = tag_importer(fullpath, tag_type, tag_name);

% I only care about data between 0 - 200000 seconds
% Change this range
range = [0 1000000];

tags = TagCluster({tag1},false, range);

%% Do data processing

% Extract trial portion
% This generates the plot where you have to draw the rectangle
tags = tags.trial_extractions();

% Calibrate and verify magnetometers
tags = tags.calibrate_magnetometers();
tags = tags.adjust_balls();
tags = tags.normalize_magnetometers();

% Detect slide times
tags = tags.slide_times();


%% MORE STUFF TO CHANGE
%  Stuff related to euler angles

% Generate eulers 
% Note: This function is the one that generates the many many plots, and these plots
% can be very laggy. To toggle the plots, go to
% MTAG_Lib_Ding->find_tag_orientation_func.m, and edit line 100
tags = tags.eulers();

% Runs a moving mean on the yaw for all the tags
% Input to this function is the length of the window, in the number of
% samples
% This pipeline processes D4 data at 50 Hz
% So a 1500 sample window equates to a 30 second moving mean
% Change this as desired
% This also generates a plot to see how the window filters the yaw
tags = tags.moving_mean_yaw(1500);

%% Make Plots
%tags = tags.correct_eulers();
for i = 1:length(tags.Tags)
    tags.Tags{i}.plot_core("Euler Angles");
end

% This should be as close to a ball as possible
tags.plot_magnetometer_balls("Final Magnetometer Balls");

% tags.plot_accels("Acceleration All Tags");
% tags.plot_mags("Magnetometer All Tags");
% tags.plot_headings("Headings");
% tags.plot_eulers("Eulers");

%% Clean up libaries

rmpath(genpath("Tags\"));
rmpath(genpath("Lags\"));
rmpath(genpath("HelperFuncs\"));
rmpath(genpath("MTAG_Lib_Ding\"));