%% analysis_pulse
% Code to analyze BAM Pulse section. Based on Fujii et al. and the HBAT. 
% Author - MJH
%
% MM/DD/YY: CHANGELOG
% 02/04/20: File initialized. 
clearvars; clc; close all; 

%% Flags
doplot = 0; 

%% Pathing
dir_data = 'C:\Users\heard.49\Documents\GitHub\BAM_Matlab\data\YA_FST_BAM'; 
% Set this to whatever

cd ..
dir_exp = pwd; 
cd stim_pulse
dir_stim = pwd; 

%% Extract tempi of stimuli
stim = dir(fullfile(dir_stim, '*.wav')); stim = {stim(:).name}'; 
tempi = cellfun((@(x) strsplit(x, '_')), stim, 'UniformOutput', false); 
tempi = cellfun((@(x) str2double(x{2})), tempi, 'UniformOutput', false); 
tempi = cell2mat(tempi); 
period = (tempi.^-1)*60; 

beats  = [41 38 51 31 48 48 34 37 31 53 45 28 40 44 28]; 
nbeats = sum(beats); 
% p06 = 41
% p08 = 38
% p10 = 51
% p11 = 31
% p12 = 48
% p22 = 48
% p24 = 34
% p25 = 37
% p26 = 31
% p27 = 53
% p32 = 45
% p33 = 28
% p34 = 40
% p35 = 44
% p39 = 28

%% Load the data
files = dir(fullfile(dir_data, '*.mat')); 
SIent = nan(length(files), 1); 

for ff = 1:length(files)
    filename = fullfile(dir_data, files(ff).name); 
    load(filename)
    % relevant variables:
    % cond_p -- which pulse stim and when
    % p      -- subject params
    % p.condLabel2 -- legacy, name of cond columns
    % p.recLabel2  -- legacy, name of rec columns
    % p.condLabelPulse -- name of cond columns
    % p.recLabelPulse  -- name of rec columns
    % rec_p  -- actual data from pulse trial

    % Clean up a few stimuli name problems
    stimnames = cond_p(:, 2); 
    stimnames(strcmp(stimnames, 'p6_120_nomet.wav')) = 'p06_120_nomet.wav'; 
    stimnames(strcmp(stimnames, 'p8_110_nomet.wav')) = 'p08_110_nomet.wav';
    cond_p(:, 2) = stimnames; 
    
    %% Preallocate data vectors
    x = nan(1, nbeats); 
    y = nan(1, nbeats); 
    phase = nan(1, nbeats); 

    phase_idx = 1; 
    for ii = 1:size(cond_p, 1)
        %% Which stimuli are we looking at?
        this_stim = cond_p{ii, 2}; 
        stim_idx  = strcmp(this_stim, stim); 

    %     this_tempi  = tempi(stim_idx);
        this_period = period(stim_idx);
    %     this_beats  = beats(stim_idx); 
        this_data = rec_p(rec_p(:, 1) == ii, :);
    %     taps = this_data(:, 2); 
        space_down = this_data(:, 3); 
    %     space_up   = this_data(:, 4); 

        %% Calculate phase of tapping
        which_beat = round(space_down/this_period); 
        idx = 1; 
        for bb = 1:length(which_beat)
            phase(phase_idx) = (space_down(idx) - which_beat(bb)*this_period) * 180;
            idx = idx + 1; 
            phase_idx = phase_idx + 1; 
        end

        %% Extract x and y coordinates of each tap
        y = sind(phase);
        x = cosd(phase);
    end
    
    %% Compute resultant vector
    R = [mean(x), mean(y)]; % coordinates of the resultant vector
    R_length = sqrt(R(1)^2 + R(2)^2); 
    R_angle  = atand(R(2)/R(1)); 

    %% Plot the vectors
    if doplot
        % Make circle
        figure
        hold on
        th = 0:pi/50:2*pi; 
        xunit = cos(th); 
        yunit = sin(th); 
        plot(xunit, yunit); 

        % Add axes
        zero2 = -1:0.1:1; 
        zero1 = repelem(0, length(zero2)); 
        plot(zero1, zero2, 'k'); 
        plot(zero2, zero1, 'k');

        % Plot points
        scatter(x, y) % all taps
        scatter(mean(x), mean(y)) % resultant vector
        plot([0, R(1)], [0, R(2)])
        hold off

        % Histogram of taps
        figure
        phase_rad = deg2rad(phase); 
        polarhistogram(phase_rad, 72)

    end

    %% Manually build PDF
    % 72 bins, each one is 5 degrees, from -180 to 180
    % Then negative sum of (probability * natural log probability)
    nbins   = 72; 
    binsize = 5; 
    borders = -180:binsize:180; 

    pdf = zeros(nbins, 1); 

    for ii = 1:nbins
        thisbin = borders(ii:ii+1); 
        pdf(ii) = sum((phase > thisbin(1)) & (phase <= thisbin(2))); 
    end

    %% Calculate entropy
    pdf = pdf / length(phase); 
    pdf = pdf(pdf ~= 0); 
    SE = -1*sum(pdf .* log(pdf)); 
    SIent(ff) = 1 - SE/log(nbins); 
    
end
