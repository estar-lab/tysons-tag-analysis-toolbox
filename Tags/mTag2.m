classdef mTag2 < Tag
    %MTAG2 Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function self = mTag2(filepath,name)
            data = readtable(filepath);
            accel = [data.Accel_X data.Accel_Y data.Accel_Z];
            gyro = [data.Gyro_X data.Gyro_Y data.Gyro_Z];
            mag = [data.Mag_X data.Mag_Y data.Mag_Z];
            depth = data.Depth;

            old_time = data.Time / 1e3;
            Fs = 50;
            new_time = old_time(1):(1/Fs):old_time(end);
            
            self.accel = interp1(old_time, accel, new_time) / 1000 * 9.81;
            self.mag = interp1(old_time, mag, new_time);
            self.gyro = interp1(old_time, gyro, new_time);
            self.depth = interp1(old_time, depth, new_time);
            self.depth = self.depth';
            self.time = new_time';
            self.name = name;
        end
        
        function self = adjust(self)
            self.mag(:,2) = self.mag(:,2) * -1;
        end
    end
end

