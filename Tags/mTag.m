classdef mTag < baseTag
    %TAG Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function self = mTag(file_paths, name)
            accel = [];
            mag = [];
            for i = 1:length(file_paths)
                n = readmatrix(file_paths(i,:));
                accel = [accel; n(:,1:3)];
                mag = [mag; n(:,4:6)];
            end
            accel = accel / 2048 * -1;
            self.accel = accel * 10;
            self.mag = mag;
        
            time = 0.02:0.02:0.02*length(accel);
            time = time';
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

