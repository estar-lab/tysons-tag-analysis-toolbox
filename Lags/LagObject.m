classdef LagObject
    %LAGOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        data
        time
        p_vals
        p_locs

        % How far apart are your synchronization signals (seconds)
        p_distance

        % Min value of the spike of your synchronization signals
        p_height

        % Amount of time between peaks (seconds)
        p_width

        % Lags at each peak location
        % Not valid for the base tag
        lags
    end
    
    methods
        % INPUTS:
        % tag
        %   baseTag object
        % which_data
        %   what stream of data do we want to use to characterize drift?
        %   current options:
        %       'az' : z-acceleration
        function self = LagObject(tag,which_data,peak_height,peak_width)
            if strcmp(which_data,'az')
                self.data = tag.accel(:,3);
            end
            self.name = tag.name;
            self.time = tag.time;
            self.p_height = peak_height;
            self.p_width = peak_width;
            
            self = self.find_peaks();
        end
        
        function self = find_peaks(self)    
            [self.p_vals,self.p_locs] = findpeaks(self.data,self.time,'MinPeakDistance',self.p_width,'MinPeakHeight',self.p_height);
        end
    end
end

