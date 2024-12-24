close all; clear;

% 67 cm depth
% 1,2,3,4 m/s
% 1 m/s recovery
% recovery is first
data = readtable("C:\Users\tyson\Downloads\data-12.csv");

pulses = data.Speed_Pulses;

n = length(pulses); % Size of the array
start_value = 0; % Starting value

old_time = data.Time;
new_time = min(old_time):200:max(old_time);
new_time = new_time';
pulses = interp1(old_time, pulses, new_time);
time = new_time / 1000;

xlabel("Time (s)");
ylabel("Pulses (s)");

speed_array = diff(pulses);
speed_time = time(2:end);

% Calculate speed using the given equation
%speed_array = (0.02278 * speed_array + 0.22755).*(speed_array > 0);
speed_array = (0.093608 * speed_array - 0.720918).*(speed_array > 0);


% Optional: Plot the speed over time
figure;
yyaxis left
plot(speed_time, speed_array, '-bo');
ylabel('Speed');
hold on;
yyaxis right
plot(time, pulses, '-r');
ylabel("Pulses")
xlabel('Time (seconds)');

title('Speed Over Time');
grid on;


%% Pressure Calibration

pressure = data.Pressure;
depth = (pressure - 9680) / 850;
depth = depth * -1;

depth = filloutliers(depth, 'linear', 'movmedian', 2000);

n = length(depth); % Size of the array
start_value = 0; % Starting value

time = data.Time / 1000;

figure;
hold on;

yyaxis right
plot(time, pressure)
ylabel("Pressure (unknown units)")
ylim([0 15000])

yyaxis left
plot(time, depth);
ylabel("Depth (cm)");
xlabel("Time (seconds)")
ylim([-2 0.5])
title("Tow Tank Test Depth")
grid on
