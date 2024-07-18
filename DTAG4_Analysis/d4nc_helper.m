clear
addpath(genpath(pwd))

% Pick an appropriate deployment id. Usually you would follow the standard
% DTAG protocol of: 2-letter Latin species initials, 2-digit year, underscore,
% 3-digit Julian day of year, 1-letter animal of the day.
% Use julian_day() if you need to convert a date to a day number.
% depid = 'mn19_170d';
% depid = 'mn17_163a';
% depid = 'mn18_175d';
% depid = 'mn18_172b';
% depid = 'mn21_173a';
depid = 'Tag401_Test';
% Make a name for the nc file that you are going to create. This should start 
% with the deployment id and then indicate what is in the file and the sampling 
% rate. There are no rules for how you indicate what is in the file but some
% ideas are here:
%	trk = position data from GPS
%	sens = all of the sensor data
%  p = depth data only
%  pAM = pressure, acceleration, magnetometer
%  aud = clips of audio
ncname = [depid, 'sens'];

% Give the directory where the raw data is.
%recdir=['dtag4_test_data\', depid];
%recdir=['V:\Whale\', depid];
recdir = ['D:\humpbackWhale\data\', depid];

% recdir=['~/Box Sync/Grad Research/Dolphin Analysis/data/', depid];
% recdir=['~/Downloads/', depid];

% Read in the raw data, for example using one of the following:
% X = d3readswv_commonfs(recdir,depid,5) ;		% decimates to a common 5 Hz sampling rate
% or
% X = d3readswv_commonfs(recdir,depid,25) ;		% decimates to a common 25 Hz sampling rate
% or
% X = d3readswv(recdir,depid,5) ;		% decimates each channel by a factor of 5
% If you need to find out what the original sampling rates are of the different sensors, use:
% X = d3readswv(recdir,depid,'info')
X = d3readswv(recdir,depid) ;

%%
tic
% In all cases, X will contain three fields:
%  X.x is the actual data in a cell array with one sensor channel per cell
%     To access the 8th sensor channel, you do X.x{8}
%     To access the first three sensor channels (assuming they are all the same size,
%     you do [X.x{1:3}]
%     If you used the 'info' option, X.x will be empty.
%  X.fs is a vector with the sampling rate for each sensor channel, in Hz
%  X.cn is a vector of the channel numbers - these are the id numbers that DTAGs use
%     to figure out what kind of data is in each sensor channel. Use d3channames(X) 
%     to find out which channels are present and in what order they are listed in X.x.
%     You can also do d3channames(recdir,depid) to see what sensors are in a dataset
%     before reading it in.

% Make an info structure for the deployment - put your own initials instead
% of 'xx'. Make sure that information about you and your study species is listed
% in the files: researchers.csv and species.csv. These should be in the 'animaltags\user'
% directory in the tag tools and these are files that you maintain yourself. You
% may actually want to rename the user directory to something else so that it
% doesn't get overwritten when you download a new copy of the tag tools. Either
% way, make sure it is on the matlab path.
% The following line makes an info structure for a D4 tag deployed on a 'hs'
% (i.e., a harbour seal) by a person with initials 'xx':
% info = make_info(depid,'D4',depid(1:2),'jg') ;

% Edit the fields in the info structure to give extra information, e.g., 
% info.dephist_deploy_method = 'suction cups' ;     % or 'suction cups' if on a whale
% info.dephist_deploy_locality = 'Oahu, HI' ;
% info.project_name = 'DQO' ;

% It may be easiest to make a script for each field trip that will generate
% an info structure like this:
lat = 41.605817;%172b%21.272027;41.623517; %175d
long = -69.69525;%172b%-157.773092;-69.715733;%175d
info = make_info(depid,'D4',depid(1:2));%%%%%,'dz'
info.project_name = 'WhaleTrack';
% info.project_datetime_start = '2018/06/21 14:46:00';%;'2019/06/24'%%%%%%%%
% info.project_datetime_start = '2019/06/19 10:06:28';%;'2019/06/24'%%%%%%%%
info.project_datetime_start =info.dephist_deploy_datetime_start;
info.project_datetime_end = '2019/06/22 14:37:57';%'2018/06/22';%%%%%%%%%%%%%
info.dephist_deploy_locality = 'Woods Hole, MA';
info.dephist_deploy_method = 'suction cup';
info.dephist_deploy_location_lat = lat;
info.dephist_deploy_location_long = long;

% Sun rise and sun set time since the start of time.
% t_tag_on = [15 39 13]*[1; 1/60; 1/3600]; % In hour. 175d
t_tag_on = [14 46 00]*[1; 1/60; 1/3600]; % In hour. 172b

% t_tag_duration = [23 51 03]*[1; 1/60; 1/3600];
t_sunset_of_the_day = [21 28 0]*[1; 1/60; 1/3600]; % Enter into Nautical twilight, around 9pm.
t_sunrise_of_the_next_day = 24 + [3 47 0]*[1; 1/60; 1/3600]; % End of Nautical twilight, around 4am.
t_sunset_tag = t_sunset_of_the_day - t_tag_on;
t_sunrise_tag = t_sunrise_of_the_next_day - t_tag_on;



% Generate sensor structures for each of the data types.
% Note that the sensor channels may change if your tag was recording a different
% set of sensors (e.g., ECG, light). Use d3channames if in doubt.
T = sens_struct(X.x{7},X.fs(7),depid,'temp') ;	% temperature
P0 = sens_struct(X.x{8},X.fs(8),depid,'press') ;	% pressure
A0 = sens_struct([X.x{1:3}],X.fs(1),depid,'acc') ;	% acceleration
M = sens_struct([X.x{4:6}],X.fs(4),depid,'mag') ;	% magnetometer

ratio = A0.sampling_rate/P0.sampling_rate
A0.data = downsample(A0.data,ratio);
A0.sampling_rate = P0.sampling_rate;
%% make sure M is centered
figure
mag = M.data;
plot3(mag(:,1),mag(:,2),mag(:,3),'.')
hold on
plot3(1,0,0,'rx')
plot3(0,0,1,'rx')
hold off
axis equal
xlabel('x')
ylabel('y')
zlabel('z')
view([0,90])
view([90,0])
Mmag = sqrt(sum(M.data.^2,2));
% histogram(Mmag)
idx_cal = find(~isnan(A0.data(:,1))&P0.data>0.5&Mmag<0.2);
[mag, idx_cal] = mag_calib(M.data, A0.data, -P0.data,idx_cal);
M.data = mag;
%%

% get the calibration constants for this tag
CAL = d4findcal(recdir,depid) ;

T = apply_cal(T,CAL.TEMP) ;			% apply cal to the temperature
% The temperature measurement is internal to the tag and is not very
% accurate. It cannot be used as a water temperature measurement without
% careful calibration. It is however useful for compensating temperature
% effects in the sensors. This is why it has to be calibrated first.

P = apply_cal(P0,CAL.PRESS,T) ;		% apply cal to the pressure


% Plot the pressure and check if it is correct when the animal surfaces.
figure
time_p = (1:length(P.data))/P.sampling_rate/3600; % Unit hour.
plot(time_p, P.data)
xlabel('time [hour]')
ylabel('depth [meter]')
if 0
  %% If depth not good at surfaces, do the following (manually):
  % Comment (Ding Zhang): these operations could make pressure reading looking
  % suspicious, use with with caution. 
  [P01,pc] = fix_pressure(P,T);
  % The calibration corrections are noted in P but you also need to add them
  % to the calibration structure in case you want to do the calibration again
  % for example, at a different sampling rate. 
  CAL.PRESS.poly(2)=pc.poly(2);	% update the CAL for the pressure sensor offset
  CAL.PRESS.tcomp=pc.tcomp;		% and the temperature compensation

  % Plot the pressure again. If it is still not correct when the animal surfaces
  % and the '0' pressure seems to be changing over time, do the following:
  P1 = fix_offset_pressure(P01,60,80);
  %P = P1; % 60, 80 good values, reset P to new fixed values
  % Plot P1 and adjust the last two numbers (300) up or down as required to
  % make the surfacings look reasonable. See the help on fix_offset_pressure for
  % guidance. When P1 looks good, rename it as P.
end

% Apply and check the calibration on the accelerometer as follows. This will
% try to improve the calibration based on the data. Note that auto_cal_acc does
% not implement any axis conversions, i.e., it ignores the accelerometer MAP. This
% is because the calibration polynomial in CAL.ACC works on the sensor axes not the
% tag axes. The MAP is applied in a later step.
[AA,ac] = auto_cal_acc(A0,CAL.ACC) ;
% Plot AA or norm2(AA) to make sure it looks good. If it does, save the
% improved calibration:
CAL.ACC = ac ;

% Apply the calibration and map to get the final tag-frame accelerometer data:
A = apply_cal(A0,CAL.ACC) ;

%%
% Once you have made changes to the CAL structure, save them to a cal file for this
% deployment:
%save([depid 'cal.mat'],'CAL')
% You can retrieve this file later using CAL=d4findcal(depid);

% It is also a good idea to save the data you have got so far just in case something
% goes wrong. You can add more data later.
%save_nc(ncname,info,P,T,A,M) ;

% Generate an RMS jerk vector with a sampling rate of e.g., 5 Hz. This takes some
% time to run because it reads the entire high-rate accelerometer data.
J = d3rmsjerk(recdir,depid,CAL.ACC.poly,5);
add_nc(ncname,J) ;

% GPS grab processing
% 1. Pre-process the grabs to get the pseudo-ranges. This can take a day or more
%    depending on the number of grabs and the speed of your computer.
d3preprocgps(recdir,depid) ;
%%
% 2. Gather the results from the pre-processing into an OBS structure.
OBS = d3combineobs(recdir,depid) ;
%%

% 3. Get estimates of the start position of the tag and its clock offset with respect
%    to GPS time. If you have good estimates for these already, proceed to step 4. 
%	  Most likely you know the rough start position (e.g., within 0.5 degree) but are
%	  not sure about the clock offset. In which case, do this:
THR = 200;%200
% % lat = 41.65; %41.605817;%21.272027;
% % long = -69.66; %-69.69525;%-157.773092;
%[tc,rerr] = gps_timesearch(OBS,[lat,long],[-30 30],THR);
[tc,rerr] = gps_timesearch(OBS,[lat,long],[-50 50],THR);
% [tc,rerr] = gps_timesearch(OBS,[lat,long],-6*3600+[-30 30],200);
% [tc,rerr] = gps_timesearch(OBS,[lat,long],-6*3600+[-30 30]);
% In this line, [-30 30] defines the clock offset time range to search, i.e., -30 to 30 
% seconds with respect to true time. This is plenty for normal clock offsets that come
% about from 
% tc is an estimate of the time offset between the tag clock and GPS time, in seconds.
% rerr is an estimate of the location error (in metres) that will result in the first
% GPS location if you use this clock offset. If rerr is less than a few hundred
% metres, give tc a try in step 4 below. If rerr is high, then either your starting
% position estimate is not good or you need to allow a larger/different time offset
% search. Either way, one of the following steps might be needed.

% Manual fix for mn19_170d.
%tc = 22.0788;
%%
if 0
%%
% If you don't know within +/- 2 degrees what the start position is, do the following:
check_sv_elevation(OBS,lat,long,tc,THR) ;
% If you know the starting point within +/- 2 degrees (e.g., as a result of
% running check_sv_elevations, run the following:
find_start_point(OBS,lat,long,tc,THR) ;
find_start_point(OBS,lat,long,tc) ;
% This will tell you a likely starting point for the GPS track.
% Now you can try to get the time offset using gps_timesearch as above.
end
%%
% 4. Run the GPS processor to compute the track. This can take several hours
%    if there were a lot of grabs.
[POS0,N,gps] = gps_posns(OBS,[lat,long],tc,THR);

% 5. Save the result. First save all of the outputs in a .mat file.
%save([depid 'trk.mat'],'POS','N','gps')
% Then generate a nc file for the GPS tracking data

gpst0 = etime(datevec(POS0.T),repmat(get_start_time(info),size(POS0.T,1),1)) ;
POS=sens_struct([POS0.lat POS0.lon],POS0.T,depid,'pos');
%save_nc([depid 'trk'],info,POS)	% info was defined at line 21 above

toc
%%
% Plot in map. Available in Matlab 2019
figure
geoplot(POS.data(:,2), POS.data(:,3), '-o')
geobasemap('streets')


%% 
% Time syncs.
% Time of gps updates in tag time frame [seconds].
gpst = gps2tag_time(gps.T, info);
t_gps_hour_0 = (gpst-tc)/3600;
% Time vectors for tag sensors that have low sampling rates.
t_tag_hour = (1:length(P.data))/P.sampling_rate/3600; % Unit hour.
% Time vectors for tag accelerometer that has high sampling rate.
t_acc_hour = (1:length(A.data))/A.sampling_rate/3600; % Unit hour.

% Norm of A and M.
A_norm = sqrt(sum(A.data.^2,2));
M_norm = sqrt(sum(M.data.^2,2));


%% Find surface times and correct depth.
if 0
  %%
  idx_gps_not_nan = ~isnan(gpst);
  tc = mean(gpst(idx_gps_not_nan) - t_gps_hour*3600);
  
end
%idx_gps_not_nan = ~isnan(t_gps_hour_0);
%t_gps_hour = t_gps_hour_0(idx_gps_not_nan);
t_gps_hour = t_gps_hour_0(gps.k);
% Indices for surfaces in tag time.
idx_surface = knnsearch(t_tag_hour', t_gps_hour);
% Mean surface depth.
p_gps_surf = P.data(idx_surface);
p_surf = mean(p_gps_surf);%(~isnan(p_gps_surf))
% Define p_offset.
p_offset = -p_surf - 0.2;


%% Calculate km position from degree positions.
pos_lat_deg_relative = POS.data(:,2) - POS.data(1,2);
pos_lon_deg_relative = POS.data(:,3) - POS.data(1,3);
pos_lat_km_relative = 110.574 * pos_lat_deg_relative;
pos_lon_km_relative = 111.32 * cos(deg2rad(POS.data(:,2))).*pos_lon_deg_relative;


%% Save resulting datas.
%save([recdir,'\Data_',depid], 'A', 'M', 'P', 'T', 'POS', 'N', 'gps', 't_gps_hour',...
%      't_tag_hour', 't_acc_hour', 'ncname', 'info', 'p_offset', 'X', 'J') 
% save([recdir,'\extracted_data\Data_',depid]) 
save([recdir,'\Data_',depid]) 

    
%%
idx_night_gps = t_gps_hour >= t_sunset_tag & t_gps_hour <= t_sunrise_tag;

% Plot data out.
figure
% Plot accelerometer data.
ax(1) = subplot(2,2,1);
hold on
plot(t_acc_hour, A.data(:,1))
plot(t_acc_hour, A.data(:,2))
plot(t_acc_hour, A.data(:,3))
plot(t_sunset_tag*ones(2,1), [-35;35], 'k', 'lineWidth', 2)
plot(t_sunrise_tag*ones(2,1), [-35;35], 'r', 'lineWidth', 2)

%plot(t_acc_hour, A_norm)
grid on
xlabel('Tag Time [h]')
ylabel('Accelerometer [m/s2]')
legend('Ax', 'Ay', 'Az',...
  'Sunset (Enter Nautical twilight)', 'Sunrise (End Nautical twilight)')
%legend('Ax', 'Ay', 'Az', 'Anorm')
title([depid(1:4),'-',depid(6:9)] )

% Plot pressure and GPS updates.
ax(2) = subplot(2,2,2);
plot(t_tag_hour, P0.data+p_offset)
hold on
plot(t_gps_hour, P0.data(round(t_gps_hour*3600*50))+p_offset, 'ko')
% plot(t_gps_hour, -0.3*ones(size(t_gps_hour)), 'ko')
plot(t_sunset_tag*ones(2,1), [-10;150], 'k', 'lineWidth', 2)
plot(t_sunrise_tag*ones(2,1), [-10;150], 'r', 'lineWidth', 2)

grid on
xlabel('Tag Time [h]')
ylabel('Depth [m]')
legend('Depth', 'GPS updates',...
  'Sunset (Enter Nautical twilight)', 'Sunrise (End Nautical twilight)')

% Plot magnetometer reading.
ax(3) = subplot(2,2,3);
hold on
plot(t_tag_hour, M.data(:,1))
plot(t_tag_hour, M.data(:,2))
plot(t_tag_hour, M.data(:,3))
%plot(t_tag_hour, M_norm)
plot(t_sunset_tag*ones(2,1), [-0.35;0.35], 'k', 'lineWidth', 2)
plot(t_sunrise_tag*ones(2,1), [-0.35;0.35], 'r', 'lineWidth', 2)

grid on
xlabel('Tag Time [h]')
ylabel('Magnetometer [G]')
legend('Mx', 'My', 'Mz',...
  'Sunset (Enter Nautical twilight)', 'Sunrise (End Nautical twilight)')
%legend('Mx', 'My', 'Mz', 'Mnorm')

% Plot gps locations.
subplot(2,2,4)
%hold on
%geoplot(POS.data(1:100,2), POS.data(1:100,3), 'mo')
%geoplot(POS.data(:,2), POS.data(:,3), 'k-o')
%geobasemap('landcover')
%legend('Start','All updates')
% hold on
% plot(POS.data(3:end,3), POS.data(3:end,2), 'k-o')
% plot(POS.data(idx_night_gps,3), POS.data(idx_night_gps,2), 'b-o')
% 
% plot(POS.data(1:3,3), POS.data(1:3,2), 'g-o')
% plot(POS.data(end-3:end,3), POS.data(end-3:end,2), 'r-o')

hold on
plot(pos_lon_km_relative(3:end-3), pos_lat_km_relative(3:end-3), 'k-o')
plot(pos_lon_km_relative(1:3), pos_lat_km_relative(1:3), 'g-o')
plot(pos_lon_km_relative(end-3:end), pos_lat_km_relative(end-3:end), 'r-o')
plot(pos_lon_km_relative(idx_night_gps), pos_lat_km_relative(idx_night_gps), 'b-o')



legend('Track', 'Start of track', 'End of track', 'Track (Night)')

grid on
axis equal
xlabel('Longitude (km)')
ylabel('Latitude (km)')
title(['GPS locations w.r.t. start: [', num2str(POS.data(1,3)),...
  '  ', num2str(POS.data(1,2)), '] (degree)'])
linkaxes(ax,'x')


%%
TagData.tempr = sens_struct(X.x{7},X.fs(7),depid,'temp') ;	% temperature
TagData.pres = P0 ;	% pressure
TagData.acc = A0 ;	% acceleration
TagData.mag = M ;

TagData.CAL_orig = d4findcal(recdir,depid);
TagData.CAL = TagData.CAL_orig;
TagData.tempr_cal = do_cal(TagData.tempr,TagData.CAL.TEMP);
TagData.pres_cal = apply_cal(TagData.pres,TagData.CAL.PRESS,TagData.tempr_cal);
[TagData.pres_cal,pc] = fix_pressure(TagData.pres_cal,TagData.tempr_cal);

TagData.CAL.PRESS.poly(2)=pc.poly(2);
TagData.CAL.PRESS.tcomp=pc.tcomp;
TagData.info = info;
TagData.acc_cal = A;
TagData.jerk = TagData.acc_cal;
TagData.jerk.data = sqrt(sum(diff(TagData.jerk.data).^2,2))*TagData.jerk.sampling_rate;

TagData.mag_cal = do_cal(TagData.mag, TagData.CAL.MAG);

[mag, idx_cal] = mag_calib(TagData.mag_cal.data, TagData.acc_cal.data, -TagData.pres_cal.data);
TagData.mag_cal.data=mag;
%% make sure M is centered
figure
mag = TagData.mag_cal.data;
plot3(mag(:,1),mag(:,2),mag(:,3),'.')
hold on
plot3(200,0,0,'rx')
plot3(0,0,200,'rx')
hold off
axis equal
xlabel('x')
ylabel('y')
zlabel('z')
view([0,90])
view([90,0])
Mmag = sqrt(sum(mag.^2,2));
histogram(Mmag)
idx_cal = find(~isnan(A0.data(:,1))&P0.data>0.5&Mmag<130);
[mag, idx_cal] = mag_calib(TagData.mag_cal.data, TagData.acc_cal.data, -TagData.pres_cal.data,idx_cal);

TagData.mag_cal.data = mag;
%%
TagData.acc_cal.data(isnan(TagData.acc_cal.data))=1;
TagData.pres_cal.data(isnan(TagData.pres_cal.data))=0;

%% trim data
figure
plott(TagData.pres_cal)
flag = input('Does the data need to be trimmed? y/n: ','s');
if flag~='y' && flag~='n'
    flag = sscanf('please enter y or n.');
end
if flag == 'y'
%     TagData = trim_time(TagData);
[tend,~] = ginput(1);
TagData.pres_cal.data(TagData.pres_cal.sampling_rate*tend*3600 : end) = [];
TagData.tempr_cal.data(TagData.tempr_cal.sampling_rate*tend*3600 : end) = [];
TagData.acc_cal.data(TagData.acc_cal.sampling_rate*tend*3600 : end,:) = [];
TagData.jerk.data(TagData.jerk.sampling_rate*tend*3600 : end,:) = [];
TagData.mag_cal.data(TagData.mag_cal.sampling_rate*tend*3600 : end,:) = [];
end
%%
TagData.gps = gps;
TagData.gps.lat = gps.lat(gps.k);
TagData.gps.lon = gps.lon(gps.k);
TagData.gps.timeGPS = t_gps_hour*3600;
%% check surface depth
depth = depth_manageHumpback(TagData, 1);
TagData.pres_cal.data = -depth;
