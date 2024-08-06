% Standard Tag Object
% There are multiple types of tags, i.e, D4, D3, MTAG, etc. But they all
% collect the same data - motion data. (With a few other stuff involved).
% All tags inherit from baseTag
classdef Tag
    
    properties
        % All tag data will be resampled to 50 hz
        time

        % m/s/s
        accel

        % dps
        gyro

        % C
        temp

        % units irrelevant. magnetometer data is always normalized to 1
        % before doing any further processing
        mag

        % degrees
        % [roll pitch yaw]
        rpy_tag

        rpy_whale

        % depth (meters)
        depth
        
        name

        ball
        slides
    end

    methods (Abstract)
        % Tags have different sensor orientations. This flips and swaps the
        % axes around to get all sensor data into a universal orientiation
        adjust();
    end
    
    methods
        % default constructor. never called, so no need for implementation
        function self = Tag(); end

        % clear NaN's from data
        function self = clearnan(self)
            self.accel(isnan(self.accel)) = 0;
            self.mag(isnan(self.mag)) = 0;
            self.depth(isnan(self.depth)) = 0;
        end
        
        % generate euler angles from available tag data
        % must have at least accelerometer and magnetometer data
        function self = euler(self)
            % Determine algorithm depending on available variables
            % algo 
            %   1 : calc_naive_rpy. least restrictive. requires
            %       acceleration and magnetometer
            %   2 : madgwick algorithm. requires acceleration, gyroscope,
            %       and magnetometer
            % algo = 1;
            % if ~isempty(self.accel) & ~isempty(self.gyro) & ~isempty(self.mag)
            %     algo = 2;
            % elseif ~isempty(self.accel) & ~isempty(self.mag)
            %     algo = 1;
            % end
            % MADGWICK ALGORITHM IS CURRENTLY NOT SUPPORTED
            algo = 1;

            % temporarily set all algorithms to calc_naive_rpy (Ding's
            % stuff)
            
            if algo == 2
                AHRS = MadgwickAHRS('SamplePeriod', 1/50, 'Beta', 0.4);
                quaternion = zeros(length(self.time), 4);
                for t = 1:length(self.time)
                    AHRS.Update(self.gyro(t,:) * (pi/180), self.accel(t,:), self.mag(t,:));	% gyroscope units must be radians
                    quaternion(t, :) = AHRS.Quaternion;
                end
                euler = quatern2euler(quaternConj(quaternion)) * (180/pi);	% use conjugate for sensor frame relative to Earth and convert to degrees.
                self.rpy = euler;
                self = self.euler_to_heading();
            end

            if algo == 1
                % Generate tag frame eulers
                [roll_niv,pitch_niv,yaw_niv,~,~] = calc_rpy_naive(self.accel,self.mag,50,25);
                [~, ~, ~, roll_filt_nv, pitch_filt_nv, yaw_filt_nv] = ...
                    calc_dynamic_pose(roll_niv, pitch_niv, yaw_niv, 150);

                self.rpy_tag(:,1) = roll_filt_nv;
                self.rpy_tag(:,2) = pitch_filt_nv;
                self.rpy_tag(:,3) = yaw_filt_nv;
                
                % Generate whale frame eulers
                if ~isempty(self.depth)
                    if ~isempty(self.slides)
                        for i = 1:length(self.slides)-1
                            s = self.slides(i);
                            e = self.slides(i+1);
                            self = self.orient_into_whale_frame(s,e);
                        end
    
                        [roll_niv,pitch_niv,yaw_niv,~,~] = calc_rpy_naive(self.accel,self.mag,50,25);
                        [~, ~, ~, roll_filt_nv, pitch_filt_nv, yaw_filt_nv] = ...
                            calc_dynamic_pose(roll_niv, pitch_niv, yaw_niv, 150);
        
                        self.rpy_whale(:,1) = roll_filt_nv;
                        self.rpy_whale(:,2) = pitch_filt_nv;
                        self.rpy_whale(:,3) = yaw_filt_nv;
                    else
                        s = 1;
                        e = length(self.time);
                        self = self.orient_into_whale_frame(s,e);
    
                        [roll_niv,pitch_niv,yaw_niv,~,~] = calc_rpy_naive(self.accel,self.mag,50,25);
                        [~, ~, ~, roll_filt_nv, pitch_filt_nv, yaw_filt_nv] = ...
                            calc_dynamic_pose(roll_niv, pitch_niv, yaw_niv, 150);
        
                        self.rpy_whale(:,1) = roll_filt_nv;
                        self.rpy_whale(:,2) = pitch_filt_nv;
                        self.rpy_whale(:,3) = yaw_filt_nv;
                    end
                else
                    fprintf("No depth data for " + self.name + ", cannot correct orientation.");
                end

                
            end
        end
        
        % Extract the portion of the dataset where the tag is on the
        % animal
        function self = trial_extraction(self)
            % Make the plot
            fig = figure; clf(fig); hold on;
            ax = gca;
            for i = 1:3
                plot(self.time,self.accel(:,i));
            end
            xlabel("Time (seconds)")
            ylabel("Gyroscope Data")
            title("Draw a rectangle around the portion of the data where the tag is on the animal");
            
            % Get the bounds
            bounds = get_bounds(ax);
            close(fig);

            s = find_index(self.time,bounds(1));
            e = find_index(self.time,bounds(2));
            
            % Do the slicing
            self.time = self.time(s:e);
            self.time = self.time - self.time(1);
        
            if ~isempty(self.accel)
                self.accel = self.accel(s:e,:);
            end
        
            if ~isempty(self.gyro)
                self.gyro = self.gyro(s:e,:);
            end
            
            if ~isempty(self.temp)
                self.temp = self.temp(s:e);
            end
        
            if ~isempty(self.mag)
                self.mag = self.mag(s:e,:);
            end
        
            if ~isempty(self.rpy_tag)
                self.rpy_tag = self.rpy_tag(s:e,:);
            end
        
            if ~isempty(self.rpy_whale)
                self.rpy_whale = self.rpy_whale(s:e,:);
            end
        
            if ~isempty(self.depth)
                self.depth = self.depth(s:e);
            end
        end
        
        % Find slide times
        function self = slide_time(self)
            [section_idx_list, ~, ~] = ...
                find_tag_slide_times_func(self.accel, self.depth, 50, 10, 0.5);
            self.slides = section_idx_list;
        end

        % Rotate part of the dataset
        % Start_time and end_time are in seconds
        function self = apply_rotation(self, start_time, end_time)
            % Define the angles in degrees
            yaw_deg = 40;
            roll_deg = 40;
            
            % Convert angles to radians
            yaw_rad = deg2rad(yaw_deg);
            roll_rad = deg2rad(roll_deg);

            % Rotation matrix for yaw (rotation around z-axis)
            R_z = [cos(yaw_rad), -sin(yaw_rad), 0;
                   sin(yaw_rad),  cos(yaw_rad), 0;
                   0,            0,            1];
            
            % Rotation matrix for roll (rotation around x-axis)
            R_x = [1, 0,            0; 
                   0, cos(roll_rad), -sin(roll_rad);
                   0, sin(roll_rad),  cos(roll_rad)];

            % Combined rotation matrix (yaw followed by roll)
            R = R_z * R_x;

            s = find_index(self.time, start_time);
            e = find_index(self.time, end_time);

            self.accel(s:e,:) = self.accel(s:e,:) * R;
            self.mag(s:e,:) = self.mag(s:e,:) * R;
            if ~isempty(self.gyro)
                self.gyro(s:e,:) = self.gyro(s:e,:) * R;
            end
        end
                    
        % Accel, gyro, and mag plot
        function self = plot_core(self, fig_name)
            if ~exist('fig_name','var')
                fig_name = self.name;
            end

            fprintf("Plotting core data for " + self.name + "\n");
            fig = figure("Name",fig_name); clf(fig);

            % Calculate Number of Plots Based on Available Data
            vars = [~isempty(self.accel) ...
                    ~isempty(self.gyro)  ...
                    ~isempty(self.mag)   ...
                    ~isempty(self.rpy_tag)   ...
                    ~isempty(self.rpy_whale) ...
                    ~isempty(self.depth)];
            num_plots = sum(vars);
            current_plot = 1;

            % Acceleration Plot
            axs(current_plot) = subplot(num_plots,1,current_plot); hold on;
            for i = 1:width(self.accel)
                plot(self.time,self.accel(:,i))
            end
            legend("X","Y","Z")
            ylabel("Acceleration (m/s^2)")
            title(sprintf(self.name + " Acceleration"));
            xlabel("Time (seconds)")
            current_plot = current_plot + 1;
            
            % Gyroscope Plot
            if ~isempty(self.gyro)
                axs(current_plot) = subplot(num_plots,1,current_plot); hold on;
                for i = 1:width(self.gyro)
                    plot(self.time, self.gyro(:,i));
                end
                legend("X","Y", "Z");
                ylabel("Gyroscope (dps)");
                xlabel("Time (s)")
                title(sprintf(self.name + " Gyroscope"))
                current_plot = current_plot + 1;
            else
                fprintf("\tNo gyroscope data for " + self.name + "\n")
            end
            
            % Magnetometer Plot
            if ~isempty(self.mag)
                axs(current_plot) = subplot(num_plots,1,current_plot); hold on;
                for i = 1:width(self.mag)
                    plot(self.time,self.mag(:,i))
                end
                legend("X","Y","Z")
                ylabel("Magnetometer (units?)")
                title(sprintf(self.name + " Magnetometer"))
                xlabel("Time (s)")
                current_plot = current_plot + 1;
            else
                fprintf("\tNo magnetometer data for " + self.name + "\n");
            end

            % Tag euler angle plot
            if ~isempty(self.rpy_tag)
                axs(current_plot) = subplot(num_plots,1,current_plot); hold on;
                for i = 1:width(self.rpy_tag)
                    plot(self.time,self.rpy_tag(:,i))
                end
                legend("Roll","Pitch","Yaw")
                ylabel("Degrees")
                title(sprintf(self.name + " Tag Euler Angles"))
                xlabel("Time (s)")
                current_plot = current_plot + 1;
            else
                fprintf("\tNo tag euler angle data for " + self.name + "\n");
            end

            % Heading plot
            if ~isempty(self.rpy_whale)
                axs(current_plot) = subplot(num_plots,1,current_plot); hold on;
                for i = 1:width(self.rpy_whale)
                    plot(self.time,self.rpy_whale(:,i));
                end
                legend("Roll","Pitch","Yaw");
                ylabel("Degrees");
                title(sprintf(self.name + " Animal Euler Angles"));
                xlabel("Time (s)");
                current_plot = current_plot + 1;
            else
                fprintf("\tNo animal euler angle data for " + self.name + "\n");
            end

            % Depth plot
            if ~isempty(self.depth)
                axs(current_plot) = subplot(num_plots,1,current_plot); hold on;
                plot(self.time, self.depth);
                ylabel("Depth");
                title(sprintf(self.name + " Depth"));
                xlabel("Time (s)");
                current_plot = current_plot + 1;
            else
                fprintf("\tNo depth data for " + self.name + "\n");
            end

            linkaxes(axs,'x')
        end
        
        % Plot euler angles
        function self = plot_euler(self)
            fig = figure; clf(fig);
            hold on;
            for i = 1:3
                plot(self.time,self.rpy_tag(:,i));
            end
            legend("Roll","Pitch","Yaw")
            ylabel("Degrees")
            xlabel("Time (seconds)")
        end

        % This fits a ball to the magnetometer data, and centers the data
        % around [0 0 0] given the center of that ball. Essentially helps
        % to calibrate the magnetometer
        function self = adjust_ball(self)
            self.ball = fit_ball(self.mag);
            ball_x = self.ball.center(1);
            ball_y = self.ball.center(2);
            ball_z = self.ball.center(3);
            self.mag(:,1) = self.mag(:,1) - ball_x;
            self.mag(:,2) = self.mag(:,2) - ball_y;
            self.mag(:,3) = self.mag(:,3) - ball_z;
        end
        
        % Take the sin() of all the euler angles to fix jumping betwen -180
        % and 180 degrees
        function self = correct_euler(self)
            self.rpy_tag = sin(toRadians('degrees',self.rpy_tag));
            self.rpy_whale = sin(toRadians('degrees',self.rpy_whale));
        end
        
        % Unroll the euler angles. Alternate method to sin(). Recommended
        % to use correct_euler()
        function self = unwrap_euler(self)
            for i = 1:3
                self.rpy_tag(:,i) = unwrap(self.rpy_tag(:,i));
                self.rpy_whale(:,i) = unwrap(self.rpy_whale(:,i));
            end
        end
        
        % Calls MATLAB's magcal() function. basically this fits the
        % magnetometer data to a ball. fixes ellipses, rotations, etc. 
        function self = calibrate_magnetometer(self)
            sol = fit_ellipsoid(self.mag');
            self.mag = ellipsoid_correction(self.mag', sol);
            self.mag = self.mag';
        end
    end

    methods (Access=protected)

        % Roll, pitch, yaw, should be in degrees
        % NOT SUPPORTED, PART OF MADGWICK ALGORITHM
        function self = euler_to_heading(self)
            self.head = zeros(size(self.rpy));
            for i = 1:length(self.rpy)
               roll = deg2rad(self.rpy(i,1));
               pitch = deg2rad(self.rpy(i,2));
               yaw = deg2rad(self.rpy(i,3));
               R_x = [1 0 0;
                      0 cos(roll) -sin(roll);
                      0 sin(roll) cos(roll)];
               R_y = [cos(pitch) 0 sin(pitch);
                      0 1 0;
                      -sin(pitch) 0 cos(pitch)];
               R_z = [cos(yaw) -sin(yaw) 0;
                      sin(yaw) cos(yaw) 0;
                      0 0 1];
               R = R_z * R_y * R_x;
               direction_vector = R(:,1);
               self.head(i,:) = direction_vector';
            end
        end
        
        % Change tag frame into whale frame
        % s and e are the start and end indexes of the window
        function self = orient_into_whale_frame(self, s, e)
            [rot,~] = find_tag_orientation_func(self.accel(s:e,:), self.depth(s:e,:),50);
            self.accel(s:e,:) = self.accel(s:e,:) * rot;
            self.mag(s:e,:) = self.mag(s:e,:) * rot;
        end
    end
end

function [bounds] = get_bounds(ax,num)
    while (true)
        % Draw one rectangle corresponding to time the tag is on the animal
        drawrectangle(ax);
    
        % Confirm the drawings (user still has time to adjust the rectangles
        % until confirming with `y + [ENTER]`
        in_str = input('Confirm the drawn rectangles (Y, [N]): ', "s");
    
        if strcmpi(in_str, "Y")
            break;
        else
            % Delete the rectangles and start again
            for i = 1:num
                rects = findobj(ax, 'Type', 'images.roi.Rectangle');
                for r = 1:length(rects)
                    delete(rects(r));
                end
            end
        end
    end
    
    bounds = NaN*zeros(1, 2);
    rects = findobj(ax, 'Type', 'images.roi.Rectangle');
    bounds(1, 1:2) = [rects(1).Position(1), rects(1).Position(1)+rects(1).Position(3)];
end