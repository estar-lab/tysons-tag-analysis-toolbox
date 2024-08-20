function [roll, pitch, yaw, head3d] = calc_naive_rpy(A, M, sample_freq)
% Estimate roll, pitch and yaw of the animal assuming accelerometer
% reading is all about gravity. The input sensor data should be aligned
% with the animal's body frame: x-surge points forward, y-sway points left,
% and z-sway points up. If input is not aligned with the animal's body,
% then this function estimates the rpy of the tag itself rather than the 
% animal.
%
% INPUT:
% A             n-by-3 acceleromter reading [unit does not matter]. 
%               Axes are aligned with the animal's body frame as defined 
%               above.
% M             n-by-3 *calibrated* magnetometer reading [unit does not matter]. 
%               Axes are aligned with the animal's body frame as defined 
%               above.
% sample_freq   1-by-1 scalar, the sampling frequency of the sensor.
%
% OUTPUT:
% roll          n-by-1 roll angle of the animal in [degree].
%               Roll is defined as the rotation around body forward axis
%               (x-axis). At zero roll, the y-axis has zero gravity
%               reading. Positive roll is body lean to the right.
% pitch         n-by-1 pitch angle of the animal in [degree].
%               Pitch is defined as the angle between body forward axis 
%               (x-axis) and the horizontal plane of the world. 
%               Positive pitch is head up. Note that positive rotation
%               around y-axis in our axes defination is negative pitch. 
% yaw           n-by-1 yaw angle of the animal in [degree]. The direction
%               of magnetic north is yaw 0. West is 90 deg. South is 180.
%               East is -90 deg.
% head3d        n-by-3 3d heading of the animal, each roll combines the
%               pitch and yaw estimates and gives a 3d vector heading of
%               the animal. E.g. [1, 0, 0] means the animal is facing
%               magnetic north with 0 pitch. [0, 1, 0] means the animal is
%               facing west with 0 pitch. [0, 0, 1] means the animal is
%               having a 90 deg pitch looking at the sky.
%
% ====================
% Ding Zhang
% zhding@umich.edu 
% Updated: 08/03/2020
% ====================

disp('Calculating naive roll, pitch and yaw...')
A = movmean(A, ceil(0.2*sample_freq));
M = movmean(M, ceil(0.2*sample_freq));
A = A./sqrt(sum(A.^2, 2));
roll = atan2d(A(:,2), A(:,3));
% Note again that positive rotation around y-axis in our axes definatio
% n is actually negative pitch. 
pitch = asind(A(:,1));
yaw = zeros(size(roll));

% Origin position (0 roll and pitch) gravity reading.
%A_g = [0, 0, 1];
for i = 1:length(yaw)
  % Change of coordinate to find the equivalent magnetic measurement as 
  % if the tag is flat (i.e. zero roll and pitch).
  %R = vrrotvec2mat(vrrotvec(A_g, A(i,:))); % Not stable.
  R = rot_xd(roll(i)) * rot_yd(-pitch(i)); % Note again pitch is negated.
  m = M(i,:)*R;
  yaw(i) = -atan2d(m(2),m(1));
end

% Initialize head3d.
head3d = zeros(size(A));
head3d(:,1) = 1;
% Apply pitch and yaw.
for i = 1:length(yaw)
  R = rot_yd(-pitch(i))*rot_zd(yaw(i));
  head3d(i,:) = head3d(i,:)*R;
end

disp('Naive roll, pitch and yaw calculation done.')

%%
% % Testing change of coordinates.
% A3 = zeros(size(A));
% A5 = zeros(size(A));
% A_g = [0, 0, 1];
% for i = 1:length(roll)
%   R3 = rot_xd(roll(i)) * rot_yd(-pitch(i)); 
%   A3(i,:) = A(i,:)*R3; % A3 -> A_g
%   R5 = rot_yd(pitch(i)) * rot_xd(-roll(i));
%   A5(i,:) = A_g*R5; % A5 -> A
% end

end


%% Helper rotation functions.
function Rx = rot_xd(alpha)
% Rotation matrix around x axis. Input 'beta' angle in degree.
% Right side multiplication: "v2 = v1*Rx" with 1-by-3 v1 and v2.
Rx = [1, 0,           0;
      0, cosd(alpha), -sind(alpha);
      0, sind(alpha), cosd(alpha)]';
end

function Ry = rot_yd(beta)
% Rotation matrix around y axis. Input 'beta' angle in degree.
% Right side multiplication: "v2 = v1*Ry" with 1-by-3 v1 and v2.
Ry = [cosd(beta),   0, sind(beta);
      0,            1,          0;
      -sind(beta),  0, cosd(beta)]';
end

function Rz = rot_zd(gamma)
% Rotation matrix around z axis. Input 'gamma' angle in degree.
% Right side multiplication: "v2 = v1*Rz" with 1-by-3 v1 and v2.
Rz = [cosd(gamma), -sind(gamma), 0;
      sind(gamma), cosd(gamma),  0;
      0,           0,            1]';
end