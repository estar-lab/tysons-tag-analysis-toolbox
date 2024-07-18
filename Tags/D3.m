classdef D3 < baseTag
    %TAG Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function self = D3(filename, name)
            load(filename);

            old_time = TagData.timeSec;
            old_mag = TagData.magTag;
            old_accel = TagData.accelTag * 10;

            Fs = 50;
            new_time = old_time(1):(1/Fs):old_time(end);
            new_time = new_time';

            self.accel = interp1(old_time, old_accel, new_time);
            self.mag = interp1(old_time, old_mag, new_time);
            self.time = new_time;

            self.name = name;
        end
    end
end

