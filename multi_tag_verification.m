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

addpath("Tags\");
addpath("Lags\");
addpath("HelperFuncs\");
addpath("MTAG_Lib_Ding\");

%% CHANGE THIS STUFF

% Same depid and filepath from data_extraction.m
filepath = "C:\Users\tyson\Documents\ESTAR\Data\verification1\";

% The filename of the data that you want to import
filename = "d409_test1.mat";

% tag_name is used to label plots, so you know which tag is which
tag_name = "D409";

%% Import Tags (MORE STUFF TO CHANGE)

fullpath = filepath + "\" + filename;

% The constructor you must use here changes
% D4 : D4()
% D3 : D3()
% MTAG: mTag();
% any tag that has been sliced : standardTag();
tag1 = D4(fullpath, tag_name);

%% Repeat for next tag (you can import as many tags as you want
filepath = "C:\Users\tyson\Documents\ESTAR\Data\verification1\";
filename = "d410_test1.mat";
tag_name = "D410";
fullpath = filepath + "\" + filename;
tag2 = D4(fullpath, tag_name);

%% Construct the tag cluster

% I only care about data between 50 and 450 seconds
% Change this range
range = [50 450];

tags = TagCluster({tag1,tag2},false, range);
tags = tags.sync_tags();

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
tags.plot_accels("Acceleration All Tags");
tags.plot_mags("Magnetometer All Tags");
tags.plot_headings("Headings");
tags.plot_eulers("Eulers");