%% BAM_Matlab_v1
%
% a Matlab version of the Basic Aptitude of Music (BAM) test.
% Consists of melody discrimination, rhythm discrimination, and pulse
% production sections. 
% To administer, press Run, fill out subject information, 
% and guide the participant through the instructions.
%
% For exact timing information, double-check output latency of 
% PsychPortAudio and the flip interval of your monitor.
%
% Author -- Hyun-Woong Kim, The Ohio State University, khw173@gmail.com
%
% MM/DD/YY -- CHANGELOG
% 01/28/20 -- Preparing for distribution to multiple computers, starting
%   with the CCBBI testing rooms. MJH.
%   + Automatically determine output latency according to the computer. 
%   + Retrieved num2digit and added to script. 
%   + Resampled all stimuli to 44.1k and adjusted code accordingly
%   + Converted stimuli to mono and adjusted code accordingly
%   + RMS normalized stimuli and adjusted code accordingly
%   ~ Changed screen number (since I have multiple screens)
% 02/04/20 -- Generated some demo pulse data for analysis. Started scripts
%   for analysis. MJH. 
%   + Fixed logic for audio device selection
%   + Updated testing logic

sca; %DisableKeysForKbCheck([]); KbQueueStop;
clc; clear;

try 
    PsychPortAudio('Close'); 
    InitializePsychSound(1) % Assert low latency
catch
    disp('PsychPortAudio is already closed.')
    InitializePsychSound(1) % Assert low latency
end

testing = 0; 
textSize = 55; % Change this to change size of text (set 55 in default)
thisDevice = 5; % Change this to be specific to your computer
outputLatency = 21.995465; % in msecs, Change for your computer. 
ad = PsychPortAudio('GetDevices'); 
% Ideally we use ASIO. Otherwise, WASAPI. 
% Read PsychPortAudio('GetDevices?') for more info

if isnan(thisDevice)    
    host = {ad.HostAudioAPIName}; 
    if any(strcmp(host, 'ASIO')) % these are the ASIO devices
        ad = ad(strcmp(host, 'ASIO')); % these are the WASAPI drivers
    elseif any(strcmp(host, 'Windows WASAPI')) 
        ad = ad(strcmp(host, 'Windows WASAPI')); % these are the WASAPI drivers
    else
        error('No compatible audio devices.')
    end
    
    if length(ad) > 1
        error('Please choose an audio device to play stimuli!')
    else
        deviceid = ad.DeviceIndex; 
    end
    
else
    ad = ad(thisDevice == [ad.DeviceIndex]); 
    deviceid = ad.DeviceIndex; 
end

%% Collect subject information
rootdir = pwd;
expName = 'BAM_v1';					    
expDate = date;

if ~testing
    prompt = { 'Subject ID:', ...
           'Subject Initials:', ...
           'Skip Rhythm part (1 to skip):', ...
           'Skip Melody part (1 to skip):', ...
           'Skip Pulse part (1 to skip):' };
    dlg_in = inputdlg(prompt);
else
    dlg_in = {'00', 'test', '0', '0', '0'}; 
end

p.subjID  = str2double(dlg_in{1});
p.subjInitial  = upper(dlg_in{2});
    
% subject ID should be an integer number for between-subject conditions
if p.subjID~=round(p.subjID)
    error('invalid subject ID');
end

skip_r = str2double(dlg_in{3});
skip_m = str2double(dlg_in{4});
skip_p = str2double(dlg_in{5});
if skip_r ~= 1, skip_r = 0;  end
if skip_m ~= 1, skip_m = 0;  end
if skip_p ~= 1, skip_p = 0;  end

filename = strcat(rootdir, '/data/', expName, '_', num2digit(p.subjID,2));
dir_prac = [rootdir '/stim_prac'];
dir_r = [rootdir '/stim_rhythm'];
dir_m = [rootdir '/stim_melody'];
dir_p = [rootdir '/stim_pulse'];

DATAFOLDER = 'data';
if (~exist(DATAFOLDER,'dir'))
    mkdir(DATAFOLDER);
end

if exist([filename, '.mat'],'file')
    error('existing file name');
end


%% Set parameters

p.responseType = ["same","diff"];  % response type list
p.sampleRate = 44100;  % sample rate for [melody, rhythm, pulse ]

p.nStimMelody = 20;  % number of melody stimuli
p.nStimRhythm = 20;  % number of rhythm stimuli
p.nStimPulse = 15;  % number of pulse tracks

% setting variables using parameters above
resptype = p.responseType;
srate = p.sampleRate;
nstim_r = p.nStimRhythm;
nstim_m = p.nStimMelody;
nstim_p = p.nStimPulse;

% rhythm stimulus durations: [ r_start, r1_start, rest, r2_start, r_end ]
stim_durs = [0, 2.2, 5.2, 7, 10];


%% Stimulus conditions

% for melody and rhythm discrimination sections
p.condLabel = {'trialNumber','stimulusCondition','stimulusIndex'};
p.recLabel = {'trialIndex','RT','correctness'};

% for pulse production section
p.condLabelPulse = {'trialNumber','stimulusIndex'};
p.recLabelPulse = {'trialNumber','tapIndex','tapStartTime','tapEndTime'};

% for practice blocks
pcond_r = strings(3,length(p.condLabel1));
pcond_r(:,2) = ["same","diff","diff"];
pcond_r(:,3) = ["r11S.wav","r1D.wav","r5D.wav"];

pcond_m = strings(3,length(p.condLabel1));
pcond_m(:,2) = ["diff","same","same"];
pcond_m(:,3) = ["m1D.wav","m7S.wav","m13S.wav"];

pcond_p = strings(2,length(p.condLabel2));
pcond_p(:,2) = ["pulsepractice.wav","pulsevisualpractice.wav"];

% for main rhythm part
files = dir(dir_r);
fnames = strings(nstim_r,1);
in=0;
for i=1:length(files) 
    if contains(files(i).name,'wav')
        in=in+1;  fnames(in,1) = files(i).name;
    end
end
cond_r = strings(nstim_r,length(p.condLabel1));
cond_r(:,1) = 1:nstim_r;
cond_r(:,3) = fnames(randperm(nstim_r));
cond_r(contains(cond_r(:,3),"S"),2) = "same";
cond_r(contains(cond_r(:,3),"D"),2) = "diff";

% for main melody part
files = dir(dir_m);
fnames = strings(nstim_m,1);
in=0;
for i=1:length(files) 
    if contains(files(i).name,'wav')
        in=in+1;  fnames(in,1) = files(i).name;
    end
end
cond_m = strings(nstim_m,length(p.condLabel1));
cond_m(:,1) = 1:nstim_r;
cond_m(:,3) = fnames(randperm(nstim_r));
cond_m(contains(cond_m(:,3),"S"),2) = "same";
cond_m(contains(cond_m(:,3),"D"),2) = "diff";

% for pulse production part
files = dir(dir_p);
fnames = strings(nstim_p,1);
in=0;
for i=1:length(files) 
    if contains(files(i).name,'wav')
        in=in+1;  fnames(in,1) = files(i).name;
    end
end
cond_p = strings(nstim_p,length(p.condLabel2));
cond_p(:,1) = 1:nstim_p;
cond_p(:,2) = fnames(randperm(nstim_p));

% variable for recording
rec_r = nan(nstim_r,length(p.recLabel1));
rec_r(:,1) = 1:nstim_r;
rec_m = nan(nstim_m,length(p.recLabel1));
rec_m(:,1) = 1:nstim_m;
rec_p = nan(10000,length(p.recLabel2));


%% Generate or load auditory stimuli
% Same as preallocating variables, loading stimuli into Matlab before
% running the code helps keep Matlab's timing accurate. 

% generate audio outputs for practice
audio_r_prac = cell(3,1);  audio_m_prac = cell(3,1);  audio_p_prac = cell(2,1);
for t=1:3
    stimfile = [dir_prac '/' char(pcond_r(t,3))];
    [audio_tmp,~] = audioread(stimfile);
    audio_r_prac{t} = [audio_tmp'; audio_tmp'];
    
    stimfile = [dir_prac '/' char(pcond_m(t,3))];
    [audio_tmp,~] = audioread(stimfile);
    audio_m_prac{t} = [audio_tmp'; audio_tmp'];
    
    if t<3
        stimfile = [dir_prac '/' char(pcond_p(t,2))];
        [audio_tmp,fs] = audioread(stimfile);

        if fs~=srate  % double-check the sampling rate of audio files
            pcond_p(t,3) = fs;
        end
        audio_p_prac{t} = [audio_tmp'; audio_tmp'];
    end
end

% generate audio outputs for main expt
audio_rhythm = cell(nstim_r,1);
for t=1:nstim_r
    stimfile = [dir_r '/' char(cond_r(t,3))];
    [audio_tmp,fs] = audioread(stimfile);
    
    if fs~=srate  % double-check the sampling rate of audio files
        error('sampling rate is not equal to what you set');
    end
    audio_rhythm{t} = [audio_tmp'; audio_tmp'];
end

audio_melody = cell(nstim_m,1);
for t=1:nstim_r
    stimfile = [dir_m '/' char(cond_m(t,3))];
    [audio_tmp,fs] = audioread(stimfile);
    
    if fs~=srate  % double-check the sampling rate of audio files
        error('sampling rate is not equal to what you set');
    end
    audio_melody{t} = [audio_tmp'; audio_tmp'];
end

audio_pulse = cell(nstim_p,1);
for t=1:nstim_p
    stimfile = [dir_p '/' char(cond_p(t,2))];
    [audio_tmp,fs] = audioread(stimfile);
    
    if fs~=srate  % double-check the sampling rate of audio files
        error('sampling rate is not equal to what you set');
    end
    audio_pulse{t} = [audio_tmp'; audio_tmp'];
end

% SPEAKER ICON AND FIXATION CROSS
speaker_mat = imread(fullfile(rootdir, 'Speaker_Icon.png'));
crossCoords = [-20, 20, 0, 0; 0, 0, -20, 20]; 

%% Open PsychToolbox (PTB) and RTBox
% PTB is used to generate the screen which the participant will see, and to
% present the auditory stimuli. If anyone is interested in learning to use 
% this incredibly powerful toolbox, I highly recommend checking out these 
% tutorials: http://peterscarfe.com/ptbtutorials.html
% [wPtr, rect] = Screen('OpenWindow', 0, 0);
Screen('Preference', 'SkipSyncTests', 1); 
if testing==1
    [w, rect] = Screen('OpenWindow', 1, 0, [0 0 800 600]);
else
    [w, rect] = Screen('OpenWindow', 1, 0);
end
p.ScreenIFI = Screen('GetFlipInterval', w);
cx = rect(3)/2;  cy = rect(4)/2;
Screen('TextSize', w, textSize);

DrawFormattedText(w, 'Please wait...', 'center', 'center', 255);
Screen('Flip', w);
WaitSecs(1);

ListenChar(2);
HideCursor(); 

InitializePsychSound(1);
pahandle = PsychPortAudio('Open', deviceid, [], 1, srate, 2);

% RTBox is used to collect subject response and maintain timing of the
% experiment. It was originally designed for use in MRI, but I prefer to
% use it in behavioral experiments as well. There are very few tutorials
% online, so I recommend reading RTBox.m and RTBoxdemo.m 
RTBox('fake', 1);
RTBox('UntilTimeout', 1);
RTBox('ButtonNames', {'left', 'right', 'space', '4'});

% I convert the speaker image matrix into a texture at this point so the
% experiment runs faster. 
speaker_tex = Screen('MakeTexture', w, speaker_mat);


%% Rhythm part

if ~skip_r
    
% Practice block
str = 'Welcome to the rhythm portion of the test.';
str = [str '\n\nYou will hear 4 low clicks and then a rhythm.'];
str = [str '\nThis will be followed by another 4 clicks and another rhythm.'];
str = [str '\nThe second rhythm is either the SAME or DIFFERENT as the first rhythm.'];
str = [str '\n\nIf the rhythms are the SAME, press the LEFT arrow key.'];
str = [str '\nIf the rhythms are DIFFERENT, press the RIGHT arrow key.'];
str = [str '\n\nPress the space bar to begin a short practice'];

DrawFormattedText(w, str, 'center', 'center', 255, [], [], [], 1.1);
Screen('Flip', w);
RTBox('Clear');
RTBox(inf);

quitit=0;
while ~quitit

    t0 = Screen('Flip', w);
    WaitTill(t0 + 2);

    correct = 0;
    intv = 1;  % inter-trial interval
    for t = 1:3
        % trial condition
        target = pcond_r(t,2);

        % fill buffer 
        PsychPortAudio('FillBuffer', pahandle, audio_r_prac{t});
        Screen('Flip', w);

        WaitSecs(intv);
        PsychPortAudio('Start', pahandle);
        WaitSecs( outputLatency*.001 - p.ScreenIFI ); % to match the audio latency
        t0=Screen('Flip', w);

        in=1;
        for j=1:2
            % draw fixation during 4 drums
            Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
            Screen('Flip', w, t0+stim_durs(in));  in=in+1;

            % rhythm start
            Screen('DrawTexture', w, speaker_tex);
            Screen('Flip', w, t0+stim_durs(in));  in=in+1;
        end

        DrawFormattedText(w, 'SAME', cx - 350, 'center', 255);
        DrawFormattedText(w, 'DIFFERENT', cx + 150, 'center', 255);
        Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
        tstart = Screen('Flip', w, t0+stim_durs(in));

        RTBox('Clear'); 
        [~, answer] = RTBox(inf);

        if strcmp('left', answer),  key=resptype(1);
        elseif strcmp('right', answer),  key=resptype(2);
        else,  key='X';  % If subject timed out
        end

        % feedback
        if key==target  % If correct
            correct = correct + 1;
            DrawFormattedText(w, 'You are correct! Good job!', 'center', 'center', 255);
        else % If wrong
            DrawFormattedText(w, 'Oops, wrong answer!', 'center', 'center', 255);
        end

        PsychPortAudio('Stop', pahandle);
        t0 = Screen('Flip', w);
        WaitTill(t0 + intv);
    end

    % practice results
    str = 'Press the left arrow key to repeat the practice\nor press the space bar';
    DrawFormattedText(w, str, 'center', 'center', 255, [], [], [], 1.2);
    Screen('Flip', w);

    WaitSecs(0.5);
    RTBox('Clear');
    [~, cont] = RTBox(inf);
    if strcmp(cont, 'space')  % move onto main blocks
        DrawFormattedText(w, 'Please wait...', 'center', 'center', 255);
        t0=Screen('Flip', w);
        WaitTill(t0 + 2);
        quitit=1;
    else  % try a practice block again
        DrawFormattedText(w, 'Please wait...', 'center', 'center', 255);
        t0=Screen('Flip', w);
        Screen('Flip', w, t0+2);
    end
end

% Main experiment
str = 'Now the real test will begin.';
str = [str '\n\nYou have 5 seconds to respond to each trial.'];
str = [str '\nYou will not be told if you are right or wrong.'];
str = [str '\n\nPress the space bar to begin.'];
DrawFormattedText(w, str, 'center', 'center', 255, [], [], [], 1.2);
Screen('Flip', w);
RTBox('Clear');
RTBox(inf);

intv = 1;  % inter-trial interval
WaitSecs(intv);
for t=1:nstim_r
    % trial condition
    target = cond_r(t,2);

    % fill buffer 
    PsychPortAudio('FillBuffer', pahandle, audio_rhythm{t});
    Screen('Flip', w);

    WaitSecs(intv);
    PsychPortAudio('Start', pahandle);
    WaitSecs( outputLatency*.001 - p.ScreenIFI ); % to match the audio latency
    t0=Screen('Flip', w);

    in=1;
    for j=1:2
        % draw fixation during 4 drums
        Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
        Screen('Flip', w, t0+stim_durs(in));  in=in+1;

        % rhythm start
        Screen('DrawTexture', w, speaker_tex);
        Screen('Flip', w, t0+stim_durs(in));  in=in+1;
    end

    DrawFormattedText(w, 'SAME', cx - 350, 'center', 255);
    DrawFormattedText(w, 'DIFFERENT', cx + 150, 'center', 255);
    Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
    tstart = Screen('Flip', w, t0+stim_durs(in));

    [thisresp, answer] = RTBox(inf); 
    if ~isempty(thisresp) % Stop bug if subject times out
        rec_r(t,2) = thisresp-tstart;
    end

    if strcmp('left', answer),  key=resptype(1);
    elseif strcmp('right', answer),  key=resptype(2);
    else,  key=0;  % If subject timed out
    end

    if key==target
        rec_r(t,3) = 1;
    else
        rec_r(t,3) = 0;
    end

    PsychPortAudio('Stop', pahandle);
    t0 = Screen('Flip', w);
    WaitSecs(intv);
end

% End of experiment
DrawFormattedText(w, 'End of the rhythm portion.\n\nPlease the space bar to continue.', 'center', 'center', 255);
Screen('Flip', w);
WaitSecs(4);

end


%% Melody part

if ~skip_m

% Practice block
str = 'Welcome to the melody portion of the test.';
str = [str '\n\nYou will hear 4 low clicks and then a melody.'];
str = [str '\nThis will be followed by another 4 clicks and another melody.'];
str = [str '\nThe second melody is either the SAME or DIFFERENT as the first melody.'];
str = [str '\n\nIf the melodies are the SAME, press the LEFT arrow key.'];
str = [str '\nIf the melodies are DIFFERENT, press the RIGHT arrow key.'];
str = [str '\n\nPress the space bar to begin a short practice'];

DrawFormattedText(w, str, 'center', 'center', 255, [], [], [], 1.1);
Screen('Flip', w);
RTBox('Clear');
RTBox(inf);

quitit=0;
while ~quitit

    t0 = Screen('Flip', w);
    WaitTill(t0 + 2);

    correct = 0;
    intv = 1;  % inter-trial interval
    for t = 1:3
        % trial condition
        target = pcond_m(t,2);

        % fill buffer 
        PsychPortAudio('FillBuffer', pahandle, audio_m_prac{t});
        Screen('Flip', w);

        WaitSecs(intv);
        PsychPortAudio('Start', pahandle);
        WaitSecs( outputLatency*.001 - p.ScreenIFI ); % to match the audio latency
        t0=Screen('Flip', w);

        in=1;
        for j=1:2
            % draw fixation during 4 drums
            Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
            Screen('Flip', w, t0+stim_durs(in));  in=in+1;

            % rhythm start
            Screen('DrawTexture', w, speaker_tex);
            Screen('Flip', w, t0+stim_durs(in));  in=in+1;
        end

        DrawFormattedText(w, 'SAME', cx - 350, 'center', 255);
        DrawFormattedText(w, 'DIFFERENT', cx + 150, 'center', 255);
        Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
        tstart = Screen('Flip', w, t0+stim_durs(in));

        RTBox('Clear'); 
        [~, answer] = RTBox(inf);

        if strcmp('left', answer),  key=resptype(1);
        elseif strcmp('right', answer),  key=resptype(2);
        else,  key='X';  % If subject timed out
        end

        % feedback
        if key==target  % If correct
            correct = correct + 1;
            DrawFormattedText(w, 'You are correct! Good job!', 'center', 'center', 255);
        else % If wrong
            DrawFormattedText(w, 'Oops, wrong answer!', 'center', 'center', 255);
        end

        PsychPortAudio('Stop', pahandle);
        t0 = Screen('Flip', w);
        WaitTill(t0 + intv);
    end

    % practice results
    str = 'Press the left arrow key to repeat the practice\nor press the space bar';
    DrawFormattedText(w, str, 'center', 'center', 255, [], [], [], 1.2);
    Screen('Flip', w);

    WaitSecs(0.5);
    RTBox('Clear');
    [~, cont] = RTBox(inf);
    if strcmp(cont, 'space')  % move onto main blocks
        DrawFormattedText(w, 'Please wait...', 'center', 'center', 255);
        t0=Screen('Flip', w);
        WaitTill(t0 + 2);
        quitit=1;
    else  % try a practice block again
        DrawFormattedText(w, 'Please wait...', 'center', 'center', 255);
        t0=Screen('Flip', w);
        Screen('Flip', w, t0+2);
    end
end

% Main experiment
str = 'Now the real test will begin.';
str = [str '\n\nYou have 5 seconds to respond to each trial.'];
str = [str '\nYou will not be told if you are right or wrong.'];
str = [str '\n\nPress the space bar to begin.'];
DrawFormattedText(w, str, 'center', 'center', 255, [], [], [], 1.2);
Screen('Flip', w);
RTBox('Clear');
RTBox(inf);

intv = 1;  % inter-trial interval
WaitSecs(intv);
for t=1:nstim_m
    % trial condition
    target = cond_m(t,2);

    % fill buffer 
    PsychPortAudio('FillBuffer', pahandle, audio_melody{t});
    Screen('Flip', w);

    WaitSecs(intv);
    PsychPortAudio('Start', pahandle);
    WaitSecs( outputLatency*.001 - p.ScreenIFI ); % to match the audio latency
    t0=Screen('Flip', w);

    in=1;
    for j=1:2
        % draw fixation during 4 drums
        Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
        Screen('Flip', w, t0+stim_durs(in));  in=in+1;

        % rhythm start
        Screen('DrawTexture', w, speaker_tex);
        Screen('Flip', w, t0+stim_durs(in));  in=in+1;
    end

    DrawFormattedText(w, 'SAME', cx - 350, 'center', 255);
    DrawFormattedText(w, 'DIFFERENT', cx + 150, 'center', 255);
    Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
    tstart = Screen('Flip', w, t0+stim_durs(in));

    [thisresp, answer] = RTBox(inf); 
    if ~isempty(thisresp) % Stop bug if subject times out
        rec_m(t,2) = thisresp-tstart;
    end

    if strcmp('left', answer),  key=resptype(1);
    elseif strcmp('right', answer),  key=resptype(2);
    else,  key=0;  % If subject timed out
    end

    if key==target
        rec_m(t,3) = 1;
    else
        rec_m(t,3) = 0;
    end

    PsychPortAudio('Stop', pahandle);
    t0 = Screen('Flip', w);
    WaitSecs(intv);
end

% End of experiment
DrawFormattedText(w, 'End of the melody portion.\n\nPlease the space bar to continue.', 'center', 'center', 255);
Screen('Flip', w);
WaitSecs(4);

end


%% Pulse production part

if ~skip_p

% auditory practice
str = 'Welcome to the pulse portion of the test.';
str = [str '\nPulse(noun): the regular, basic unit of time in a piece of music. (i.e. "beat")'];
str = [str '\n\nYou will hear a 15 second sample of music.'];
str = [str '\nYour task is to press the SPACE BAR with the "pulse".'];
str = [str '\n\nLet''s listen to an example.'];
str = [str '\nIn this example, you will hear a "click" on every beat.'];
str = [str '\n\nPress the space bar to begin.'];

DrawFormattedText(w, str, 'center', 'center', 255, [], [], [], 1.1);
Screen('Flip', w);
RTBox('Clear');
RTBox(inf);

Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
Screen('Flip', w);
WaitSecs(1);

quitit=0;
while ~quitit
    % fill buffer 
    PsychPortAudio('FillBuffer', pahandle, audio_p_prac{1});
    PsychPortAudio('Start', pahandle);
    Screen('DrawTexture', w, speaker_tex);
    WaitSecs( outputLatency*.001 - p.ScreenIFI ); % to match the audio latency
    Screen('Flip', w);

    WaitSecs(length(audio_p_prac{1})/srate);
    PsychPortAudio('Stop', pahandle);

    % practice results
    str = 'Press the left arrow key to repeat the practice\nor press the space bar';
    DrawFormattedText(w, str, 'center', 'center', 255, [], [], [], 1.2);
    Screen('Flip', w);

    WaitSecs(0.5);
    RTBox('Clear');
    [~, cont] = RTBox(inf);
    if strcmp(cont, 'space')  % move onto main blocks
        DrawFormattedText(w, 'Please wait...', 'center', 'center', 255);
        t0=Screen('Flip', w);
        WaitTill(t0 + 2);
        quitit=1;
    else  % try a practice block again
        DrawFormattedText(w, 'Please wait...', 'center', 'center', 255);
        t0=Screen('Flip', w);
        Screen('Flip', w, t0+2);
    end
end

% visual practice
str = 'Now let''s do some practice.';
str = [str '\n\nPress the SPACE BAR with every pulse you hear.'];
str = [str '\nDon''t start pressing the space bar until you are sure you know where the pulse is!'];
str = [str '\nIt is okay to wait a few seconds until you are sure. '];
str = [str '\n\nFor this practice, the fixation cross will flash red on every pulse.'];
str = [str '\n\nPress the space bar to begin.'];

DrawFormattedText(w, str, 'center', 'center', 255, [], [], [], 1.1);
Screen('Flip', w);
RTBox('Clear');
RTBox(inf);

Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
Screen('Flip', w);
WaitSecs(2);

quitit=0;  intv=1;
while ~quitit
    Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
    Screen('Flip', w);
    WaitSecs(intv);

    % fill buffer
    PsychPortAudio('FillBuffer', pahandle, audio_p_prac{2});
    PsychPortAudio('Start', pahandle);
    
    Screen('DrawLines', w, 1.5*crossCoords, 4, [255 0 0], [cx, cy]);
    WaitSecs( outputLatency*.001 - p.ScreenIFI ); % to match the audio latency
    tstart = Screen('Flip', w);
    WaitSecs(.1);
    
    tnow = tstart;  t0 = tnow;
    dur_pulse = length(audio_p_prac{2})/srate; % rec=[];
    while tnow < tstart+dur_pulse
        tnow = GetSecs;
        if tnow>t0+.48
            Screen('DrawLines', w, 1.5*crossCoords, 4, [255 0 0], [cx, cy]);
            t0=Screen('Flip', w);
%             rec=[rec; t0];
            WaitSecs(.1);
        else
            Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
            Screen('Flip', w);
        end
    end
    PsychPortAudio('Stop', pahandle);

    % practice results
    str = 'Press the left arrow key to repeat the practice\nor press the space bar';
    DrawFormattedText(w, str, 'center', 'center', 255, [], [], [], 1.2);
    Screen('Flip', w);

    WaitSecs(0.5);
    RTBox('Clear');
    [~, cont] = RTBox(inf);
    if strcmp(cont, 'space')  % move onto main blocks
        DrawFormattedText(w, 'Please wait...', 'center', 'center', 255);
        t0=Screen('Flip', w);
        WaitTill(t0 + 2);
        quitit=1;
    else  % try a practice block again
        DrawFormattedText(w, 'Please wait...', 'center', 'center', 255);
        t0=Screen('Flip', w);
        Screen('Flip', w, t0+2);
    end
end

% Main experiment
str = 'Now the real test will begin.';
str = [str '\n\nEach trial will be 15 seconds long.'];
str = [str '\n\nRemember: wait until you know where the pulse is'];
str = [str '\nbefore starting to press the SPACE BAR.'];
str = [str '\n\nPress the space bar to begin.'];

DrawFormattedText(w, str, 'center', 'center', 255, [], [], [], 1.2);
Screen('Flip', w);
RTBox('Clear');
RTBox(inf);

% keyboard input
KbName('UnifyKeyNames');
keyS = KbName('space');

intv = 2;  % inter-trial interval
in = 0;

WaitSecs(intv);
for t=1:nstim_p
    % trial condition
    target = cond_p(t,2);

    DrawFormattedText(w, 'Be ready...', 'center', 'center', 255, [], [], [], 1.1);
    Screen('Flip', w);
    WaitSecs(intv);
    
    % fill buffer 
    dur_pulse = length(audio_pulse{t})/srate;
    PsychPortAudio('FillBuffer', pahandle, audio_pulse{t});
    
    DrawFormattedText(w, 'START!', 'center', 'center', 255, [], [], [], 1.1);
    Screen('Flip', w);  WaitSecs(1);
    Screen('Flip', w);  WaitSecs(.5);
    
    Screen('DrawLines', w, crossCoords, 2, 255, [cx, cy]);
    tapOn=0;  count=0;  
    PsychPortAudio('Start', pahandle);
    
    WaitSecs( outputLatency*.001 - p.ScreenIFI ); % to match the audio latency
    tstart = Screen('Flip', w);
	tnow = tstart; 
    while tnow < tstart+dur_pulse
        tnow = GetSecs;
        [~, Secs, kCod] = PsychHID('KbCheck');
        if kCod(keyS) && ~tapOn
            tapOn=1;  in=in+1;  count=count+1;
            rec_p(in,1:3) = [t count Secs-tstart];
        end
        
        if ~kCod(keyS) && tapOn
            tapOn=0;
            rec_p(in,4) = Secs-tstart;
        end
    end
    
    if tapOn % record the last tapping
        rec_p(in,4) = Secs-tstart;
    end
    
    PsychPortAudio('Stop', pahandle);
    DrawFormattedText(w, 'END', 'center', 'center', 255, [], [], [], 1.1);
    Screen('Flip', w);
    WaitSecs(intv);
    
    if t<nstim_p
        str = 'Press the space bar when you are ready.';
        DrawFormattedText(w, str, 'center', 'center', 255, [], [], [], 1.1);
        Screen('Flip', w);
        WaitTill('space');
    end
end

% get rid of the rest lines
rec_p(isnan(rec_p(:,1)),:)=[];

end


%% End of experiment

DrawFormattedText(w, 'End of the test.\nPlease call the experimenter', 'center', 'center', 255);
Screen('Flip', w);
WaitSecs(4);

sca
PsychPortAudio('Close');
ShowCursor; ListenChar();
save(filename, 'p','cond_r','cond_m','cond_p','rec_r','rec_m','rec_p');

%% Important functions
function out = num2digit(num,len)
% Duc Chung Tran (2020). num2digit.zip 
% https://www.mathworks.com/matlabcentral/fileexchange/46459-num2digit-zip,
% MATLAB Central File Exchange. Retrieved January 28, 2020. 
    if (len>0) && (num>=0)
        out = zeros(1,len);
        for i=len:-1:1
            out(1,len+1-i) = floor(num/(10^(i-1)));
            num = mod(num,10^(i-1));
        end
    else
        if (len<=0)
            out = -1;
            disp('Invalid output length, it should be >0 .');
        else
            out = -2;
            disp('Invalid input number, it should be >=0.');
        end
    end
end
