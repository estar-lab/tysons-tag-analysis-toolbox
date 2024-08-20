function [TagData_precal, TagData_orig, TagData_corr, TagData_orient, ...
    TagData_fluking, TagData_time] = calib_data_split_fields(TagData)
%CALIB_DATA_SPLIT Splits calibrated tag data into smaller portions for saving
%   This (hopefully) corrects the too-large file error when saving by breaking
%   the original file into mutually-exclusive parts

TagData_precal = ([]);
TagData_precal.Calib = TagData.Calib;
TagData_precal.CalibOrig = TagData.CalibOrig;
TagData_precal.RawVolt = TagData.RawVolt;
TagData_precal.dataLength = TagData.dataLength;
TagData_precal.deployName = TagData.deployName;
TagData_precal.desampFreq = TagData.desampFreq;
TagData_precal.sampleFreq = TagData.sampleFreq;
TagData_precal.surface_threshold = TagData.surface_threshold;
TagData_precal.orient_est_mthd = TagData.orient_est_mthd;
% TagData_precal.tagSlidePars = TagData.tagSlidePars;
TagData_precal.recording_dir = TagData.recording_dir;

TagData_orig = ([]);
TagData_orig.accelTagOrig = TagData.accelTagOrig;
TagData_orig.magTagOrig = TagData.magTagOrig;
TagData_orig.depthOrig = TagData.depthOrig;

TagData_corr = ([]);
TagData_corr.accelTag = TagData.accelTag;
TagData_corr.magTag = TagData.magTag;
TagData_corr.depth = TagData.depth;
TagData_corr.tempTag = TagData.tempTag;

TagData_orient = ([]);
TagData_orient.head = TagData.head;
TagData_orient.head_filt = TagData.head_filt;
TagData_orient.pitch = TagData.pitch;
TagData_orient.relPitch = TagData.relPitch;
TagData_orient.roll = TagData.roll;

TagData_fluking = ([]);
TagData_fluking.atpeakAmp = TagData.atpeakAmp;
TagData_fluking.atpeakFreq = TagData.atpeakFreq;
TagData_fluking.filtAmp = TagData.filtAmp;
TagData_fluking.filtFreq = TagData.filtFreq;
TagData_fluking.dnFluke = TagData.dnFluke;
TagData_fluking.upFluke = TagData.upFluke;
TagData_fluking.inactive = TagData.inactive;
TagData_fluking.flukePeriodMedian = TagData.flukePeriodMedian;
TagData_fluking.autoOrientPars = TagData.autoOrientPars;
TagData_fluking.accelInterm = TagData.accelInterm;
TagData_fluking.in_density_forward = TagData.in_density_forward;
TagData_fluking.in_density_reverse = TagData.in_density_reverse;

TagData_time = ([]);
TagData_time.timeHour = TagData.timeHour;
TagData_time.timeSec = TagData.timeSec;

end