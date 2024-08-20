classdef IMU < TimeData
    % IMU Defines the IMU data into a common format for analysis, allowing
    % for a standardization of the interface
    %   This class sets up the ability to import raw IMU data, and then
    %   perform some needed analysis, such as quaternions, euler angles,
    %   pitching, or fluking frequency. This class inherits from TimeData
    %   for the interpolation or the extraction methods on the data.
    properties (Access = public)
        % data inherited from TimeData can contain the following fields
        %accel     % Acceleration data [m/s^2], 3 x T
        %gyro      % Gyro data [deg/sec], 3 x T
        %magnet    % Magnetometer data [uT], 3 x T
        %quat      % Normalized quaternion data [-], 4 x T
        %accel_mag % Acceleration magnitude [m/s^2], 1 x T
    end

    properties (Access = protected)
        has_accel  = false; % boolean if data contains acceleration
        has_gyro   = false; % boolean if data contains gyro
        has_magnet = false; % boolean if data contains magnetometer
        has_quat   = false; % boolean if data contains quaternion data

        mag_was_calib  = false;  % boolean if the magnetometer was calibrated
        gyro_was_calib = false;  % boolean if the gyroscope was calibrated
    end

    methods
        function obj = IMU(time, Fs, accel, gyro, magnet, quat)
            obj@TimeData(time, Fs); % call superclass constructor to set up the time for this data set

            % Import the requsite data into the IMU, remember that && is a
            % short-circuit "AND", and thus the second half will only run
            % if the variable does exist
            if (exist('accel',  'var')  && ~isempty(accel)) ; obj.append_field('accel',  accel);  obj.has_accel  = true; end
            if (exist('gyro',   'var')  && ~isempty(gyro))  ; obj.append_field('gyro',   gyro);   obj.has_gyro   = true; end
            if (exist('magnet', 'var')  && ~isempty(magnet)); obj.append_field('magnet', magnet); obj.has_magnet = true; end
            if (exist('quat',   'var')  && ~isempty(quat))  ; obj.append_field('quat',   quat);   obj.has_quat   = true; end
        end

        function [] = calibrate_offset_magnetometer(obj, times, fit_type, plot_bool)
            if nargin < 3
                plot_bool = false;
            end

            if obj.has_magnet
                if obj.mag_was_calib
                    obj.magnet = undo_ellipsoid_correction(obj.magnet, obj.metadata.mag_calib);
                end

                if isempty(times)
                    mag_data = obj.magnet;
                else
                    mag_data = obj.magnet(:, obj.apply_func(@(x) time_range_find(x.time, times)));
                end

                if strcmpi(fit_type, 'sphere')
                    sol = fit_ball(mag_data);
                elseif strcmpi(fit_type, 'ellipse')
                    sol = fit_ellipsoid(mag_data);
                else
                   error('Invalid parameter for magnetometer fitting (can either be `ellipse` or `sphere`).');
                end
                
                if plot_bool
                    plot_pre_post_mag(mag_data, sol);
                end

                obj.append_metadata('mag_calib', sol);  % this is merely a structure of non-temporal data, metadata is a good enough place for it

                obj.magnet = ellipsoid_correction(obj.magnet, sol);  %can handle both ellipsoids and spheres

                obj.mag_was_calib = true;
            else  %tag does not contain magnetometer data
                warning('IMU structure does not contain magnetometer data.');
            end
        end

        function [] = calibrate_offset_gyroscope(obj, times, plot_bool)
            if (nargin < 3)
                plot_bool = false;
            end

            if obj.has_gyro
                if obj.gyro_was_calib
                    obj.gyro = obj.gyro + obj.gyro_offset;
                end

                if isempty(times)
                    times = [obj.time(1) obj.time(end)];
                end

                % Find the mean gyro value within the time bounds
                offset = NaN*zeros(size(obj.gyro));
                for i = 1:size(times, 1)
                    inds = obj.time >= times(i, 1) & obj.time <= times(i, 2);
                    offset(:, inds) = mean(obj.gyro(:, inds), 2).*ones(size(offset, 1), sum(inds));  %create a vector of 3x((t2-t1)*Fs)
                end
                % Now linearly interpolate between the bounds, replacing
                % the edges with a copy of the value at the endpoints
                offset = interp1(obj.time(~isnan(offset(1, :))), offset(:, ~isnan(offset(1, :)))', obj.time, 'linear')';
                offset(:, obj.time < times(1, 1))   = offset(:, find(obj.time >= times(1, 1), 1, 'first')) .* ones(size(offset, 1), sum(obj.time < times(1, 1)));
                offset(:, obj.time > times(end, 2)) = offset(:, find(obj.time <= times(end, 2), 1, 'last')) .* ones(size(offset, 1), sum(obj.time > times(end, 2)));

                if plot_bool
                    plot_pre_post_gyro(obj.time, obj.gyro, obj.gyro-offset, offset, times);
                end
                
                obj.append_field('gyro_offset', offset);  %this is temporal data the same size as the data, we need to be able to interpolate it in case we reinterpolate

                obj.gyro = obj.gyro - offset;
                obj.gyro_was_calib = true;
            else
                warning('IMU structure does not contain gyroscope data.');
            end
        end

        function [] = rotate_frame(obj, rot_mat)
            % Rotate the current frame of the IMU by rot_mat
            %   This is used to rotate the right-hand frame the IMU is
            %   currently to a new orientation. Note that the IMU data is
            %   in the size of 3xT for the accel, gyro, mag, and 4xT for
            %   the quaternion representation. The rot_mat as given is in
            %   the form of v_B [3xT] = R_BA [3x3] * v_A [3xT].
            if (obj.has_accel)
                obj.accel = rotate_matrix(rot_mat, obj.accel);
            end

            if (obj.has_gyro)
                obj.gyro = rotate_matrix(rot_mat, obj.gyro);
            end

            if (obj.has_magnet)
                obj.magnet = rotate_matrix(rot_mat, obj.magnet);
            end

            if (obj.data.has_quat)
                warning('rotate_frame not implemented for quaternions yet\n');
            end
        end

        function [] = get_accel_magnitude(obj)
            % Calculate the L2 norm row-wise (for each time point)
            obj.append_field('accel_mag', vecnorm(obj.accel, 2));
        end
        
        function [] = find_tag_slide_times(obj, category_struct, sec_dur_min, density_thrs, plot_on) 
            % This function wraps the tag_slide times function with the
            % appropriate inputs. We will prepare the function by directly
            % passing in the category times (flat/ascend/descend swimming
            % types) calculated seperately (from Pressure class). This
            % allows for a bit more extensibility in finding outliers,
            % which can be useful in contexts outside of just finding tag
            % slide times as well.
            
            
        end
    end
end

%% Helper functions
% Helper function for IMU.rotate_frame(obj, rot_mat)
%   This function will rotate a 3xT matrix, where the rows correspond to
%   the data channels (accel, gyro, or mag), and the columns to time.
%   Additionally, only selected indexed points can be rotated.
function frame_b = rotate_matrix(rot_mat, frame_a, inds)
if nargin < 3
    frame_b = rot_mat * frame_a;
else
    % Create a copy of frame_a, especially if we are doing a subindexed
    % rotations
    frame_b = frame_a;
    frame_b(:, inds) = rot_mat*frame_b(:, inds);
end
end

%% Ancillary plotting functions for debugging/visualization
% Plotting functions for pre/post for gyro and mag
function [] = plot_pre_post_gyro(time, pre_gyro, post_gyro, offset, time_bounds)
y_lims = [min(pre_gyro, [], 'all') max(pre_gyro, [], 'all')];

figure;
axs(1) = subplot(1, 2, 1); hold on; grid on; box off; title('Pre');
plot(time, pre_gyro);
plot(time, offset, 'k:', 'LineWidth', 1.2);
for i = 1:size(time_bounds, 1)
    Ts = time_bounds(i, :);
    patch([Ts fliplr(Ts)], ...
        1.2*[y_lims(1) y_lims(1) y_lims(2) y_lims(2)], ...
        'k', 'EdgeColor', 'none', 'FaceAlpha', 0.2);
end
xlabel('Time [sec]')
ylabel('Gyro [rad/sec]');

axs(2) = subplot(1, 2, 2); hold on; grid on; box off; title('Post');
plot(time, post_gyro);
legend('roll', 'pitch', 'yaw');

linkaxes(axs, 'xy');
ylim(axs(1), 1.05*y_lims);
end

function [] = plot_pre_post_mag(mag_data, sol)
figure;
axs(1) = subplot(1, 2, 1); hold on; grid on; box off; title('Pre');
scatter3(mag_data(1, :), mag_data(2, :), mag_data(3, :), 4, 'filled');
xlabel('Mag_x');
ylabel('Mag_y');
zlabel('Mag_z');
[x, y, z] = sphere;

% We can generate an ellipsoid from a sphere by "undoing" a correction
ellipsoid = undo_ellipsoid_correction([x(:)'; y(:)'; z(:)'], sol);
xe = reshape(ellipsoid(1, :)', size(x));
ye = reshape(ellipsoid(2, :)', size(y));
ze = reshape(ellipsoid(3, :)', size(z));

surf(xe, ...
     ye, ...
     ze, ...
     'FaceAlpha', 0.2, 'EdgeAlpha', 0.2);

axis equal;

axs(2) = subplot(1, 2, 2); hold on; grid on; box off; title('Post');

corrected = ellipsoid_correction(mag_data, sol);

scatter3(corrected(1, :), corrected(2, :), corrected(3, :), 4, 'filled');

[x, y, z] = sphere;
surf(x, y, z, 'FaceAlpha', 0.2, 'EdgeAlpha', 0.2);

xlabel('Mag_x');
ylabel('Mag_y');
zlabel('Mag_z');
axis equal;

linkprop(axs, 'View');
end