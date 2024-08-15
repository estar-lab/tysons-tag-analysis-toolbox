% TODO
% Add protections for variables that don't exist

% Primary Operating Class
% Cluster all the tags together, and perform operations on all the tags,
% and perform operations that interact the tags together

classdef TagCluster

    properties
        % Cell array of baseTag objects, or any objects of which baseTag is
        % a parent class
        Tags
        
        % LagCalculator object. Do all the lag calculations in a seperate 
        % object to reduce complexity
        Lags
    end
    
    methods
        % Constructor
        % INPUTS:
        %   TagList : (cell array of baseTag or baseTag subobjects)
        %   enable_plots : (boolean) enable a few debugging plots during
        %       the constructor process
        %   window : 1x2 array. The first item is the desired start time.
        %   The second item is the desired end time. units are in seconds.
        function self = TagCluster(TagList, enable_plots, window)
            self.Tags = TagList;
            if enable_plots
                self.plot_accels("Orignal Acceleration");
            end

            % correct the tag orientations
            self = self.adjust_all();
            
            % typically the start and end of a data collection session
            % contains a bunch of random data from moving the tags around. 
            % use these indexes to chop off the beginning and end of a
            % dataset. units are in seconds.
            if ~exist('fig_name','var')
                start_time = 0;
                end_time = 100000000000;
            else
                start_time = window(1); 
                end_time = window(2);
            end

            for i = 1:length(self.Tags)
                start_index = find_index(self.Tags{i}.time, start_time);
                end_index = find_index(self.Tags{i}.time, end_time);
                self.Tags{i}.time = self.Tags{i}.time(start_index:end_index);
                self.Tags{i}.accel = self.Tags{i}.accel(start_index:end_index,:);
                self.Tags{i}.mag = self.Tags{i}.mag(start_index:end_index,:);
                
                if ~isempty(self.Tags{i}.depth)
                    self.Tags{i}.depth = self.Tags{i}.depth(start_index:end_index,:);
                end

                if ~isempty(self.Tags{i}.gyro)
                    self.Tags{i}.gyro = self.Tags{i}.gyro(start_index:end_index,:);
                end
            end

            for i = length(self.Tags)
                self.Tags{i} = self.Tags{i}.clearnan();
            end
            
        end
        
        

%% CLUSTER OPERATIONS
% the baseTag object has a number of different functions that can modify its own data
% ex: generating euler angles, adjusting orientations, etc
% these functions call the baseTag functions on every tag in the cluster
% so for the first one, calibrate_magnetometers() maps to
% calibrate_magnetometer() for every tag object

        % Runs a moving mean on tag animal yaws
        % k is the length of the window
        function self = moving_mean_yaw(self, k)
            fig = figure("Name","Moving Mean Plot"); clf(fig); hold on;
            for i = 1:length(self.Tags)
                axs(i) = subplot(length(self.Tags),1,i); hold on;
                plot(self.Tags{i}.time,self.Tags{i}.rpy_whale(:,3));
                self.Tags{i}.rpy_whale(:,3) = movmean(self.Tags{i}.rpy_whale(:,3), k);
                %self.Tags{i}.rpy_whale(:,3) = lowpass(self.Tags{i}.rpy_whale(:,3), 0.0000000001);
                plot(self.Tags{i}.time,self.Tags{i}.rpy_whale(:,3));
                xlabel("Time (seconds)");
                ylabel("Yaw (degrees)");
                legend("Raw Yaw", "Filtered Yaw");
                title("Moving Mean on Yaw")
            end
            linkaxes(axs, 'x');
        end
        
        % See Tag->slide_time()
        function self = slide_times(self)
            for i = 1:length(self.Tags)
                self.Tags{i} = self.Tags{i}.slide_time();
            end
        end

        % See Tag->trial_extraction()
        function self = trial_extractions(self)
            for i = 1:length(self.Tags)
                self.Tags{i} = self.Tags{i}.trial_extraction();
            end
        end
        
        % this internally calls magcal from the sensor funsion toolbox on
        % each tag
        % IDEAL PROCEDURE TO CORRECT MAGNETOMETERS
        % calibrate_magnetometers()
        % normalize_magnetometers()
        % adjust_balls()
        function self = calibrate_magnetometers(self)
            for i = 1:length(self.Tags)
                self.Tags{i} = self.Tags{i}.calibrate_magnetometer();
            end
        end
        
        % both unwrap_eulers() and correct_eulers() are a way to fix the
        % jumping between -180 and 180 degrees for the euler angles
        % 
        % unwrap_eulers() calls matlab's unwrap() on all the euler angles
        function self = unwrap_eulers(self)
            for i = 1:length(self.Tags)
                self.Tags{i} = self.Tags{i}.unwrap_euler();
            end
        end
    
        % takes the sin() of every euler angle
        function self = correct_eulers(self)
            for i = 1:length(self.Tags)
                self.Tags{i} = self.Tags{i}.correct_euler();
            end
        end

        % fits a sphere to each magnetometer ball
        function self = fit_balls(self)
            for i = 1:length(self.Tags)
                self.Tags{i}.ball = fit_ball(self.Tags{i}.mag);
            end
        end
        
        % fits a sphere to each magnetometer ball, and drags those balls to
        % the origin
        function self = adjust_balls(self)
            for i = 1:length(self.Tags)
                self.Tags{i} = self.Tags{i}.adjust_ball();
            end
        end
        
        % generates euler angles for each tag
        % algorithm changes depending on available data for each tag. (i.e
        % some tags do not log gyroscope data)
        function self = eulers(self)
            for i = 1:length(self.Tags)
                self.Tags{i} = self.Tags{i}.euler();
            end
        end
       
        % for each tag, normalize all the magnetometer data so that the max
        % magnetometer value for each tag is 1. essentially this should
        % give us really nice unit balls for the magnetometer data
        function self = normalize_magnetometers(self)
            for i = 1:length(self.Tags)
                max_value = max(abs(self.Tags{i}.mag(:,:)));
                self.Tags{i}.mag(:,:) = self.Tags{i}.mag(:,:) ./ max_value;
            end
        end

%% PLOTTING FUNCTIONS
% Naming convention: plot_{datastream}_{compare?}
% if "compare" is added, each portion of the datastream will be plotted on
% a subplot, with the same portion of the datastream for every tag on that
% subplot
% if "compare" is not added, each tag gets its own designated subplot
        
        % Plot acceleration data for all tags
        % Each tag gets its own subplot
        function self = plot_accels(self,fig_name)
            if ~exist('fig_name','var')
                fig_name = "All Tags Acceleration";
            end
            disp("Plotting accelerometer data")
            fig = figure("Name",fig_name); clf(fig);
            
            for i = 1:length(self.Tags)
                if isempty(self.Tags{i}.accel)
                    fprintf("\tNo accelerometer data for " + self.Tags{i}.name + "\n");
                end

                axs(i) = subplot(length(self.Tags),1,i); hold on;
                for j = 1:width(self.Tags{i}.accel)
                    plot(self.Tags{i}.time,self.Tags{i}.accel(:,j))
                end
                title(self.Tags{i}.name);
                legend("X","Y","Z")
                ylabel("Acceleration (m/s^2)")
                xlabel("Time (seconds");
                grid on;
            end
            linkaxes(axs,'x');
        end
        
        % Plot gyroscope data for all tags
        % Each tag gets its own subplot
        function self = plot_gyro(self,fig_name)
            disp("Plotting gyroscope data")
            fig = figure("Name",fig_name); clf(fig);

            for i = 1:length(self.Tags)
                if isempty(self.Tags{i}.gyro)
                    fprintf("\tNo Gyroscope data for " + self.Tags{i}.name + "\n")
                    continue;
                end

                axs(i) = subplot(length(self.Tags),1,i); hold on;
                for j = 1:width(self.Tags{i}.gyro)
                    plot(self.Tags{i}.time,self.Tags{i}.gyro(:,j));
                end
                title(self.Tags{i}.name);
                ylabel("Gyroscope Data (dps)")
                xlabel("Time (seconds)")
                legend("X", "Y", "Z")
                grid on;
            end
            linkaxes(axs,'x');
        end
        
        % Plot magnetometer data for all tags
        % Each tag gets its own subplot
        function self = plot_mags(self,fig_name)
            disp("Plotting magnetometer data")
            fig = figure("Name",fig_name); clf(fig);

            for i = 1:length(self.Tags)
                if isempty(self.Tags{i}.mag)
                    fprintf("\tNo magnetometer data for " + self.Tags{i}.name + "\n")
                    continue;
                end

                axs(i) = subplot(length(self.Tags),1,i); hold on;
                for j = 1:width(self.Tags{i}.mag)
                    plot(self.Tags{i}.time,self.Tags{i}.mag(:,j))
                end
                title(self.Tags{i}.name);
                ylabel("Magnetometer (units?)")
                xlabel("Time (seconds)")
                legend("Mag X", "Mag Y", "Mag Z")
                grid on;
            end
            linkaxes(axs, 'x');
        end
        
        % Plot magnetometer and accelerometer data for all tags
        % each tag gets its own subplot
        % accelerometer plots are on the left column
        % magnetometer plots are on the right column
        function self = plot_accels_mags(self,fig_name)
            fig = figure("Name",fig_name); clf(fig);

            for i = 1:length(self.Tags)
                if isempty(self.Tags{i}.accel)
                    fprintf("\tNo accelerometer data for " + self.Tags{i}.name + "\n")
                else
                    axs(2*i-1) = subplot(length(self.Tags),2,2*i-1); hold on;
                    for j = 1:width(self.Tags{i}.accel)
                        plot(self.Tags{i}.time,self.Tags{i}.accel(:,j))
                    end
                    title(self.Tags{i}.name + " Acceleration");
                    legend("X","Y","Z")
                    ylabel("Acceleration (m/s^2)")
                    grid on;
                end
                
                if isempty(self.Tags{i}.mag)
                    fprintf("\tNo magnetometer data for " + self.Tags{i}.name + "\n")
                else
                    axs(2*i) = subplot(length(self.Tags),2,2*i); hold on;
                    for j = 1:width(self.Tags{i}.mag)
                        plot(self.Tags{i}.time,self.Tags{i}.mag(:,j))
                    end
                    title(self.Tags{i}.name + " Magnetometer");
                    legend("X","Y","Z")
                    ylabel("Magnetometer")
                    grid on;
                end
            end
            linkaxes(axs,'x')
        end

        % Subplot for X,Y,Z of magnetometer and accelerometer
        % "Master" comparison plot
        function self = plot_accels_mags_compare(self,fig_name)
            if ~exist('fig_name','var')
                fig_name = "Master Comparison Plot";
            end
            fig = figure("Name",fig_name); clf(fig);

            names(1:length(self.Tags)) = {0};
            for i = 1:length(self.Tags)
                names{i} = self.Tags{i}.name;
            end

            labels = ["X" "Y" "Z"];

            for i = 1:3
                axs(2*i-1) = subplot(3,2,2*i-1); hold on;
                for j = 1:length(self.Tags)
                    plot(self.Tags{j}.time,self.Tags{j}.accel(:,i));
                end
                title("Accel " + labels(i));
                legend(names);
                ylabel("Acceleration (m/s^2)");
                xlabel("Time (s)");
                grid on;

                axs(2*i) = subplot(3,2,2*i); hold on;
                for j = 1:length(self.Tags)
                    plot(self.Tags{j}.time,self.Tags{j}.mag(:,i));
                end
                title("Magnetometer " + labels(i));
                legend(names);
                ylabel("Magnetometer");
                xlabel("Time (s)");
                grid on;
            end
            linkaxes(axs,'x');
        end

        % Plot tag euler angles for all tags
        % Each tag gets its own subplot
        function self = plot_tag_eulers(self,fig_name)
            fig = figure("Name",fig_name); clf(fig);
            for i = 1:length(self.Tags)
                if isempty(self.Tags{i}.rpy_tag)
                    fprintf("\tNo tag euler angles for " + self.Tags{i}.name + "\n");
                    continue;
                end
                axs(i) = subplot(length(self.Tags),1,i); hold on;
                for j = 1:3
                    plot(self.Tags{i}.time,self.Tags{i}.rpy_tag(:,j));
                end
                legend("Roll", "Pitch", "Yaw");
                xlabel("Time (seconds)")
                ylabel("Tag Euler Angles")
                title(self.Tags{i}.name);
                grid on;
            end
            linkaxes(axs,'x');
        end
        
        % Plot whale euler angles for all tags
        % Each tag gets its own subplot
        function self = plot_whale_eulers(self, fig_name)
            fig = figure("Name",fig_name); clf(fig);
            for i = 1:length(self.Tags)
                if isempty(self.Tags{i}.rpy_whale)
                    fprintf("\tNo whale euler angles for " + self.Tags{i}.name + "\n");
                    continue;
                end
                axs(i) = subplot(length(self.Tags),1,i); hold on;
                for j = 1:3
                    plot(self.Tags{i}.time,self.Tags{i}.rpy_whale(:,j))
                end
                xlabel("Time (seconds)")
                title(self.Tags{i}.name);
                legend("Roll", "Pitch", "Yaw");
                grid on;
            end
            linkaxes(axs,'x')
        end

        % Plot depths for all tags
        % Each tag gets its own subplot
        function self = plot_depth(self, fig_name)
            fig = figure("Name",fig_name); clf(fig);
            for i = 1:length(self.Tags)
                if isempty(self.Tags{i}.depth)
                    fprintf("\tNo depth data for " + self.Tags{i}.name + "\n");
                    continue;
                end
                axs(i) = subplot(length(self.Tags),1,i); hold on;
                plot(self.Tags{i}.time, self.Tags{i}.depth);
                xlabel("Time (seconds)");
                title(self.Tags{i}.name);
                ylabel("Depth");
                grid on;
            end
            linkaxes(axs,'x');
        end

        % plot the magnetometer balls for each tag, each in its seperate
        % axis.
        % INPUTS:
        %   ball_enable : (boolean) fits a sphere to each magnetometer
        %       ball, to visually see how close each ball is to a sphere.
        %       default value is false.
        function self = plot_magnetometer_balls(self, fig_name, ball_enable)
            if ~exist('fig_name','var')
                fig_name = "Magnetometer Balls";
            end

            if ~exist('ball_enable', 'var')
                ball_enable = false;
            end

            if ball_enable
                self = self.fit_balls();
            end

            fig = figure("Name",fig_name); clf(fig);
            for i = 1:length(self.Tags)
                if length(self.Tags) == 1
                    subplot(1,1,i); hold on; 
                elseif length(self.Tags) == 2
                    subplot(1,2,i); hold on;
                elseif length(self.Tags) <= 4
                    subplot(2,2,i); hold on;
                elseif length(self.Tags) <= 6
                    subplot(2,3,i); hold on;
                end
                
                scatter3(self.Tags{i}.mag(:, 1), self.Tags{i}.mag(:, 2), self.Tags{i}.mag(:, 3), 4, 'filled');
                 
            
                if ball_enable
                    [X,Y,Z] = sphere;
                    ball = self.Tags{i}.ball;
                    X = X*ball.r;
                    Y = Y*ball.r;
                    Z = Z*ball.r;
                    surf(X+ball.center(1),Y+ball.center(2),Z+ball.center(3))
                end
                
                % This generates a set of axes
                scatter3(0,0,0,"r","filled")  
                line = linspace(-10, 10, 100);
                zero = zeros(size(line));
                plot3(line,zero,zero,'r-')
                plot3(zero,line,zero,'r-')
                plot3(zero,zero,line,'r-')

                axis square; grid on;
                title(self.Tags{i}.name)
                xlim([-1.5 1.5])
                ylim([-1.5 1.5])
                zlim([-1.5 1.5])

                azimuth = 0;
                elevation = 0;
                view(azimuth,elevation);

                xlabel("X")
                ylabel("Y")
                zlabel("Z")
            end
        end
        
        % Generates a figure of euler angles, or headings, or whatever
        % datastream
        % Generates a realtime vector plot of the heading of all of the
        % tags. This is VERY HELPFUL for understanding datastreams
        function self = headings_realtime(self,fig_name)
            fig_sliders = figure("Name",fig_name); clf(fig_sliders);
            s(1:length(self.Tags)) = {0};
            for i = 1:length(self.Tags)
                axs(i) = subplot(length(self.Tags),1,i); hold on;
                plot(self.Tags{i}.time,self.Tags{i}.head(:,1));
                plot(self.Tags{i}.time,self.Tags{i}.head(:,2));
                plot(self.Tags{i}.time,self.Tags{i}.head(:,3));
                s{i} = xline(self.Tags{i}.time(1), 'k', 'LineWidth',2);
                legend("North", "West", "Sky")
                xlabel("Time (seconds)")
                title(self.Tags{i}.name)
            end
            linkaxes(axs,'x')

            fig = figure; clf(fig);
            hold on;

            line = linspace(-1, 1, 100);
            zero = zeros(size(line));
            quiver3(-1,0,0,2.2,0,0,'g');
            quiver3(0,-1,0,0,2.2,0,'r');
            quiver3(0,0,-1,0,0,2.2,'b');

            xlim = [-1 1];
            ylim = [-1 1];
            zlim = [-1 1];

            axis equal;
            axis([xlim,ylim,zlim]);
            xlabel('South - North');
            ylabel('East - West')
            zlabel('Down - Up')
            
            grid on;

            azimuth = 45;
            elevation = 30;
            view(azimuth,elevation);

            start = 1;
            h(1:length(self.Tags)) = {0};
            for i = 1:length(self.Tags)
                h{i} = quiver3(0,0,0,self.Tags{i}.head(start,1),self.Tags{i}.head(start,2),self.Tags{i}.head(start,3));
            end
            
            names(1:length(self.Tags)+3) = {0};
            names{1} = "";
            names{2} = "";
            names{3} = "";
            for i = 1:length(self.Tags)
                names{i+3} = self.Tags{i}.name;
            end
            legend(names)

            for i = 1:5:length(self.Tags{1}.time)-10
                for j = 1:length(self.Tags)
                    u = self.Tags{j}.head(i,1);
                    v = self.Tags{j}.head(i,2);
                    w = self.Tags{j}.head(i,3);
                    set(h{j}, 'UData', u, 'VData', v, 'WData', w);
                    set(s{j}, 'Value', self.Tags{j}.time(i))
                    pause(0.01);
                end
            end
        end

        % Plots the magnetometer balls for every tag on the same axis
        function self = plot_magnetometer_balls_compare(self, fig_name)
            fig = figure("Name",fig_name); clf(fig); hold on;
            scatter3(0,0,0,"r","filled")
            l = max(max(self.Tags{1}.mag));
            line = linspace(-l, l, 100);
            zero = zeros(size(line));
            plot3(line,zero,zero,'r-')
            plot3(zero,line,zero,'r-')
            plot3(zero,zero,line,'r-')
            
            for i = 1:length(self.Tags)
                scatter3(self.Tags{i}.mag(:, 1), self.Tags{i}.mag(:, 2), self.Tags{i}.mag(:, 3), 4, 'filled');
            end
            names(1:length(self.Tags)+4) = {0};
            names{1} = "";
            names{2} = "";
            names{3} = "";
            names{4} = "";
            for i = 1:length(self.Tags)
                names{i+4} = self.Tags{i}.name;
            end
            legend(names)
            xlabel("X")
            ylabel("Y")
            zlabel("Z")

            azimuth = 0;
            elevation = 0;
            view(azimuth,elevation);

            axis square; grid on;
        end

        % All rolls on one plot
        % All yaws on one plot
        % All pitches on one plot
        function self = plot_eulers_compare(self, fig_name)
            fig = figure("Name",fig_name); clf(fig);

            names(1:length(self.Tags)) = {0};
            for i = 1:length(self.Tags)
                names{i} = self.Tags{i}.name;
            end

            axs(1) = subplot(3,1,1); hold on;
            for j = 1:length(self.Tags)
                plot(self.Tags{j}.time, self.Tags{j}.rpy_tag(:,1));
            end
            legend(names)
            xlabel("Time (seconds)")
            ylabel("")
            title("Roll")
            grid on;

            axs(2) = subplot(3,1,2); hold on;
            for j = 1:length(self.Tags)
                plot(self.Tags{j}.time, self.Tags{j}.rpy_tag(:,2));
            end
            legend(names)
            xlabel("Time (seconds)")
            ylabel("")
            title("Pitch")
            grid on;

            axs(3) = subplot(3,1,3); hold on;
            for j = 1:length(self.Tags)
                plot(self.Tags{j}.time, self.Tags{j}.rpy_tag(:,3));
            end
            legend(names)
            xlabel("Time (seconds)")
            ylabel("")
            title("Yaw")
            grid on;

            linkaxes(axs, 'x');
        end

%% SPECIAL FUNCTIONS
% These functions do special things

        % construct the LagCalculator object
        % the LagCalculator object finds the drifts, and generates all the
        % plots inside its own constructor
        function self = lag_characterization(self, base_index, peak_heights, peak_width)
            self.Lags = LagCalculator(self.Tags,base_index,peak_heights,peak_width);
        end

        % synchronize all the tags. a window will
        % open up, and you will be able to select a portion of each
        % tag z-accelerometer data to line everything up.
        % TODO: 
        %   Add arguments to enable syncing across different lines of data
        %   What if tags are in different orientations
        %   What if we want to sync across magnetometer data
        function self = sync_tags(self)
            if length(self.Tags) == 1
                return
            end

            sync_signals(1:length(self.Tags)) = {0};

            % sync across z-acceleration
            for i = 1:length(self.Tags)
                sync_signals{i} = self.Tags{i}.accel(:,3);
            end
            
            % draw rectangles
            fig = figure; clf(fig);
            for i = 1:length(sync_signals)
                axs(i) = subplot(length(sync_signals),1,i);
                plot(sync_signals{i});
                title("Draw a Rectangle Around the Portion of the Signal that You Want to Use as the Basis for" + ...
                    " Synchronization")
            end
            linkaxes(axs, 'x');
            bounds = get_crosscorrelation_bounds(axs);
            
            % zero everything that isn't in the rectangle
            for i = 1:length(sync_signals)
                front = round(bounds(i,1));
                back = round(bounds(i,2));
                sync_signals{i}(1:front) = 0;
                sync_signals{i}(back:end) = 0;
            end
            

            clf(fig); hold on;
            subplot(2,1,1); hold on;
            for i = 1:length(sync_signals)
                plot(self.Tags{i}.time,sync_signals{i})
            end
            title("Pre-Synced Signals")
            
            % find the lags between all the tags, and the base tag
            % adjust time vectors accordingly
            base = sync_signals{1};
            for i = 2:length(self.Tags)
                [r,lag] = xcorr(base,sync_signals{i});
                [~,index] = max(abs(r));
                index_lag = lag(index);
                time_lag = index_lag/50;
                self.Tags{i}.time = self.Tags{i}.time + time_lag;
            end
            
            % compare the synced signal against the unsynced signal to
            % verify correct alignment
            subplot(2,1,2); hold on;
            for i = 1:length(sync_signals)
                plot(self.Tags{i}.time,sync_signals{i})
            end
            title("Synced Signals")
        end
    end

%% PRIVATE METHODS
    methods (Access=private)
        function self = adjust_all(self)
            for i = 1:length(self.Tags)
                self.Tags{i} = self.Tags{i}.adjust();
            end
        end
    end
end

%% END OF TAGCLUSTER

function [bounds] = get_crosscorrelation_bounds(axs)
    num_plots = length(axs);
    while (true)
        % Draw two rectangles corresponding to beginning and ending sync
        % signals
        for i = 1:num_plots
            drawrectangle(axs(i));
        end
    
        % Confirm the drawings (user still has time to adjust the rectangles
        % until confirming with `y + [ENTER]`
        in_str = input('Confirm the drawn rectangles (Y, [N]): ', "s");
    
        if strcmpi(in_str, "Y")
            break;
        else
            % Delete the rectangles and start again
            for i = 1:num_plots
                rects = findobj(axs(i), 'Type', 'images.roi.Rectangle');
                for r = 1:length(rects)
                    delete(rects(r));
                end
            end
        end
    end
    
    bounds = NaN*zeros(num_plots, 2);
    for i = 1:num_plots
        rects = findobj(axs(i), 'Type', 'images.roi.Rectangle');
        for k = 1:length(rects)
            bounds(i, (2*k-1):(2*k)) = [rects(k).Position(1), rects(k).Position(1)+rects(k).Position(3)];
            % sort to allow for rectangles to be input in any order
            bounds(i, :) = sort(bounds(i, :));
        end
    end
end

