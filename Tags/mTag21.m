classdef mTag21 < Tag
    methods
        function self = mTag21(file_paths, name)
            accel = [];
            mag = [];
            gyro = [];
            depth = [];

            n = readtable(file_paths(1,:));
            accel = [n.Accel_X n.Accel_Y n.Accel_Z] / 1000 * 9.8;
            gyro = [n.Gyro_X n.Gyro_Y n.Gyro_Z];
            mag = [n.Mag_X n.Mag_Y n.MagZ];
            speed = n.Speed_Pulses;

            old_time = n.Time / 1000;

            IR = n.IR;

            depth = n.Pressure;
            depth = depth(~isnan(depth));

            temp = n.Temp / 100;
            
            %new_time = min(old_time):0.1:max(old_time);
            new_time = min(old_time):0.02:max(old_time);
            new_time = new_time';
            
            self.depth = interp1(old_time, depth, new_time);
            self.accel = interp1(old_time, accel, new_time);
            self.gyro = interp1(old_time, gyro, new_time);
            self.mag = interp1(old_time, mag, new_time);
            self.speed = interp1(old_time, speed, new_time);
            self.time = new_time;
            self.name = name;
            self.IR = interp1(old_time, IR, new_time);
            self.temp = interp1(old_time, temp, new_time);
            
        end

        function self = adjust(self) 
            temp = self.accel(:,1);
            self.accel(:,1) = self.accel(:,2) * -1;
            self.accel(:,2) = temp * -1;
            
            temp = self.gyro(:,1);
            self.gyro(:,1) = self.gyro(:,2);
            self.gyro(:,2) = temp * -1;
            
            temp = self.mag(:,1);
            self.mag(:,1) = self.mag(:,2) * -1;
            self.mag(:,2) = temp * -1;
        end
    end
end
            
            