% tysonlin
% tysonlin@umich.edu

% This script will ask you to draw rectangles around portions of tag data
% that happened at the same time. This 'syncs' all of the tags into the
% same time frame. So if all the tags are doing the same thing, their
% motion will be temporally aligned. 
%
% A window will pop up, and will ask you to draw a rectangle for each 
% subplot. After drawing your rectangles, type 'y' to confirm them. If you 
% are not satisfied with your rectangles, 'n' will let you redraw the 
% rectangles.

close all; clear; 

addpath(genpath("Tags\"));
addpath(genpath("Lags\"));
addpath(genpath("HelperFuncs\"));
addpath(genpath("MTAG_Lib_Ding\"));

%% CHANGE THIS STUFF

% Same depid and filepath from data_extraction.m
filepath = "C:\Users\tysonlin\Documents\Data\drift_test-080724-1606\d401_drift_try2";

% The filename of the data that you want to import
filename = "d401_drift_try2.mat";

% tag_name is used to label plots, so you know which tag is which
tag_name = "D401";

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
tag1 = tag_importer(fullpath, 'D4', tag_name);

%% Repeat for next tag (you can import as many tags as you want
filepath = "C:\Users\tysonlin\Documents\Data\drift_test-080724-1606\mtag2";
filename = "data82.csv";
tag_name = "MTAG2";
fullpath = filepath + "\" + filename;
tag2 = tag_importer(fullpath, 'mTag2', tag_name);

filepath = "C:\Users\tysonlin\Documents\Data\drift_test-080724-1606\utag";
filename = "datalog00178.txt";
tag_name = "uTag-A";
fullpath = filepath + "\" + filename;
tag3 = tag_importer(fullpath, 'uTag', tag_name);

%% Construct the tag cluster

% I only care about data between 50 and 450 seconds
% Change this range
range = [0 100000000];

tags = TagCluster({tag1,tag2,tag3},false, range);
tags = tags.sync_tags();
tags = tags.lag_characterization(1,[10,10,10],200);

%% Do data processing

% Calibrate and verify magnetometers
%tags = tags.calibrate_magnetometers();
%tags = tags.normalize_magnetometers();
%tags = tags.adjust_balls();

% Generate eulers 
%tags = tags.eulers();

%tags = tags.trial_extractions();


%% Make Plots
% for i = 1:length(tags.Tags)
%     tags.Tags{i}.plot_core("Raw Euler Angles");
% end

%tags.plot_magnetometer_balls();
% tags.plot_accels("Acceleration All Tags");
% tags.plot_mags("Magnetometer All Tags");
% tags.plot_headings("Headings");
% tags.plot_eulers("Eulers");

%% Clean up libaries

rmpath(genpath("Tags\"));
rmpath(genpath("Lags\"));
rmpath(genpath("HelperFuncs\"));
rmpath(genpath("MTAG_Lib_Ding\"));