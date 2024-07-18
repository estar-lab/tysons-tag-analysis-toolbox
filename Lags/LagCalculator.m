classdef LagCalculator

    properties
        % LagObject
        base

        % Array of Lag Objects
        tags = {};

        % Amount of time between peaks (seconds)
        p_width

        num_peaks
    end
    
    methods
        function self = LagCalculator(tags, base_index, peak_heights, peak_width)
            % Actually construct the lag object
            self.p_width = peak_width;

            self.base = LagObject(tags{base_index}, ...
                                  'az', ...
                                  peak_heights(base_index), ...
                                  peak_width);
            
            remaining_tags = tags;
            remaining_tags(base_index) = [];

            remaining_peak_heights = peak_heights;
            remaining_peak_heights(base_index) = [];
            
            self.tags(1:length(remaining_tags)) = {0};
            for i = 1:length(remaining_tags)
                self.tags{i} = LagObject(remaining_tags{i}, ...
                                         'az', ...
                                         remaining_peak_heights(i), ...
                                         peak_width);
            end
            
            % Find each synchronization signal
            peak_lengths = zeros(length(self.tags)+1,1);
            for i = 1:length(self.tags)
                peak_lengths(i) = length(self.tags{i}.p_locs);
            end
            peak_lengths(length(self.tags)+1) = length(self.base.p_locs);
            peak_num = min(peak_lengths);
            self.num_peaks = peak_num;
        
            self.base.p_vals = self.base.p_vals(1:peak_num);
            self.base.p_locs = self.base.p_locs(1:peak_num);
            for i = 1:length(self.tags)
                self.tags{i}.p_vals = self.tags{i}.p_vals(1:peak_num);
                self.tags{i}.p_locs = self.tags{i}.p_locs(1:peak_num);
            end

            self.plot_peaks();

            % Calculate the lags
            self = self.calculate_lags();

            
            self.plot_lags();
        end

        function self = calculate_lags(self)
            fprintf("Calculating Lags\n")

            window_size = self.p_width / 4;
            
            % we know that the lags for the first signal are zero, because
            % we synced the tags in the beginning
            self.base.lags(1) = 0;
            for i = 1:length(self.tags)
                self.tags{i}.lags(1) = 0;
            end

            for i = 2:self.num_peaks
                window_base = gen_window(self.base.p_locs(i),self.base.time,self.base.data,window_size);
                
                for j = 1:length(self.tags)
                    window_tag = gen_window(self.tags{j}.p_locs(i),self.tags{j}.time,self.tags{j}.data,window_size);   
                    lag = find_lag(window_base,window_tag);
                    self.tags{j}.lags(i) = lag;
        
                    % if i < 10
                    %     fprintf("\b\b\b\b%i/%i", i, self.num_peaks)
                    % elseif i >= 10
                    %     fprintf("\b\b\b\b\b%i/%i", i, self.num_peaks)
                    % end
                end
            end
            fprintf("\n")
        end

        function self = plot_peaks(self)
            fig = figure("Name", "Synchronization Signals Peak Plot"); clf(fig); hold on;
            for i = 1:length(self.tags)
                axs(i+1) = subplot(length(self.tags)+1,1,i+1); hold on;
                plot(self.tags{i}.time,self.tags{i}.data)
                scatter(self.tags{i}.p_locs,self.tags{i}.p_vals,'kx');
                xlabel("Time (seconds)");
                title(self.tags{i}.name);
            end
            axs(length(self.tags{i})) = subplot(length(self.tags)+1,1,1); hold on;
            plot(self.base.time,self.base.data);
            scatter(self.base.p_locs,self.base.p_vals,'kx');
            xlabel("Time (seconds)");
            title(self.base.name);
            linkaxes(axs,'x')
        end

        function self = plot_lags(self)
            fig = figure("Name", "Lags"); clf(fig); hold on;
            for i = 1:length(self.tags)
                axs(i) = subplot(length(self.tags),1,i); hold on;

                scatter(self.tags{i}.p_locs,self.tags{i}.lags);
                xlabel("Time (seconds)")
                ylabel("Lag (seconds)")
                title(self.tags{i}.name)
            end
            linkaxes(axs,'x');
            grid on;
        end
    end
end

function window = gen_window(peak_time, time, data, window_size)
    window = data;
    peak_index = find_index(time,peak_time);
    start = max(peak_index - window_size * 50 / 2,1);
    stop = min(peak_index + window_size * 50 / 2,length(data));
    window(1:start-1,stop+1:end) = 0;
    window(1:start-1) = 0;
    window(stop+1:end) = 0;
end

function lag = find_lag(window_base,window_tag)
    [R,lag] = xcorr(window_tag,window_base);
    R = R/max(R);
    [~,index] = max(abs(R));
    index_lag = lag(index);
    time_lag = index_lag/50;
    lag = time_lag;
end

