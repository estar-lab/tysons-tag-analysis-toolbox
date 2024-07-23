classdef dataLogger < Tag
    %TAG Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function self = dataLogger(filepath, name)
            self.name = name;
            data = readtable(filepath);
            
            Fs = 50;
            raw_time = data.General_Time - data.General_Time(1);
            raw_time = raw_time / 1e3;
            new_time = raw_time(1):(1/Fs):raw_time(end);

            raw_accel = [data.ISM330_AccelX_milli_g_ data.ISM330_AccelY_milli_g_ data.ISM330_AccelZ_milli_g_];
            raw_accel = raw_accel / 1e3 * 9.8;
            self.accel = interp1(raw_time, raw_accel, new_time);

            raw_gyro = [data.ISM330_GyroX_milli_dps_ data.ISM330_GyroY_milli_dps_ data.ISM330_GyroZ_milli_dps_];
            raw_gyro = raw_gyro / 1e3;
            self.gyro = interp1(raw_time, raw_gyro, new_time);

            % raw_temp = data.ISM330_Temperature_C_;
            % self.temp = interp1(raw_time, raw_temp, new_time);
            
            modded_mag_z = data.MMC5983_ZField_Gauss__;
            for i = 1:length(modded_mag_z)
                modded_mag_z{i} = str2double(modded_mag_z{i});
            end
            modded_mag_z = cell2mat(modded_mag_z);
            raw_mag = [data.MMC5983_XField_Gauss_ data.MMC5983_YField_Gauss_ modded_mag_z];
            self.mag = interp1(raw_time, raw_mag, new_time);
            self.mag(:,3) = self.mag(:,3) * -1;

            self.time = new_time;

            self = self.reorient_mag();
            self = self.reorient_accel();

        end

        function self = adjust(self)
            old_mag = self.mag;
            self.mag(:,1) = old_mag(:,2);
            self.mag(:,2) = old_mag(:,1) * -1;
            self.mag(:,3) = old_mag(:,3) * -1;

            old_accel = self.accel;
            self.accel(:,1) = old_accel(:,2);
            self.accel(:,2) = old_accel(:,1) * -1;
            self.accel(:,3) = old_accel(:,3) * -1;
        end
    end
end

