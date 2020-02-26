classdef special_filter
    methods(Static)
        function gauss_filt_val = gauss_filter(input,window_len)
            digits(50);
            gauss_coeff = gausswin(window_len);
            gauss_coeff = gauss_coeff/sum(gauss_coeff); % Normalize.
            gauss_filt_temp = conv(input,gauss_coeff);          
            gauss_filt_val = gauss_filt_temp(1:length(input));
        end
        
        function [var_x var_y var_xy norm_x norm_y] = calc_covar(x_data,y_data)
            % the line connecting starting and end point of path
            % segment is rotated to align with x-axis
            theta = atan2((y_data(end) - y_data(1)),(x_data(end) - x_data(1)));
            rotation_matrix = [cos(theta) sin(theta);-sin(theta) cos(theta)];
            temp_rotated = rotation_matrix*[x_data ; y_data];
            temp_x = temp_rotated(1,:);
            temp_y = temp_rotated(2,:);

            %normalization of the segment data
            norm_x = (temp_x - mean(temp_x))/std(temp_x);
            norm_y = (temp_y - mean(temp_y))/std(temp_y);

            %calculation of covariance
            temp_cov = cov(norm_x,norm_y);

            %separation of covariance and variance
            var_x = temp_cov(1,1);
            var_y = temp_cov(2,2);
            var_xy = temp_cov(1,2);
        end
        
        function median_out = median_filter(data, window)
            %pad data
            median_out = zeros(length(data),1);
            data = [ones(window-1,1)*data(1);data];
            for(index = window:1:length(data)) %#ok<*NO4LP>
                median_out(index - window + 1) = median(data((index-(0:window-1))));    %#ok<*AGROW>
            end         
        end
        
        function grad_out = calc_grad(data,window_len)
            window = zeros(1,window_len);
            window(1) = 1;
            window(end) = -1;
            temp = conv(data,window);
            grad_out = temp(1:length(data));
        end
        
        function index_out = find_index_threshold(data_in,threshold)
            indices = find((data_in) <= threshold);
            % only capture the start index
            index_out = null(1);
            count = 0;
            for(i = 2:1:length(indices))  
                if(count == 1)
                    if((indices(i) - indices(i-1))==1)
                        %do nothing%
                    else
                        count = 0;
                    end
                else 
                    if((indices(i) - indices(i-1)) == 1)
                        count = 1;
                        index_out = [index_out indices(i-1)];
                    end
                end
            end
        end
        
        function indices = mov_win_var_calc(data_in,window,var_threshold,mag_threshold)
            %padding the beginning with mean value of input data
            mean_val = mean(data_in);
            variance = zeros(length(data_in),1);
            data_in = [ones(window - 1,1)*mean_val;data_in];%padding with mean values
            for(i=window:1:length(data_in))
                variance(i-window+1) = std(data_in(i-window+1:i))^2;
            end
            
            magnitude = data_in(window:end);
            indices = find(variance<=var_threshold & abs(magnitude) <= mag_threshold);
        end 
        
        function dist = calc_dist(start_point,stop_point)
            dist = sqrt((start_point.Position(1) - stop_point.Position(1))^2 +...
                (start_point.Position(2) - stop_point.Position(2))^2);
        end
    end
end