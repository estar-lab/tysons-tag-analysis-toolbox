classdef mTag21 < Tag
    methods
        function self = mTag21(file_paths, name)
            accel = [];
            mag = [];
            gyro = [];
            depth = [];

            n = readtable(file_paths(1,:));
            accel = [n.AccelX n.AccelY n.AccelZ] / 1000 * 9.8;
            gyro = [n.GyroX n.GyroY n.GyroZ];
            mag = [n.MagX n.MagY n.MagZ];
            speed = n.Speed;

            old_time = n.Time;

            depth = n.Pressure;
            depth = depth(~isnan(depth));

            new_time = min(old_time):200:max(old_time);
            new_time = new_time';
            
            self.depth = interp1(old_time, depth, new_time);
            self.accel = interp1(old_time, accel, new_time);
            self.gyro = interp1(old_time, gyro, new_time);
            self.mag = interp1(old_time, mag, new_time);
            self.speed = interp1(old_time, speed, new_time);
            self.time = new_time;
            self.name = name;
            
        end

        function self = adjust(self) 
        end
    end
end
            
            