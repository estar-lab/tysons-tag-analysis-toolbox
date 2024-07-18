function [roll, pitch, yaw, A_g, A_spec, rt, bool_singular] =...
  calc_rpy_magnetometer(A, M, sample_freq, wd_static, wd_naive)
% Estimate roll, pitch and yaw of the animal, with an implementation of the
% "magnetometer method" proposed in [1]. The "magnetometer method" uses 
% magnetometer reading to help identifying dynamic orientation changes  
% associated with the fluking (*pitch*) motion of *cetacean*, hence decouples
% accelerometer reading into: (1) static acc ("A_filt"), (2) dynamic acc 
% induced by linear acceleration of the animal ("A_spec"), (3) dynamic acc
% induced by orientation changes of the animal.
%
% The "magnetometer method" suffers from "singular events" when the y-axis
% (sway) of the animal is colinear with the magnetic field. This
% implementation patches these events (marked by "idx_singular") by
% replacing results of those sections with results from a naive method.
%
% The naive method applies a mild low-pass filter to acceleration
% measurement "A" and assumes the filtered signal "A_g_naive" is associated
% with gravity (contains both static and dynamic orientation of the 
% animal), while all dynamic linear accelration of the animal has been
% filtered out (which is not accurate, but that's why it's called naive).
%
% The input sensor data should be aligned
% with the animal's body frame: x-surge points forward, y-sway points left,
% and z-sway points up. If input is not aligned with the animal's body,
% then this function estimates the rpy of the tag itself rather than the 
% animal.
%
% **NOTE** The "magnetometer method* is making an underlying assumption that
% high frequency motions are results of fluking. Thus the method does not
% handle the situations well when the animal does a quick back-and-forth
% roll or turn.
%
% INPUT:
% A             n-by-3 accelerometer reading [unit does not matter]. 
%               Axes are aligned with the animal's body frame as defined 
%               above.
% M             n-by-3 *calibrated* magnetometer reading [unit does not matter]. 
%               Axes are aligned with the animal's body frame as defined 
%               above.
% sample_freq   1-by-1 scalar, the sampling frequency of the sensor. [Hz]
% wd_static     1-by-1 scalar, window size of the (low-pass) moving
%               average filter, for identifying static portion of the 
%               signal (i.e. fitering out dynamic portion). [counts]
% wd_naive      1-by-1 scalar, window size of the (low-pass) moving
%               average filter, used in the naive method for identifying 
%               portion of the signal associated static and dynamic
%               orientation, fitering out linear accelrations. [counts]
%
% OUTPUT:
% roll          n-by-1 roll angle of the animal in [degree].
%               Roll is defined as the rotation around body forward axis
%               (x-axis). At zero roll, the y-axis has zero gravity
%               reading. Positive roll is body lean to the right.
% pitch         n-by-1 pitch angle of the animal in [degree].
%               Pitch is defined as the angle between body forward axis 
%               (x-axis) and the horizontal plane of the world. 
%               Positive pitch is head up. *NOTE* that positive rotation
%               around y-axis in our axes defination is negative pitch. 
% yaw           n-by-1 yaw angle of the animal in [degree]. The direction
%               of magnetic north is yaw 0. West is 90 deg. South is 180.
%               East is -90 deg.
% A_g           n-by-3 accleration measure (static + dynamic) associated 
%               with gravity. [g]
% A_spec        n-by-3 accleration measure associated with (dynamic) linear
%               accleration of the animal. [g]
% rt            n-by-1 dynamic "pitch" angle of the animal. [degree]
% bool_singular n-by-1 boolean values (0 or 1) indicating whether a point is
%               associated with a singular event (i.e. y-axis colinear with
%               magnetic field). If so, the results for that point come 
%               from the naive method.
%
% Reference:
% [1] L�pez, L.M.M., Miller, P.J., de Soto, N.A. and Johnson, M., 2015. 
% Gait switches in deep-diving beaked whales: biomechanical strategies 
% for long-duration dives. Journal of Experimental Biology,
% 218(9), pp.1325-1338.
%
% ====================
% Ding Zhang
% zhding@umich.edu 
% Updated: 04/06/2021
% ====================

disp('Calculating roll, pitch and yaw using magnetometer method...')

% Window size of the low-pass filter, tune these as needed.
% wd_static = ceil(3*gait_period*sample_freq); % For magnetometer method.
% wd_mild = ceil(0.5*gait_period*sample_freq); % For naive method.


% Initial smooth.
A = movmean(A, ceil(0.1*sample_freq));
M = movmean(M, ceil(0.1*sample_freq));

% Normalize to 1 g.
% A = A./sqrt(sum(A.^2, 2));
A = A/mean(sqrt(sum(A.^2, 2)));

% Static portion of the signal.
A_filt = movmean(A, wd_static);
M_filt = movmean(M, wd_static);

% Dynamic portion of the signal.
A_tl = A - A_filt;
M_tl = M - M_filt;

% Acceleration measure associated with gravity, determined by static and 
% dynamic orientation of the animal.
% A_g = A - A_spec;
A_g_naive = movmean(A, wd_naive);

% Decouple dynamic into linear changes and orientation changes. 
% See Ref.[1] for why.
A_spec = zeros(size(A)); % Dynamic linear acceleration.
rt = zeros(length(A),1); % Dynamic "pitch" angle.
bool_singular = false(length(A), 1);
singular_const = 1/cosd(25)^2 - 1;

% for t = 1:length(A)
parfor t = 1:length(A)
  if mod(t, round(length(A)/100)) == 0
    disp([num2str(t/length(A) * 100), '% complete'])
  end
      
  mx = M_filt(t, 1);
  my = M_filt(t, 2);
  mz = M_filt(t, 3);

  if mz^2 + mx^2 >= my^2*singular_const
    % Not singular.
    W = [mz, 0, -mx]/(mz^2 + mx^2);
    rt(t) = asind(M_tl(t, :)*W');
    A_spec(t, :) = A_tl(t, :) - sind(rt(t))*[A_filt(t, 3), 0, -A_filt(t, 1)];
  else
    % Singular.
    bool_singular(t) = true;
    rt(t) = nan;
    A_spec(t, :) = A(t, :) - A_g_naive(t, :);
  end
end


A_g = A - A_spec;

% Roll pitch yaw calculation.
roll = atan2d(A_g(:,2), A_g(:,3));
% Note again that positive rotation around y-axis in our axes definatio
% n is actually negative pitch. 
pitch = real(asind(A_g(:,1)));
yaw = zeros(size(roll));

% Origin position (0 roll and pitch) gravity reading.
%A_g = [0, 0, 1];
%for t = 1:length(yaw)
parfor t = 1:length(yaw)
  % Change of coordinate to find the equivalent magnetic measurement as 
  % if the tag is flat (i.e. zero roll and pitch).
  %R = vrrotvec2mat(vrrotvec(A_g, A(i,:))); % Not stable.
  R = rot_xd(roll(t)) * rot_yd(-pitch(t)); % Note again pitch is negated.
  m = M(t,:)*R;
  yaw(t) = -atan2d(m(2),m(1));
end

disp('Roll, pitch and yaw calculation done.')

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