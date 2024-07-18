% Standard Tag Object
% There are multiple types of tags, i.e, D4, D3, MTAG, etc. But they all
% collect the same data - motion data. (With a few other stuff involved).
% All tags inherit from baseTag
classdef baseTag
    
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
        rpy 

        % n-by-3 3d heading of the animal, each roll combines the
        % pitch and yaw estimates and gives a 3d vector heading of
        % the animal. E.g. [1, 0, 0] means the animal is facing
        % magnetic north with 0 pitch. [0, 1, 0] means the animal is
        % facing west with 0 pitch. [0, 0, 1] means the animal is
        % having a 90 deg pitch looking at the sky.
        head

        % depth (meters)
        depth
        
        name
        ball
        mag_A
    end

    methods (Abstract)
        % Tags have different sensor orientations. This flips and swaps the
        % axes around to get all sensor data into a universal orientiation
        adjust();
    end
    
    methods
        % default constructor. each tag has it's own special import
        % function so this constructor doesn't need to do anything
        function self = baseTag(); end

        % clear NaN's from data
        function self = clearnan(self)
            self.accel(isnan(self.accel)) = 0;
            self.mag(isnan(self.mag)) = 0;
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
            algo = 1;
            if ~isempty(self.accel) & ~isempty(self.gyro) & ~isempty(self.mag)
                algo = 2;
            elseif ~isempty(self.accel) & ~isempty(self.mag)
                algo = 1;
            end
            algo = 3;

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
                [roll_niv,pitch_niv,yaw_niv,~,~] = calc_rpy_naive(self.accel,self.mag,50,25);
                [pitch_dp_nv, yaw_dp_nv, vector_dp_nv, roll_filt_nv, pitch_filt_nv, yaw_filt_nv] = ...
                    calc_dynamic_pose(roll_niv, pitch_niv, yaw_niv, 150);

                self.rpy(:,1) = roll_filt_nv;
                self.rpy(:,2) = pitch_filt_nv;
                self.rpy(:,3) = yaw_filt_nv;
                
                self.head = vector_dp_nv;
            end

            if algo == 3
                [roll,pitch,yaw,heading] = calc_naive_rpy(self.accel,self.mag,50);
                self.rpy(:,1) = roll;
                self.rpy(:,2) = pitch;
                self.rpy(:,3) = yaw;
                self.head = heading;
            end
        end
        
        % Accel, gyro, and mag plot
        function self = plot_core(self)
            fprintf("Plotting core data for " + self.name + "\n");
            fig = figure("Name",self.name); clf(fig);

            % Calculate Number of Plots Based on Available Data
            vars = [~isempty(self.accel) ~isempty(self.gyro) ~isempty(self.mag) ~isempty(self.rpy) ~isempty(self.head)];
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

            % Euler angle plot
            if ~isempty(self.rpy)
                axs(current_plot) = subplot(num_plots,1,current_plot); hold on;
                for i = 1:width(self.rpy)
                    plot(self.time,self.rpy(:,i))
                end
                legend("Roll","Pitch","Yaw")
                ylabel("Euler Angles)")
                title(sprintf(self.name + " Euler Angles)"))
                xlabel("Time (s)")
                current_plot = current_plot + 1;
            else
                fprintf("\tNo euler angle data for " + self.name + "\n");
            end

            % Heading plot
            if ~isempty(self.rpy)
                axs(current_plot) = subplot(num_plots,1,current_plot); hold on;
                for i = 1:width(self.head)
                    plot(self.time,self.head(:,i));
                end
                legend("North","West","Sky");
                ylabel("Heading");
                title(sprintf(self.name + " Heading"));
                xlabel("Time (s)");
                current_plot = current_plot + 1;
            else
                fprintf("\tNo heading angle data for " + self.name + "\n");
            end

            linkaxes(axs,'x')
        end
        
        % Plot euler angles
        function self = plot_euler(self)
            fig = figure; clf(fig);
            hold on;
            for i = 1:3
                plot(self.time,self.rpy(:,i));
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
            self.rpy = sin(toRadians('degrees',self.rpy));
        end
        
        % Unroll the euler angles. Alternate method to sin(). Recommended
        % to use correct_euler()
        function self = unwrap_euler(self)
            for i = 1:3
                self.rpy(:,i) = unwrap(self.rpy(:,i));
            end
        end
        
        % Calls MATLAB's magcal() function. basically this fits the
        % magnetometer data to a ball. fixes ellipses, rotations, etc. 
        function self = calibrate_magnetometer(self)
            [A,b,~]  = magcal(self.mag);
            self.mag = (self.mag-b)*A;
        end
    end

    methods (Access=protected)

        % Roll, pitch, yaw, should be in degrees
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
    end
end