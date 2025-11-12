function photodiodeCheckerGUI(photodiode_data_dir)
%%
% Run GUI to check or modify extracted from times
close all
% Create the main figure for the GUI
if ismac
    fig = figure('Name', 'Photodiode Checker', ...
                 'NumberTitle', 'off', ...
                 'Units', 'normalized', ...
                 'Position', [.1 .05 .75 .6], ...
                 'ToolBar', 'figure');
else
    fig = figure('Name', 'Photodiode Checker', ...
                 'NumberTitle', 'off', ...
                 'Units', 'normalized', ...
                 'Position', [.1 .05 .5 .4], ...
                 'ToolBar', 'figure');
end


% Initialize gui
h = initialize_photodiodeChecker(fig);

% Set data directory BEFORE adding functionality
if nargin > 0
    h.dataDir = photodiode_data_dir;
else
    h.dataDir = pwd;
end

% add functionality (this will store h with guidata)
h = add_functionality(h);

% Store the figure handle for easy reference
h.fig = fig;

% Update guidata one more time to ensure everything is stored
guidata(fig, h);

end

function h = initialize_photodiodeChecker(fig)

% main signal display plot
h.signal = axes('Parent', fig, ...
                'Units', 'normalized', ...
                'Position', [.11 .25 .63 .6]);


% Session loading/saving
h.sessName = add_indicator(fig, [.12 .9 .175 .05], .4, 'Session');
h.sessLoad = add_button(fig, [.335 .9 .125 .05], 'Load Session', '');
h.sessSave = add_button(fig, [.465 .9 .125 .05], 'Save Session', '');

% trial control buttons & edit field
h.trialEdit = add_edit(fig, [.12 .1 .06 .05], 'Trial', 'Trial number');
h.trialPrev = add_button(fig, [.265 .1 .09 .05], 'Previous', 'Go to previous trial');
h.trialNext = add_button(fig, [.36 .1 .09 .05], 'Next', 'Go to next trial');

% Accept/Discard buttons
h.trialAccept  = add_button(fig, [.46 .1 .125 .05], 'Accept', 'Accept current trial', [0 0.5 0]);
h.trialDiscard = add_button(fig, [.59 .1 .125 .05], 'Discard', 'Discard current trial', [0.7 0 0]);
h.trialStatus  = add_indicator(fig, [.76 .1 .175 .05], .7, 'Trial status');


% Adjust start/end fields, and +/- buttons 
h.adjustStart = add_edit(fig, [.76 .8 .0975 .05], 'Start time', '');
h.minusStart  = add_button(fig, [.8625 .74 .048 .05], '-', 'Decrease start time by 1');
h.addStart    = add_button(fig, [.9125 .74 .048 .05], '+', 'Increase start time by 1');
h.adjustEnd   = add_edit(fig, [.76 .66 .0975 .05], 'End time', '');
h.minusEnd    = add_button(fig, [.8625 .6 .048 .05], '-', 'Decrease end time by 1');
h.addEnd      = add_button(fig, [.9125 .6 .048 .05], '+', 'Increase end time by 1');


% Display expected/detected number of frames
h.expectedFrames = add_indicator(fig, [.76 .5 .175 .05], .7, 'Expected # frames');
h.detectedFrames = add_indicator(fig, [.76 .44 .175 .05], .7, 'Detected # frames');

% Add peak detection button and parameters
h.peakDetect = add_button(fig, [.76 .35 .2 .05], 'Detect Peaks', ...
                          'Run findpeaks function in selected range');
h.peakThreshold = add_edit(fig, [.76 .29 .0975 .05], 'Parameters', ...
                           'Specify parameters to findpeaks function as comma separated values');

% Add auto-distribution button and functionality
h.autoDistribute = add_button(fig, [.76 .2 .2 .05], 'Auto Distribute', ...
                              'Automatically distribute frame times betweem start and end');

end

function h = add_functionality(h)
    % Store handles structure in figure
    guidata(h.sessName.Parent, h);
    
    % Update callbacks - using cleaner naming
    h.sessLoad.Callback = @(~,~) call_load_session();
    h.sessSave.Callback = @(~,~) call_save_session();
    
    h.trialEdit.Callback = @(~,~) call_load_trial();
    h.trialPrev.Callback = @(~,~) call_load_trial('previous');
    h.trialNext.Callback = @(~,~) call_load_trial('next');
    
    h.trialAccept.Callback  = @(~,~) call_label_trial('accept');
    h.trialDiscard.Callback = @(~,~) call_label_trial('reject');
    
    h.adjustStart.Callback = @(~,~) call_time_adjusted('start');
    h.adjustEnd.Callback = @(~,~) call_time_adjusted('end');
    
    h.addStart.Callback = @(~,~) call_time_adjusted('start', 1);
    h.minusStart.Callback = @(~,~) call_time_adjusted('start', -1);
    h.addEnd.Callback = @(~,~) call_time_adjusted('end', 1);
    h.minusEnd.Callback = @(~,~) call_time_adjusted('end', -1);
    
    h.peakDetect.Callback = @(~,~) call_peak_detection();
    h.autoDistribute.Callback = @(~,~) call_auto_distribute();
end


function widget = add_button(fig, pos, text, tooltip, bg_col)

if nargin==4
    bg_col = [.6 .6 .8];
end

widget = uicontrol( ...
    'Parent', fig, ...
    'Units', 'normalized', ...
    'Style', 'pushbutton', ...
    'Position', pos, ...
    'String', text, ...
    'BackgroundColor', bg_col, ...
    'Tooltip', tooltip);

end

function widget = add_edit(fig, pos, text, tooltip)
    uicontrol( ...
        'Parent', fig, ...
        'Units', 'normalized', ...
        'Style', 'edit', ...
        'Enable', 'inactive', ...
        'Position', pos, ...
        'String', text, ...
        'FontSize', 10, ...
        'BackgroundColor', [.6 .6 .6]);
    
    edit_pos = [pos(1) + pos(3) + 0.005, pos(2), pos(3), pos(4)];
    widget = uicontrol( ...
        'Parent', fig, ...
        'Units', 'normalized', ...
        'Style', 'edit', ...
        'Position', edit_pos, ...
        'Tooltip', tooltip, ...
        'FontSize', 10);
end


function widget = add_slider(fig, pos)

widget = uicontrol( ...
    'Parent', fig, ...
    'Style',  'slider', ...
    'Units', 'Normalized', ...
    'Position', pos, ...
    'BackgroundColor', [.6 .6 .8]);

end


% create widgets used to display information only
function widget = add_indicator(fig, pos, ratio, txt)
    label_pos = [pos(1), pos(2), pos(3) * ratio, pos(4)];
    uicontrol( ...
        'Parent', fig, ...
        'Units', 'normalized', ...
        'Style', 'edit', ...
        'Enable', 'inactive', ...
        'Position', label_pos, ...
        'String', txt, ...
        'FontSize', 10, ...
        'BackgroundColor', [0.9, 0.9, 0.9]);

    edit_pos = [pos(1) + label_pos(3) + 0.005, pos(2), ...
        pos(3) * (1 - ratio) + 0.02, pos(4)];
    widget = uicontrol( ...
        'Parent', fig, ...
        'Units', 'normalized', ...
        'Enable', 'inactive', ...
        'Style', 'edit', ...
        'Position', edit_pos, ...
        'FontSize', 10, ...
        'BackgroundColor', [0.9, 0.9, 0.9]);
end

%% Core photodiode checker functions (no 'call_' prefix)
function h = load_session(h)
    % Load session data from file
    if isfield(h, 'dataDir')
        startPath = h.dataDir;
    else
        startPath = pwd;
    end
    
    [filename, pathname] = uigetfile({'*.mat', 'MAT files'; '*.*', 'All files'}, ...
                                     'Select photodiode data file', startPath);
    
    if isequal(filename, 0)
        return;  % User cancelled
    end
    
    fullpath = fullfile(pathname, filename);
    
    try
        % Load the data
        data = load(fullpath);
        
        % Store session data
        h.frame_times = data.frame_times;
        h.photodiode_signal = data.photodiode_signal;
        h.NI_sample_rate = data.NI_sample_rate;
        h.trialStartTimes = data.trialStartTimes;  % Actual trial onset times in seconds
        
        % Initialize trial management
        h.nTrials = length(h.photodiode_signal);
        h.currentTrial = 1;
        
        % Initialize trial status tracking (all pending by default)
        if ~isfield(h.frame_times, 'status')
            h.frame_times.status = repmat({'pending'}, 1, h.nTrials);
        end
        
        % Store original frame times for reference
        h.frame_times.original = h.frame_times.time;
        
        % Calculate expected frames and trial durations
        h.expectedFramesData = zeros(1, h.nTrials);
        h.trialDurations = zeros(1, h.nTrials);
        
        for tr = 1:h.nTrials
            % Each signal contains from -2s to (trial_end + 1s)
            % So total signal length = 2s (pre) + trial_duration + 1s (post)
            % Therefore: trial_duration = signal_length/sample_rate - 3
            total_signal_duration = length(h.photodiode_signal{tr}) / h.NI_sample_rate;
            trial_duration = total_signal_duration - 3;  % Remove the 2s pre and 1s post
            h.trialDurations(tr) = trial_duration;
            h.expectedFramesData(tr) = round(60 * trial_duration);  % 60Hz refresh rate
        end
        
        % Initialize analysis windows (in seconds relative to trial onset)
        h.analysisWindow = zeros(h.nTrials, 2);
        for tr = 1:h.nTrials
            h.analysisWindow(tr, 1) = 0;  % Start at trial onset
            h.analysisWindow(tr, 2) = h.trialDurations(tr);  % End at trial end
        end
        
        % Update session name display
        [~, name, ~] = fileparts(filename);
        h.sessName.String = name;
        h.sessionPath = fullpath;
        
        % Initialize peak detection parameters field
        h.peakThreshold.String = '''MinPeakProminence'', 1, ''MinPeakDistance'', 0.02';
        
        % Update display
        update_display(h);
        
    catch ME
        errordlg(['Error loading file: ' ME.message], 'Load Error');
    end
end


function h = save_session(h)
    % Save current session data with modified frame times
    if ~isfield(h, 'frame_times')
        errordlg('No session loaded', 'Save Error');
        return;
    end
    
    % Get save location
    defaultName = [h.sessName.String '_checked.mat'];
    [filename, pathname] = uiputfile('*.mat', 'Save processed data', ...
                                     fullfile(h.dataDir, defaultName));
    
    if isequal(filename, 0)
        return;  % User cancelled
    end
    
    % Prepare data for saving
    frame_times = h.frame_times;
    photodiode_signal = h.photodiode_signal;
    NI_sample_rate = h.NI_sample_rate;
    trialStartTimes = h.trialStartTimes;
    
    % Add summary information
    summary.totalTrials = h.nTrials;
    summary.accepted = sum(strcmp(h.frame_times.status, 'accepted'));
    summary.rejected = sum(strcmp(h.frame_times.status, 'rejected'));
    summary.pending = sum(strcmp(h.frame_times.status, 'pending'));
    summary.processedDate = datestr(now);
    summary.analysisWindows = h.analysisWindow;
    
    % Save
    try
        save(fullfile(pathname, filename), 'frame_times', 'photodiode_signal', ...
             'NI_sample_rate', 'trialStartTimes', 'summary');
        msgbox(sprintf('Session saved successfully.\nAccepted: %d\nRejected: %d\nPending: %d', ...
               summary.accepted, summary.rejected, summary.pending), ...
               'Save Complete');
    catch ME
        errordlg(['Error saving file: ' ME.message], 'Save Error');
    end
end

function h = load_trial(h, varargin)
    % Navigate between trials
    if ~isfield(h, 'photodiode_signal') || isempty(h.photodiode_signal)
        return;
    end
    
    % Handle navigation
    if nargin > 1
        switch varargin{1}
            case 'previous'
                h.currentTrial = max(1, h.currentTrial - 1);
            case 'next'
                h.currentTrial = min(h.nTrials, h.currentTrial + 1);
        end
    else
        % Load from edit field
        requestedTrial = str2double(h.trialEdit.String);
        if ~isnan(requestedTrial) && requestedTrial >= 1 && requestedTrial <= h.nTrials
            h.currentTrial = round(requestedTrial);
        end
    end
    
    % Update display
    update_display(h);
end

function h = label_trial(h, status)
    % Label trial as accepted or rejected
    if ~isfield(h, 'frame_times')
        return;
    end
    
    switch status
        case 'accept'
            h.frame_times.status{h.currentTrial} = 'accepted';
        case 'reject'
            h.frame_times.status{h.currentTrial} = 'rejected';
    end
    
    % Update display
    update_display(h);
    
    % Optionally auto-advance to next trial
    if h.currentTrial < h.nTrials
        pause(0.2);  % Brief pause to see the status change
        h = load_trial(h, 'next');
    end
end

function h = time_adjusted(h, when, increment)
    % Adjust the analysis window for frame detection
    if ~isfield(h, 'photodiode_signal')
        return;
    end
    
    tr = h.currentTrial;
    
    % Maximum time is trial duration + 1s post-trial
    max_time = h.trialDurations(tr) + 1;
    
    if nargin < 3
        % Manual entry from edit field
        switch when
            case 'start'
                newValue = str2double(h.adjustStart.String);
                if ~isnan(newValue) && newValue >= -2 && newValue < h.analysisWindow(tr, 2)
                    h.analysisWindow(tr, 1) = newValue;
                end
            case 'end'
                newValue = str2double(h.adjustEnd.String);
                if ~isnan(newValue) && newValue > h.analysisWindow(tr, 1) && newValue <= max_time
                    h.analysisWindow(tr, 2) = newValue;
                end
        end
    else
        % Increment/decrement by 10ms
        increment_time = increment * 0.01;
        switch when
            case 'start'
                newValue = h.analysisWindow(tr, 1) + increment_time;
                if newValue >= -2 && newValue < h.analysisWindow(tr, 2)
                    h.analysisWindow(tr, 1) = newValue;
                end
            case 'end'
                newValue = h.analysisWindow(tr, 2) + increment_time;
                if newValue > h.analysisWindow(tr, 1) && newValue <= max_time
                    h.analysisWindow(tr, 2) = newValue;
                end
        end
    end
    
    % Update display
    update_display(h);
end

function h = peak_detection(h)
    % Detect peaks/frames in current trial
    if ~isfield(h, 'photodiode_signal')
        return;
    end
    
    tr = h.currentTrial;
    trial_signal = h.photodiode_signal{tr};
    
    % Get analysis window in samples
    start_idx = round((h.analysisWindow(tr, 1) + 2) * h.NI_sample_rate);
    end_idx = round((h.analysisWindow(tr, 2) + 2) * h.NI_sample_rate);
    start_idx = max(1, start_idx);
    end_idx = min(length(trial_signal), end_idx);
    
    % Extract baseline and stimulus statistics
    iti_signal = trial_signal(1:round(1.5*h.NI_sample_rate));
    stim_signal = trial_signal(start_idx:end_idx);
    
    if isempty(stim_signal)
        warndlg('Analysis window is empty!');
        return;
    end
    
    stim_mean = mean(stim_signal);
    stim_std = std(stim_signal);
    
    % Time vector for stimulus period
    t = (start_idx:end_idx) / h.NI_sample_rate - 2;
    
    % Parse parameters and detect peaks
    up_state_times = [];
    down_state_times = [];
    
    try
        paramStr = strtrim(h.peakThreshold.String);
        if ~isempty(paramStr)
            eval_str = sprintf('{%s}', paramStr);
            peakArgs = eval(eval_str);
        else
            peakArgs = {'MinPeakProminence', stim_std, 'MinPeakDistance', 0.02};
        end
        
        [~, up_state_times] = findpeaks(stim_signal - stim_mean, t, peakArgs{:});
        [~, down_state_times] = findpeaks(stim_mean - stim_signal, t, peakArgs{:});
        
    catch ME
        warndlg(['Peak detection failed: ' ME.message]);
        return;
    end
    
    % Combine and sort frame times
    frame_times_relative = sort([up_state_times, down_state_times]);
    
    % Convert from offset to onset times
    if length(frame_times_relative) > 1
        IFI = median(diff(frame_times_relative));
        frame_times_relative = [frame_times_relative(1)-IFI, frame_times_relative(1:end-1)];
    end
    
    % Convert to absolute session time
    h.frame_times.time{tr} = frame_times_relative + h.trialStartTimes(tr);
    
    % Update display
    update_display(h);
    
    fprintf('Detected %d frames in trial %d (expected: %d)\n', ...
            length(h.frame_times.time{tr}), tr, h.expectedFramesData(tr));
end

function h = auto_distribute(h)
    % Automatically distribute frame times evenly at 60Hz
    if ~isfield(h, 'photodiode_signal')
        return;
    end
    
    tr = h.currentTrial;
    
    % Get analysis window
    start_time = h.analysisWindow(tr, 1);
    end_time = h.analysisWindow(tr, 2);
    
    % Calculate number of frames based on 60Hz within the window
    window_duration = end_time - start_time;
    nFrames = round(60 * window_duration);  % 60Hz refresh rate
    
    if nFrames <= 0
        warndlg('Window duration too small for frames!');
        return;
    end
    
    % Generate frame times at 60Hz (every 1/60 seconds)
    frame_times_relative = start_time + (0:(nFrames-1)) / 60;
    
    % Only keep frames that fit within the window
    frame_times_relative = frame_times_relative(frame_times_relative <= end_time);
    
    % Convert to absolute session time
    h.frame_times.time{tr} = frame_times_relative + h.trialStartTimes(tr);
    
    % Update display
    update_display(h);
    
    msgbox(sprintf('Distributed %d frames at 60Hz between %.3fs and %.3fs', ...
                   length(frame_times_relative), start_time, end_time), ...
           'Auto Distribution Complete');
end

function update_display(h)
    % Central function to update all GUI elements and plot
    if ~isfield(h, 'photodiode_signal') || isempty(h.photodiode_signal)
        return;
    end
    
    tr = h.currentTrial;
    trial_signal = h.photodiode_signal{tr};
    
    % Update trial number field
    h.trialEdit.String = num2str(tr);
    
    % Create time vector
    t = (-2*h.NI_sample_rate:(length(trial_signal)-2*h.NI_sample_rate-1)) / h.NI_sample_rate;
    
    % Plot photodiode signal
    axes(h.signal);
    cla;
    plot(t, trial_signal, 'b-', 'LineWidth', 1);
    hold on;
    
    % Mark trial start and analysis window
    yl = ylim;
    plot([0 0], yl, 'g--', 'LineWidth', 2);
    
    % Mark trial end
    trial_end_time = h.trialDurations(tr);
    plot([trial_end_time trial_end_time], yl, 'm--', 'LineWidth', 2);
    
    start_time = h.analysisWindow(tr, 1);
    end_time = h.analysisWindow(tr, 2);
    patch([start_time end_time end_time start_time], ...
          [yl(1) yl(1) yl(2) yl(2)], ...
          'yellow', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
    plot([start_time start_time], yl, 'r:', 'LineWidth', 1.5);
    plot([end_time end_time], yl, 'r:', 'LineWidth', 1.5);
    
    % Plot detected frame times
    nFramesInWindow = 0;
    if ~isempty(h.frame_times.time{tr})
        frame_times_relative = h.frame_times.time{tr} - h.trialStartTimes(tr);
        frames_in_window = frame_times_relative >= start_time & frame_times_relative <= end_time;
        nFramesInWindow = sum(frames_in_window);
        
        % Plot ALL frames within the visible window (not just -2 to 1)
        max_view_time = h.trialDurations(tr) + 1;  % Show trial + 1s post
        valid_frames = frame_times_relative >= -2 & frame_times_relative <= max_view_time;
        frame_times_to_plot = frame_times_relative(valid_frames);
        
        if ~isempty(frame_times_to_plot)
            frame_indices = round((frame_times_to_plot + 2) * h.NI_sample_rate);
            frame_indices = frame_indices(frame_indices > 0 & frame_indices <= length(trial_signal));
            if ~isempty(frame_indices)
                plot(t(frame_indices), trial_signal(frame_indices), 'ro', ...
                     'MarkerSize', 5, 'MarkerFaceColor', 'r');
            end
        end
    end
    
    % Update plot labels
    xlabel('Time (s) [relative to trial onset]');
    ylabel('Photodiode Signal');
    title(sprintf('Trial %d of %d | Duration: %.2fs | Session time: %.2fs', ...
                  tr, h.nTrials, h.trialDurations(tr), h.trialStartTimes(tr)));
    grid on;
    
    % Set x-axis limits to show full trial + 1s post (or at least -2 to 1)
    max_view_time = max(1, h.trialDurations(tr) + 1);
    xlim([-2 max_view_time]);
    
    % Update legend
    legend({'Signal', 'Trial onset', 'Trial end', 'Analysis window', 'Detected frames'}, ...
           'Location', 'northwest', 'FontSize', 6);
    
    % Update status indicator
    h.trialStatus.String = h.frame_times.status{tr};
    switch h.frame_times.status{tr}
        case 'accepted'
            h.trialStatus.BackgroundColor = [0.7 1 0.7];
        case 'rejected'
            h.trialStatus.BackgroundColor = [1 0.7 0.7];
        otherwise
            h.trialStatus.BackgroundColor = [0.9 0.9 0.9];
    end
    
    % Update time fields
    h.adjustStart.String = sprintf('%.3f', start_time);
    h.adjustEnd.String = sprintf('%.3f', end_time);
    
    % Update frame counts
    h.expectedFrames.String = num2str(h.expectedFramesData(tr));
    h.detectedFrames.String = num2str(nFramesInWindow);
end

%% Callback wrapper functions (these get called by the GUI)
function call_load_session()
    h = guidata(gcf);
    h = load_session(h);
    guidata(gcf, h);
end

function call_save_session()
    h = guidata(gcf);
    h = save_session(h);
    guidata(gcf, h);
end

function call_load_trial(varargin)
    h = guidata(gcf);
    h = load_trial(h, varargin{:});
    guidata(gcf, h);
end

function call_label_trial(status)
    h = guidata(gcf);
    h = label_trial(h, status);
    guidata(gcf, h);
end

function call_time_adjusted(when, increment)
    h = guidata(gcf);
    if nargin < 2
        h = time_adjusted(h, when);
    else
        h = time_adjusted(h, when, increment);
    end
    guidata(gcf, h);
end

function call_peak_detection()
    h = guidata(gcf);
    h = peak_detection(h);
    guidata(gcf, h);
end

function call_auto_distribute()
    h = guidata(gcf);
    h = auto_distribute(h);
    guidata(gcf, h);
end