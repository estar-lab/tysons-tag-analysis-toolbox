classdef standardTag < Tag
    %TAG Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function self = standardTag(filename, name)
            fprintf("Importing " + name + "\n");
            load(filename);
            self.time = sliced_tag.time;
            self.accel = sliced_tag.accel;
            self.gyro = sliced_tag.gyro;
            self.temp = sliced_tag.temp;
            self.mag = sliced_tag.mag;
            self.rpy_tag = sliced_tag.rpy_tag;
            self.rpy_whale = sliced_tag.rpy_whale;
            self.depth = sliced_tag.depth;
            self.name = name;
        end

        function self = adjust(self)

        end

        function self = reorient_heading(self)
            
        end

        function self = reorient_mag(self)
            
        end

        function self = reorient_accel(self)
            
        end
       
    end
end

