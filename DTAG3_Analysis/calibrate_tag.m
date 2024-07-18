function TagData = calibrate_tag(recdir, thisDeploy, DF, pars, filt_pars, ...
    est_mthd)
%CALIBRATE_TAG Calibrates tag and attempts to perform simple orientation est.

addpath(genpath(recdir));

if exist([recdir, '/', 'audit'], 'dir') ~= 7
    mkdir([recdir, '/', 'audit'])
end
if exist([recdir, '/', 'cal'], 'dir') ~= 7
    mkdir([recdir, '/', 'cal'])
end
if exist([recdir, '/', 'prh'], 'dir') ~= 7
    mkdir([recdir, '/', 'prh'])
end
if exist([recdir, '/', 'raw'], 'dir') ~= 7
    mkdir([recdir, '/', 'raw'])
end

initPath(recdir)

% Set deploy name and decimation factor
TagData.deployName = thisDeploy;
TagData.desampFreq = DF;

% Read raw data
TagData = readSwv(TagData,recdir);
TagData.dataLength = numel(TagData.depthOrig); %get the number of data points

% Apply raw voltage filtering if called (in progress)
% TagData = precal_filter(TagData, filt_pars, 0);

TagData = optCalib(TagData); %calibration optimization

% Filter out initial noise if necessary before orientation filter applied
if any(filt_pars.lpf); TagData = preorient_filter(TagData, filt_pars.lpf); end

% Secondary depth correction
try
    dtr = -0.5; % Depth threshold to preserve surfacings in correction method [m]
    TagData.depth = depth_manage_p(-TagData.depth, dtr, TagData.sampleFreq, 0);
catch
    TagData.depth = -TagData.depth;
end

% Run tag orientation
if strcmp(est_mthd, 'auto')
    TagData = autoOrient(TagData, pars);
else
    % Manual orientation estimation method
    TagData = estOrient(recdir, TagData, pars);
end

% Add additional calibration parameters to TagData for saving
TagData.surface_threshold = dtr;
TagData.orient_est_mthd = est_mthd;
TagData.recording_dir = recdir;
TagData.filt_pars = filt_pars;

% Remove original voltage recording for space savings (keeps sampling
% frequencies and channel names for posterity)
TagData.RawVolt.x = [];

TagData = orderfields(TagData);

% Save the Data
% save([recdir, '/', thisDeploy, '_cal_', num2str(TagData.sampleFreq), 'hz'])
tdata_fldname = [recdir, '/tagdata_', num2str(TagData.sampleFreq), 'hz/'];
disp(['Saving data to ', tdata_fldname, ' ...'])
calib_data_split_idx(TagData, 1, tdata_fldname);

disp('Done with calibration.')

end

%------------------------------------------------------------------------------%

function initPath(recdir)

if ispc
    settagpath('cal',[recdir, '\cal']);
    %settagpath('raw','c:/tag/data/raw');
    settagpath('prh',[recdir, '\prh']);
    settagpath('audit',[recdir, '\audit']) ;
else
    settagpath('cal',[recdir, '/cal']);
    %settagpath('raw','c:/tag/data/raw');
    settagpath('prh',[recdir, '/prh']);
    settagpath('audit',[recdir, '/audit']) ;
end

end

%------------------------------------------------------------------------------%

function TagData = readSwv(TagData, recdir)

prefix = TagData.deployName;
RawVolt = d3readswv(recdir,prefix,TagData.desampFreq);
% [ch_names,descr,ch_nums,type] = d3channames(X.cn);
% Register the deployment:
[Calib,Deploy] = d3deployment(recdir, prefix, prefix) ;

depthOrig = d3calpressure(RawVolt, Calib);

accelTagOrig = d3calacc(RawVolt,Calib);

magTagOrig = d3calmag(RawVolt,Calib);

depthOrig(isnan(accelTagOrig)) = nan;

TagData.RawVolt = RawVolt;
TagData.CalibOrig = Calib;
TagData.accelTagOrig = accelTagOrig;
TagData.depthOrig = depthOrig;
TagData.magTagOrig = magTagOrig;

end

%------------------------------------------------------------------------------%

function TagData = optCalib(TagData)

satisCalib = 0;
while ~satisCalib
    TagData = reoptCalib(TagData);
    correctKey = 0;
    while ~correctKey
    keyPress = input('Satis for the calib? y, n  ', 's');
    switch keyPress(1)
        case 'y'
            satisCalib = 1;
            correctKey = 1;
        case 'n'
            correctKey = 1;
        otherwise
            fprintf('Please type y, n')
    end
    end
end

end

%------------------------------------------------------------------------------%

function TagData = reoptCalib(TagData)
RawVolt = TagData.RawVolt;
Calib = TagData.CalibOrig;
prefix = TagData.deployName;
%% Optimize the Calibration
% Optimize the pressure calibration:
% X = trPress(X);
[depth,Calib,sampleFreq,temp] = d3calpressure(RawVolt,Calib,'full');

% Optimize the acceleration calibration:
% min_depth = 10;
[accelTag,Calib,sampleFreq] = d3calacc(RawVolt,Calib,'full');
% Optimize the magnetometer calibration:
[magTag,Calib,sampleFreq,dmvar01] = d3calmag(RawVolt,Calib,'full');
% Save the calibration information so far to the deployment CAL file:
d3savecal(prefix,'CAL',Calib) % bug needs to be fixed
timeHour = (1:length(accelTag))'/max(sampleFreq)/3600;
timeSec = timeHour*3600;
depth(isnan(accelTag)) = nan;

TagData.accelTag = accelTag;
TagData.depth = depth;
TagData.magTag = magTag;
TagData.tempTag = temp;
TagData.timeHour = timeHour;
TagData.timeSec = timeSec;
TagData.sampleFreq = sampleFreq;
TagData.Calib = Calib;
end