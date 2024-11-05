close all; clear;

addpath(genpath("Internal_Libs/AMX/"))

filepath = "C:\w\loggerhead\e3d10a22504b3239302e3120ff0a1a34";
filename = "08205950.AMX";
fullpath = filepath + "\" + filename;

data = amxLoadFolder(fullpath);