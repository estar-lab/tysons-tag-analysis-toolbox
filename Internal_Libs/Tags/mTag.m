classdef mTag < Tag
    %TAG Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function self = mTag(file_paths, name)
            accel = [];
            mag = [];
            gyro = [];
            depth = [];
            for i = 1:length(file_paths)
                n = readtable(file_paths(i,:));
                accel = [accel; ...
                         n.accelX n.accelY n.accelZ];
                gyro = [gyro; ...
                         n.gyroX n.gyroY n.gyroZ];
                mag = [mag; ...
                         n.magX n.magY n.magZ];
                depth = [depth; n.depth];
            end
            depth = depth(~isnan(depth));
            depth_time = 0.2:0.2:0.2*length(depth);
            

            accel = accel / 2048 * -1;
            self.accel = accel * 10;
            self.mag = mag;
            self.gyro = gyro;
        
            time = 0.02:0.02:0.02*length(accel);
            time = time';

            depth = interp1(depth_time, depth, time);
            depth = depth * -1;
            % floor depth to 0
            depth = depth - max(depth);
            self.depth = depth;
            self.time = time;

            self.name = name;
        end

        function self = adjust(self)
            self.accel(:,3) = self.accel(:,3) * -1;
            self.accel(:,2) = self.accel(:,2) * -1;

            orig_x = self.mag(:,1);
            orig_y = self.mag(:,2);
            self.mag(:,2) = orig_x;
            self.mag(:,1) = orig_y;
        end
    end
end

