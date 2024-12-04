close all; clear;
addpath(genpath("Tags\"));
addpath(genpath("Lags\"));
addpath(genpath("HelperFuncs\"));
addpath(genpath("MTAG_Lib_Ding\"));

%% CHANGE THIS STUFF
filepath = "C:\Users\tyson\Downloads\fakedolphin";

% tag_name is used to label plots, so you know which tag is which
tag_name = "Example Dolphin";

tag_type = "mTag2.1";

tag = tag_importer(filepath, tag_type, tag_name);
tag = tag.trial_extraction();
tag.plot_core("Master Plot");
tag.plot_IR();

%% Clean up libaries

rmpath(genpath("Tags\"));
rmpath(genpath("Lags\"));
rmpath(genpath("HelperFuncs\"));
rmpath(genpath("MTAG_Lib_Ding\"));