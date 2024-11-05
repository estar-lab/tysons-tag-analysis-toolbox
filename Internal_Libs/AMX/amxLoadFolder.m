% amxFolderLoad
% loads all AMX files in a folder into matrices.
% modified 4/10/2017

%close all
clear all
disp('----------------')
% Surface pressure estimate in mbar for depth calculation
% depth calculation assfumes 1 bar = 10 m
surfacepress=1010;

%ans=input('Append? 0=No  1=Yes ');
ans=0;

% Add current folder to path
addpath(pwd);

%% Select any file in the target folder using dialog box, then automatic reading starts.
disp('Select any AMX file in the target folder, all AMX files ')
disp('in that folder will be read and combined as one.')
[FileName,PathName,FilterIndex] = uigetfile({'*.amx','AMX files (*.amx)'},'Select an AMX file');

if isequal(FileName,0)|isequal(PathName,0)
   return
end
cd(PathName);
% Load all files to structure fileList.
fileList = dir('*.AMX');
logFile = dir('*.CSV');

%% Load .csv file (battery status)
%table_log = readtable([logFile(1).folder,'/', logFile(1).name]);
%battery_log = table_log{:,2};

%% Load all .amx file
% The IMU sensors are sampled at 100 Hz and the other sensors are sampled 
% at 1 Hz. The sample rate is stored in the header structure (SID_SPEC).
sample_freq_a = 100;
sample_freq_b = 1;

%INER=[];
%INER.accel=[];INER.mag=[];INER.gyro=[];
INER.accel.x=[];INER.mag.x=[];INER.gyro.x=[];
INER.accel.y=[];INER.mag.y=[];INER.gyro.y=[];
INER.accel.z=[];INER.mag.z=[];INER.gyro.z=[];
light.red = []; light.blue = []; light.green = [];

PT_Pressure = [];
PT_Temperature = [];
O2_Temperature = [];
O2_Phase = [];

ADC=[];
PTMP=[];
INER_ts=[];
PTMP_ts=[];

% Start time for each file, including the last file that was created but
% not saved.
time_files = 0; % minutes.

for k = 1:length(fileList)
    [DF_HEAD, SID_SPEC, SID_REC]=oAMX(fileList(k).name);

    if(ans==0)
        AUDIO=[];
        PT=[];
        RGB=[];
        IMU=[];
        O2=[];
    end

    for x=1:length(SID_REC)
        cur_sid=(SID_REC(x).nSID) + 1;
        if(SID_SPEC(cur_sid).SID(1)=='A')
            AUDIO=vertcat(AUDIO,SID_REC(x).data);
        end
        if(SID_SPEC(cur_sid).SID(1)=='P')
            PT=vertcat(PT,SID_REC(x).data);
        end
        if(SID_SPEC(cur_sid).SID(1)=='L')
            RGB=vertcat(RGB,SID_REC(x).data);
            RGB_SID = cur_sid;
        end
        if(SID_SPEC(cur_sid).SID(1)=='I' | SID_SPEC(cur_sid).SID(1)=='3')
            IMU=vertcat(IMU,SID_REC(x).data);
            IMU_SID = cur_sid;
        end
            if(SID_SPEC(cur_sid).SID(1)=='O')
            O2=vertcat(O2,SID_REC(x).data);
        end
    end
    
    
    PT_Pressure = [PT_Pressure;
                   PT(1:2:end)];
    PT_Temperature = [PT_Temperature;
                      PT(2:2:end)];
    O2_Temperature = [O2_Temperature;
                      O2(1:2:end)];
    O2_Phase = [O2_Phase;
                O2(2:2:end)];

    INER.accel.x = [INER.accel.x;
                    IMU(1:9:end) * SID_SPEC(IMU_SID).sensor.cal(1)];
    INER.accel.y = [INER.accel.y;
                    IMU(2:9:end) * SID_SPEC(IMU_SID).sensor.cal(2)];
    INER.accel.z = [INER.accel.z;
                    IMU(3:9:end) * SID_SPEC(IMU_SID).sensor.cal(3)];

    INER.gyro.x = [INER.gyro.x;
                   IMU(4:9:end) * SID_SPEC(IMU_SID).sensor.cal(4)];
    INER.gyro.y = [INER.gyro.y; 
                   IMU(5:9:end) * SID_SPEC(IMU_SID).sensor.cal(5)];
    INER.gyro.z = [INER.gyro.z;
                   IMU(6:9:end) * SID_SPEC(IMU_SID).sensor.cal(6)];

    INER.mag.x = [INER.mag.x;
                  IMU(7:9:end) * SID_SPEC(IMU_SID).sensor.cal(7)];
    INER.mag.y = [INER.mag.y;
                  IMU(8:9:end) * SID_SPEC(IMU_SID).sensor.cal(8)];
    INER.mag.z = [INER.mag.z;
                  IMU(9:9:end) * SID_SPEC(IMU_SID).sensor.cal(9)];

    light.red = [light.red;
                 RGB(1:3:end) * SID_SPEC(RGB_SID).sensor.cal(1)];
    light.green = [light.green;
                   RGB(2:3:end) * SID_SPEC(RGB_SID).sensor.cal(2)];
    light.blue =  [light.blue;
                   RGB(3:3:end) * SID_SPEC(RGB_SID).sensor.cal(3)];
                 
    time_files = [time_files;
                  length(INER.accel.x)/sample_freq_a/60;];

end


time_a = [1:length(INER.accel.x)]/sample_freq_a; % sec.
time_b = [1:length(PT_Pressure)]/sample_freq_b; % sec.
%% Plot.
if(length(AUDIO)>0)
    figure()
    plot(AUDIO);
end

figure()
ax2(1) = subplot(4,1,1);
plot(time_a, INER.accel.x, 'b');
hold on;
plot(time_a, INER.accel.y, 'r');
plot(time_a, INER.accel.z, 'g');
xlabel('time (sec)')
ylabel('g');
%plot(sqrt(INER.accel.x.^2+INER.accel.y.^2+INER.accel.z.^2),'k:','lineWidth',1)
title('accelerometer')
grid on

ax2(2) = subplot(4,1,2);
plot(time_a, INER.gyro.x, 'b');
hold on;
plot(time_a, INER.gyro.y, 'r');
plot(time_a, INER.gyro.z, 'g', 'lineWidth',2.0);
grid on
xlabel('time (sec)')
ylabel('deg/s');
title('gyroscope')

ax2(3) = subplot(4,1,3);
plot(time_a, INER.mag.x, 'b');
hold on;
plot(time_a, INER.mag.y, 'r');
plot(time_a, INER.mag.z, 'g');
%plot(sqrt(INER.mag.x.^2+INER.mag.y.^2+INER.mag.z.^2),'k:')
grid on
xlabel('time (sec)')
ylabel('uT');
title('magnetometer')

ax2(4) = subplot(4,1,4);
%plot(time_files, battery_log, 'x-')
%grid on
title('Battery')
xlabel('time (sec)')
ylabel('battery (V)')

linkaxes(ax2,'x')


figure()
subplot(2,1,1)
plot(time_b, PT_Pressure)
ylabel('Pressure');
subplot(2,1,2)
plot(time_b, PT_Temperature);
ylabel('Temperature');
xlabel('time (sec)')
grid on

figure()
plot(time_b, light.red, 'r');
hold on
plot(time_b, light.green, 'g');
plot(time_b, light.blue, 'b');
plot(time_b, sqrt(light.red.^2+light.green.^2+light.blue.^2),'k:')
ylabel('uWpercm^2');
xlabel('time (sec)')
title('Light');
grid on

figure()
subplot(2,1,1)
plot( O2_Temperature);
title('O2');
ylabel('Temp');
subplot(2,1,2)
plot(O2_Phase);
ylabel('Phase');
grid on






