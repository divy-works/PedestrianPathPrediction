%%
%receive the user input for the measurement file
clear all;close all; %#ok<CLALL>
[measurement_file, measurement_file_path] = uigetfile({'*.csv'},'Measurement File Selector');
filename = strcat(measurement_file_path,measurement_file); 


[ACCELEROMETERXms,ACCELEROMETERYms,ACCELEROMETERZms,GRAVITYXms,GRAVITYYms,GRAVITYZms,MAGNETICFIELDXT,MAGNETICFIELDYT,...
    MAGNETICFIELDZT,ORIENTATIONZazimuth,ORIENTATIONXpitch,ORIENTATIONYroll,LOCATIONLatitude,LOCATIONLongitude,LOCATIONAltitudem,...
    LOCATIONAltitudegooglem,LOCATIONSpeedKmh,LOCATIONAccuracym,LOCATIONORIENTATION,Satellitesinrange,Timesincestartinms,...
    YYYYMODDHHMISS_SSS] = importfile(filename);
%%
%receive user inputs for Sample Time and Prediction Time
prompt = {'Sample Time(s):','Prediction Time(s):','Make Live Plot:(0 or 1):','File Name:'};
dlg_title = 'Input Parameters';
num_lines = [1 40];

if(exist('defaultans','var'))
    %do nothing
else
    defaultans = {'0.1','3','0','TestData.mat'};
end

answer = inputdlg(prompt,dlg_title,num_lines,defaultans,'on');

if(~isempty(answer))
    % configuration data
    sample_time = str2num(answer{1});%#ok<*ST2NM>
    prediction_time = str2num(answer{2});  
    make_live_plot = str2num(answer{3});
    file_name = answer{4};
    defaultans={answer{1},answer{2},answer{3},answer{4}};
end

%find orientation
orientation_temp = null(1);
for(i=1:1:length(LOCATIONORIENTATION))
    orientation_temp = [orientation_temp;str2double(LOCATIONORIENTATION{i})]; %#ok<*AGROW>
end

indices = find(~isempty(orientation_temp)&~isnan(orientation_temp));
orientation = orientation_temp(indices);

orientation = deg2rad(orientation);
orientation = special_filter.median_filter(orientation,40);
t =0:sample_time:(length(orientation)-1)*sample_time;

%obtain latitude longitude when orientation is not NAN
long = LOCATIONLongitude(indices);
lat = LOCATIONLatitude(indices);

%convert from latitude longitude to x and y(cartesian)
[lng_x,lat_y,zone] = ll2utm(lat,long);
x_init = lng_x(1);
y_init = lat_y(1);
lng_x = lng_x - x_init;
lat_y = lat_y - y_init;

%extract speed data from GPS data
speed = LOCATIONSpeedKmh(indices)*1000/3600;
t =0:sample_time:(length(speed)-1)*sample_time;

%find pedestrian speed using the cartesian values corresponding to latitude
%and longitude
disp_x = zeros(length(speed),1);
disp_y = zeros(length(speed),1);

for(i=2:1:length(speed))
    disp_x(i) = disp_x(i-1) + speed(i-1)*sample_time*cos(orientation(i-1));
    disp_y(i) = disp_y(i-1) + speed(i-1)*sample_time*sin(orientation(i-1));
end

%obtain the predicted path for pedestrian
predict_x = zeros(length(speed),1);
predict_y = zeros(length(speed),1);

for(i=2:1:length(speed))
    predict_x(i) = disp_x(i-1) + speed(i-1)*prediction_time*cos(orientation(i-1));
    predict_y(i) = disp_y(i-1) + speed(i-1)*prediction_time*sin(orientation(i-1));
end

%convert the predicted path to the latitude and longitude
    [actual_lat,actual_lng] = utm2ll(disp_y + x_init, disp_x + y_init,zone);
    [predict_lat,predict_lng] = utm2ll(predict_y + x_init, predict_x + y_init,zone);
    %%
    %plot latitude and longitude of pedestrian on Google Map
if(make_live_plot == 1)    
    scrsz = get(groot,'ScreenSize');
    figure('Position',[40 scrsz(4)*0.1 scrsz(3)*0.8 scrsz(4)*0.8])
    subplot(1,3,1);
    plot(long,lat,'g','linewidth',2);hold on;
    hold on;
    scatter(long(1), lat(1),'g*','linewidth',2);
    scatter(long(end), lat(end),'ro','filled','linewidth',2);
    plot_google_map('MapType','satellite');hold off;title('Pedestrian Path');xlabel('Longitude');ylabel('Latitude');
    long_margin = (max(long) - min(long))*0.2;
    lat_margin = (max(lat) - min(lat))*0.2;
    xlim([min(long)-long_margin max(long)+long_margin]);
    ylim([min(lat)-lat_margin max(lat)+lat_margin]);

    %plot pedestrian path in runtime
    x = disp_x;
    y = disp_y;
    %set the title for predicted cartesian path
    live_plot_cartesian_title = ['Pedestrian Path in Cartesian Coordinates' newline ...
        'Green Rectangle:Current Position, Cyan Rectangle:Future Position' newline ...
        'blue line:predicted, green line:actual path'];

    %occupy space on google map to plot the predicted trajectory
    annotation('textbox', [0.45 0.9 0.1 0.1],'String', live_plot_cartesian_title,'EdgeColor', 'k','HorizontalAlignment', 'center','FontWeight','bold');
        subplot(1,3,3);
        lat_lim = [min(lat) min(lat) max(lat) max(lat)];
        long_lim = [max(long) min(long) min(long) max(long)];
        scatter(long_lim, lat_lim);
        plot_google_map('MapType','satellite');hold on;
        xlim([min(long)-long_margin max(long)+long_margin]);
        ylim([min(lat)-lat_margin max(lat)+lat_margin]); 
        
     live_plot_map_title = ['Pedestrian Path in Latitude-longitude' newline ...
         'Green Rectangle:Current Position, Cyan Rectangle:Future Position'  newline ...
         'blue line: predicted path, green line:actual path'];
     annotation('textbox', [0.75 0.9 0.1 0.1],'String', live_plot_map_title,'EdgeColor', 'k','HorizontalAlignment', 'center','FontWeight','bold');
        subplot(1,3,3);
        xlabel('Longitude');ylabel('Latitude');

    for(i=1:1:length(x))
        subplot(1,3,2);
        plot(y(i),x(i),'gx','MarkerSize',0.5);grid on;hold on;
        xlabel('X');ylabel('Y');
        plot(predict_y(i),predict_x(i),'bx','MarkerSize',0.5);hold on;
        %legend('Actual Path','Predicted Path');
        axis([min(y)-2 max(y)+2 min(x)-2 max(x)+2]);
        RectPosCurr = [y(i)-0.75 x(i)-0.75 1.5 1.5];
        RectPosFuture = [predict_y(i)-0.75 predict_x(i)-0.75 1.5 1.5];
        showCurr = rectangle('Position',RectPosCurr,'FaceColor','g','Visible','on');
        showFuture = rectangle('Position',RectPosFuture,'FaceColor','c','Visible','on');

        subplot(1,3,3);
        plot(actual_lng(i),actual_lat(i),'gs','MarkerSize',0.5);
        plot(predict_lng(i),predict_lat(i),'bs','MarkerSize',2);hold on;
        %legend('','Actual Path','Predicted Path');
        RectPosCurrMap = [actual_lng(i)-long_margin*0.1 actual_lat(i)-lat_margin*0.1 long_margin*0.2 lat_margin*0.2];
        RectPosFutureMap = [predict_lng(i)-long_margin*0.1 predict_lat(i)-long_margin*0.1 long_margin*0.2 lat_margin*0.2];
        showCurrMap = rectangle('Position',RectPosCurrMap,'FaceColor','g','Visible','on');
        showFutureMap = rectangle('Position',RectPosFutureMap,'FaceColor','c','Visible','on');

        pause(0.00001/2);
        set(showCurr,'Visible','off');
        set(showFuture,'Visible','off');
        set(showCurrMap,'Visible','off');
        set(showFutureMap,'Visible','off');
        pause(0.00001/2);
    end
    subplot(1,3,2);
    showCurr = rectangle('Position',RectPosCurr,'FaceColor','g','Visible','on');
    showFuture = rectangle('Position',RectPosFuture,'FaceColor','c','Visible','on');
    subplot(1,3,3);
    showCurrMap = rectangle('Position',RectPosCurrMap,'FaceColor','g','Visible','on');
    showFutureMap = rectangle('Position',RectPosFutureMap,'FaceColor','c','Visible','on');
end