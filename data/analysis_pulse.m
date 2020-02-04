%% analysis_pulse
% Code to analyze BAM Pulse section. Based on Fujii et al. and the HBAT. 
% Author - MJH
%
% MM/DD/YY: CHANGELOG
% 02/04/20: File initialized. Goal: load 1 subject of data. 
clearvars; clc; 

%% Pathing
dir_data = pwd; 
cd ..
dir_exp = pwd; 
cd stim_pulse
dir_stim = pwd; 

%% Load the data
filename = fullfile(dir_data, 'BAM_v1_demo_MH.mat'); 
% Can probably call dir('*.mat') in the long run?

load(filename)
% relevant variables:
% cond_p -- which pulse stim and when
% p      -- subject params
% p.condLabel2 -- legacy, name of cond columns
% p.recLabel2  -- legacy, name of rec columns
% p.condLabelPulse -- name of cond columns
% p.recLabelPulse  -- name of rec columns
% rec_p  -- actual data from pulse trial

%% Extract tempi of stimuli
stim = dir('*.wav'); stim = {stim(:).name}'; 
tempi = cellfun((@(x) strsplit(x, '_')), stim, 'UniformOutput', false); 
tempi = cellfun((@(x) str2double(x{2})), tempi, 'UniformOutput', false); 
tempi = cell2mat(tempi); 
period = (tempi.^-1)*60*1000; 

%% Compute entropy
% How many beats are there in the whole experiment
nbeats = 
% p06 = 41
% p08 = 38
% p10 = 51
% p11 = 31
% p12 = 48
% p22 = 48
% p24 = 34
% p25 = 
% p26 = 
% p27 = 
% p32 = 
% p33 = 
% p34 = 
% p35 = 
% p39 = 

%% Close up shop