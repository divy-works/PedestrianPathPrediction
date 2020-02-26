%%
%concatenate data
clear all;clc;close all;
Training_Data = null(1);
Target_Data = null(1);
load('CircleDataNN.mat');
Training_Data = [Training_Data;[segment_train_x segment_train_y]];
Target_Data = [Target_Data;[segment_target_x segment_target_y]];
clearvars -except Training_Data Target_Data
load('RectangleDataNN.mat');
Training_Data = [Training_Data;[segment_train_x segment_train_y]];
Target_Data = [Target_Data;[segment_target_x segment_target_y]];
clearvars -except Training_Data Target_Data
load('DoubleEllipseDataNN.mat');
Training_Data = [Training_Data;[segment_train_x segment_train_y]];
Target_Data = [Target_Data;[segment_target_x segment_target_y]];
clearvars -except Training_Data Target_Data