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

filepath = "D:\Maui2025\Sensor-Testing\D406\Pressure_Test";
filename = "Pressure_Test.mat";
tag_name = "D406";
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
d406 = tag_importer(fullpath, 'D4', tag_name);

%% Repeat for next tag (you can import as many tags as you want
filepath = "D:\Maui2025\Sensor-Testing\D410\Pressure_Test";
filename = "Pressure_Test.mat";
tag_name = "D410";
fullpath = filepath + "\" + filename;
d410 = tag_importer(fullpath, 'D4', tag_name);

filepath = "D:\Maui2025\Sensor-Testing\D405\Pressure_Test";
filename = "Pressure_Test.mat";
tag_name = "D405";
fullpath = filepath + "\" + filename;
d405 = tag_importer(fullpath, 'D4', tag_name);

filepath = "D:\Maui2025\Sensor-Testing\D345\Pressure_Test";
filename = "Pressure_Test.mat";
tag_name = "D345";
fullpath = filepath + "\" + filename;
d345 = tag_importer(fullpath, 'D3', tag_name);

filepath = "D:\Maui2025\Sensor-Testing\D347\Pressure_Test";
filename = "Pressure_Test.mat";
tag_name = "D347";
fullpath = filepath + "\" + filename;
d347 = tag_importer(fullpath, 'D3', tag_name);


%% Construct the tag cluster

% I only care about data between 50 and 450 seconds
% Change this range
range = [0 10000000];

tags = TagCluster({d345,d347,d405,d406,d410},false, range);

%% Make Plots
% for i = 1:length(tags.Tags)
%     tags.Tags{i}.plot_core("Pressure Test");
% end

tags.plot_depths_compare("Pressure Test");
tags.plot_depths("Depths");

%% Clean up libaries

rmpath(genpath("Tags\"));
rmpath(genpath("Lags\"));
rmpath(genpath("HelperFuncs\"));
rmpath(genpath("MTAG_Lib_Ding\"));