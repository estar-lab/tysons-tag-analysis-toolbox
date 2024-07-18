classdef uTag < baseTag
    %TAG Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function self = uTag(filename, name)
            imu = readtable(filename);

            old_time = unwrap(imu.micros,2^31)/1e6;
            old_time = old_time - old_time(1);

            old_mag = [imu.mX imu.mY imu.mZ];

            old_accel = [imu.aX/1000 imu.aY/1000 imu.aZ/1000];
            old_accel = old_accel*10;

            Fs = 50;
            new_time = old_time(1):(1/Fs):old_time(end);
            new_time = new_time';

            self.accel = interp1(old_time, old_accel, new_time);
            self.mag = interp1(old_time, old_mag, new_time);
            self.time = new_time;

            self.name = name;
        end

        function self = adjust(self)
            self.accel(:,3) = self.accel(:,3) * -1;

            self.mag(:,:) = self.mag(:,:) * -1;
        end
    end
end

