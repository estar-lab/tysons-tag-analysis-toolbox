classdef D4 < baseTag
    %TAG Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function self = D4(filename,name)
            fprintf("Importing " + name + "\n");
            load(filename);
            self.accel = A.data;
            self.mag = M.data;
            if exist("P","var") == 1
                self.depth = P.data * -1;
                % floor depth to 0
                self.depth = self.depth - max(self.depth);
            end
            self.time = time' * 60 * 60;
            self.name = name;
        end

        function self = adjust(self)
            self.accel(:,1) = self.accel(:,1);
            self.accel(:,2) = self.accel(:,2) * -1;
            
            old_mag = self.mag;
            self.mag(:,1) = old_mag(:,2);
            self.mag(:,2) = old_mag(:,1) * -1;
            self.mag(:,3) = self.mag(:,3) * -1;
        end
    end
end

