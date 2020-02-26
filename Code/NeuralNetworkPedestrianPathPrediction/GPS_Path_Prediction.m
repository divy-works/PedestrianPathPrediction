%%
%receive the user input for the measurement file
clc;clear all;close all; %#ok<CLALL>
[measurement_file, measurement_file_path] = uigetfile({'*.csv'},'Measurement File Selector');
filename = strcat(measurement_file_path,measurement_file); 
[pathstr,name,ext] = fileparts(filename);

[ACCELEROMETERXms,ACCELEROMETERYms,ACCELEROMETERZms,GRAVITYXms,GRAVITYYms,GRAVITYZms,MAGNETICFIELDXT,MAGNETICFIELDYT,...
    MAGNETICFIELDZT,ORIENTATIONZazimuth,ORIENTATIONXpitch,ORIENTATIONYroll,LOCATIONLatitude,LOCATIONLongitude,LOCATIONAltitudem,...
    LOCATIONAltitudegooglem,LOCATIONSpeedKmh,LOCATIONAccuracym,LOCATIONORIENTATION,Satellitesinrange,Timesincestartinms,...
    YYYYMODDHHMISS_SSS] = importfile(filename);
%%
%receive user inputs for Sample Time and Prediction Time
prompt = {'file name','Sampling Rate(Hz):','Prediction Time(s):','Past Data Time(s):'};
dlg_title = 'Input Parameters';
num_lines = [1 40];

if(exist('defaultans','var'))
    %do nothing
else
    defaultans = {strcat(name,'.mat'),'10','1','3'};
end

answer = inputdlg(prompt,dlg_title,num_lines,defaultans,'on');

if(~isempty(answer))
    % configuration data
    mat_file_name = answer{1};
    sample_rate = str2num(answer{2});%#ok<*ST2NM>
    segment_target_len = str2num(answer{3})*sample_rate;
    segment_train_len = str2num(answer{4})*sample_rate;  
    defaultans={answer{1},answer{2},answer{3},answer{4}};
end

%find orientation
orientation_temp = null(1);
for(i=1:1:length(LOCATIONORIENTATION))
    orientation_temp = [orientation_temp;str2double(LOCATIONORIENTATION{i})]; %#ok<*AGROW>
end

indices = find(~isempty(orientation_temp)&~isnan(orientation_temp));

%obtain latitude longitude when orientation is not NAN
long = LOCATIONLongitude(indices);
lat = LOCATIONLatitude(indices);
%%
%convert from latitude longitude to x and y(cartesian)
[lng_x,lat_y,zone] = ll2utm(lat,long);
x_init = lng_x(1);
y_init = lat_y(1);
lng_x = lng_x - x_init;
lat_y = lat_y - y_init;
%%
save(mat_file_name,'lng_x','lat_y','x_init','y_init','indices','LOCATIONLongitude','LOCATIONLatitude','zone','segment_target_len','segment_train_len','name');
clearvars -except mat_file_name;
%%
%moving segment generation
load(mat_file_name);
%%
segment_train_y = null(1);
segment_train_x = null(1);
segment_target_y = null(1);
segment_target_x = null(1);

for(i=1:1:length(lat_y)-segment_train_len-segment_target_len+1)
    segment_train_temp_x = null(1);
    segment_train_temp_y = null(1);
    segment_target_temp_x = null(1);
    segment_target_temp_y = null(1);

    for(j=1:1:segment_train_len)
        segment_train_temp_y = [segment_train_temp_y lat_y(i+j-1)];
        segment_train_temp_x = [segment_train_temp_x lng_x(i+j-1)];        
    end
    
    for(k=i+j:1:i+j+segment_target_len-1)
        segment_target_temp_y = [segment_target_temp_y lat_y(k)];
        segment_target_temp_x = [segment_target_temp_x lng_x(k)];        
    end   
    init_y = lat_y(i+j-1);
    init_x = lng_x(i+j-1);
    segment_train_y = [segment_train_y;segment_train_temp_y - init_y];
    segment_train_x = [segment_train_x;segment_train_temp_x - init_x];
    segment_target_y = [segment_target_y;segment_target_temp_y - init_y];
    segment_target_x = [segment_target_x;segment_target_temp_x - init_x];
end
%%
segment_train_x = segment_train_x(:,end:-1:1);
segment_train_y = segment_train_y(:,end:-1:1);
segment_target_x = segment_target_x(:,end);
segment_target_y = segment_target_y(:,end);

%%
[row,col]=size(segment_train_y);
figure;
for(i=1:1:row)
    plot(segment_train_x(i,:),segment_train_y(i,:));grid on;hold on;
end
title('Path Segments');xlabel('X-coordinates');ylabel('Y-coordinates');
%%
save(strcat(name,'_NN.mat'),'segment_train_y','segment_train_x','segment_target_y','segment_target_x');