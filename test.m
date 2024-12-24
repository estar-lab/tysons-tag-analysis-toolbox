close all; clear;

addpath("HelperFuncs\")

% depth doesn't matter
% 1m/s recovery first (same as Test 1)
% 1.5, 2.5, 3.5, 4.5, 5.5 6, 0.5 m/s 
% apparently recovery doesn't exist
data = readtable("C:\Users\tyson\Downloads\data-15.csv");

pulses = data.Speed_Pulses;
pulses = pulses(4500:end);

n = length(pulses); % Size of the array
start_value = 0; % Starting value

time = start_value + (0:n-1) * 0.2;

end_value = find_index(time, 700);

time = time(1:end_value);
pulses = pulses(1:end_value);


speed_array = diff(pulses);
speed_time = time(2:end);

% Calculate speed using the given equation

% old speed equation
% speed_array = (0.02278 * speed_array + 0.22755).*(speed_array > 0);

% new speed equation
speed_array = (0.093608 * speed_array - 0.720918).*(speed_array > 0);

% Optional: Plot the speed over time
figure;
yyaxis left
plot(speed_time, speed_array, '-b');
ylabel('Speed (m/s)');

hold on;
yyaxis right
plot(time, pulses, '-r');
ylabel("Total Hall Effect Pulses")
xlabel('Time (s)');

title('Speed Calibration');
grid on;

rmpath("HelperFuncs\")