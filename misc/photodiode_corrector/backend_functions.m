%% Photodiode checker functions
%% Photodiode checker functions
function call_load_session(h)
    % Load session data from file
    [filename, pathname] = uigetfile({'*.mat', 'MAT files'; '*.*', 'All files'}, ...
                                     'Select photodiode data file', h.dataDir);
    
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
        
        % Initialize trial management
        h.nTrials = length(h.photodiode_signal);
        h.currentTrial = 1;
        
        % Initialize trial status tracking (all pending by default)
        if ~isfield(h.frame_times, 'status')
            h.frame_times.status = repmat({'pending'}, 1, h.nTrials);
        end
        
        % Store original frame times for reference
        h.frame_times.original = h.frame_times.time;
        
        % Calculate expected frames for each trial (60Hz refresh)
        h.expectedFrames = zeros(1, h.nTrials);
        for tr = 1:h.nTrials
            % Trial duration in seconds (excluding the 2s pre-trial period)
            trial_duration = (length(h.photodiode_signal{tr}) - 2*h.NI_sample_rate) / h.NI_sample_rate;
            h.expectedFrames(tr) = round(60 * trial_duration);  % 60Hz refresh rate
        end
        
        % Update session name display
        [~, name, ~] = fileparts(filename);
        h.sessName.String = name;
        h.sessionPath = fullpath;
        
        % Load first trial
        call_load_trial(h);
        
    catch ME
        errordlg(['Error loading file: ' ME.message], 'Load Error');
    end
end

function call_save_session(h)
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
    
    % Add summary information
    summary.totalTrials = h.nTrials;
    summary.accepted = sum(strcmp(h.frame_times.status, 'accepted'));
    summary.rejected = sum(strcmp(h.frame_times.status, 'rejected'));
    summary.pending = sum(strcmp(h.frame_times.status, 'pending'));
    summary.processedDate = datestr(now);
    
    % Save
    try
        save(fullfile(pathname, filename), 'frame_times', 'photodiode_signal', ...
             'NI_sample_rate', 'summary');
        msgbox(sprintf('Session saved successfully.\nAccepted: %d\nRejected: %d\nPending: %d', ...
               summary.accepted, summary.rejected, summary.pending), ...
               'Save Complete');
    catch ME
        errordlg(['Error saving file: ' ME.message], 'Save Error');
    end
end

function call_load_trial(h, varargin)
    % Load and display trial data
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
    
    % Update trial number display
    h.trialEdit.String = num2str(h.currentTrial);
    
    % Get current trial data
    tr = h.currentTrial;
    trial_signal = h.photodiode_signal{tr};
    
    % Create time vector (starting at -2s)
    t = (-2*h.NI_sample_rate:(length(trial_signal)-2*h.NI_sample_rate-1)) / h.NI_sample_rate;
    
    % Plot photodiode signal
    axes(h.signal);
    cla;
    plot(t, trial_signal, 'b-');
    hold on;
    
    % Mark trial start (at t=0)
    plot([0 0], ylim, 'g--', 'LineWidth', 2);
    
    % Plot detected frame times if they exist
    if ~isempty(h.frame_times.time{tr})
        frame_times = h.frame_times.time{tr};
        % Convert to indices in the trial signal
        frame_indices = round((frame_times + 2) * h.NI_sample_rate);  % +2 because signal starts at -2s
        
        % Make sure indices are within bounds
        frame_indices = frame_indices(frame_indices > 0 & frame_indices <= length(trial_signal));
        
        % Plot frame markers
        if ~isempty(frame_indices)
            plot(t(frame_indices), trial_signal(frame_indices), 'ro', ...
                 'MarkerSize', 6, 'MarkerFaceColor', 'r');
        end
    end
    
    xlabel('Time (s) [relative to trial start]');
    ylabel('Photodiode Signal');
    title(sprintf('Trial %d of %d', h.currentTrial, h.nTrials));
    grid on;
    
    % Highlight stimulus period (from 0 to end-1s, since signal goes from -2 to +1)
    trial_end_time = (length(trial_signal) - 3*h.NI_sample_rate) / h.NI_sample_rate;
    patch([0 trial_end_time trial_end_time 0], ...
          [min(ylim) min(ylim) max(ylim) max(ylim)], ...
          'yellow', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
    
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
    
    % Update time fields (in samples from start of recording)
    trial_start_sample = 2 * h.NI_sample_rate;  % Trial starts at t=0, which is 2s into the recording
    trial_end_sample = length(trial_signal) - h.NI_sample_rate;  % 1s before end of recording
    
    h.adjustStart.String = num2str(trial_start_sample);
    h.adjustEnd.String = num2str(trial_end_sample);
    
    % Update frame counts
    h.expectedFrames.String = num2str(h.expectedFrames(tr));
    
    if ~isempty(h.frame_times.time{tr})
        h.detectedFrames.String = num2str(length(h.frame_times.time{tr}));
    else
        h.detectedFrames.String = '0';
    end
end

function call_label_trial(h, status)
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
    call_load_trial(h);
    
    % Optionally auto-advance to next trial
    if h.currentTrial < h.nTrials
        pause(0.2);  % Brief pause to see the status change
        call_load_trial(h, 'next');
    end
end

function call_time_adjusted(h, when, increment)
    % Adjust the analysis window for frame detection
    % This doesn't change the raw data, but changes where we look for frames
    
    if ~isfield(h, 'photodiode_signal')
        return;
    end
    
    tr = h.currentTrial;
    
    % Get current window boundaries (in samples)
    if ~isfield(h, 'analysisWindow')
        h.analysisWindow = zeros(h.nTrials, 2);
        for i = 1:h.nTrials
            h.analysisWindow(i, :) = [2*h.NI_sample_rate, ...  % Start at t=0
                                      length(h.photodiode_signal{i})-h.NI_sample_rate];  % End at t=end-1s
        end
    end
    
    if nargin < 3
        % Manual entry from edit field
        switch when
            case 'start'
                newValue = str2double(h.adjustStart.String);
                if ~isnan(newValue) && newValue >= 1 && newValue < h.analysisWindow(tr, 2)
                    h.analysisWindow(tr, 1) = round(newValue);
                end
            case 'end'
                newValue = str2double(h.adjustEnd.String);
                if ~isnan(newValue) && newValue > h.analysisWindow(tr, 1) && ...
                   newValue <= length(h.photodiode_signal{tr})
                    h.analysisWindow(tr, 2) = round(newValue);
                end
        end
    else
        % Increment/decrement by samples
        increment_samples = increment * round(0.01 * h.NI_sample_rate);  % 10ms steps
        switch when
            case 'start'
                newValue = h.analysisWindow(tr, 1) + increment_samples;
                if newValue >= 1 && newValue < h.analysisWindow(tr, 2)
                    h.analysisWindow(tr, 1) = newValue;
                end
            case 'end'
                newValue = h.analysisWindow(tr, 2) + increment_samples;
                if newValue > h.analysisWindow(tr, 1) && newValue <= length(h.photodiode_signal{tr})
                    h.analysisWindow(tr, 2) = newValue;
                end
        end
    end
    
    % Update display
    call_load_trial(h);
end

function call_peak_detection(h)
    % Detect peaks/frames in current trial using approach similar to extract_frame_times_from_photodiode
    
    if ~isfield(h, 'photodiode_signal')
        return;
    end
    
    tr = h.currentTrial;
    trial_signal = h.photodiode_signal{tr};
    
    % Get analysis window
    if ~isfield(h, 'analysisWindow')
        start_idx = 2 * h.NI_sample_rate;  % Start at t=0
        end_idx = length(trial_signal) - h.NI_sample_rate;  % End at t=end-1s
    else
        start_idx = h.analysisWindow(tr, 1);
        end_idx = h.analysisWindow(tr, 2);
    end
    
    % Extract ITI (baseline) statistics from pre-trial period
    iti_signal = trial_signal(1:round(1.5*h.NI_sample_rate));
    iti_mean = mean(iti_signal);
    iti_std = std(iti_signal);
    
    % Extract stimulus period signal
    stim_signal = trial_signal(start_idx:end_idx);
    stim_mean = mean(stim_signal);
    stim_std = std(stim_signal);
    
    % Parse parameters from edit field (if provided)
    paramStr = h.peakThreshold.String;
    if ~isempty(paramStr)
        params = str2double(strsplit(paramStr, ','));
        if length(params) >= 1 && ~isnan(params(1))
            minProminence = params(1) * stim_std;
        else
            minProminence = stim_std;
        end
        if length(params) >= 2 && ~isnan(params(2))
            minDistance = params(2);
        else
            minDistance = 0.02;  % 20ms minimum between peaks
        end
    else
        minProminence = stim_std;
        minDistance = 0.02;
    end
    
    % Time vector for stimulus period
    t = (start_idx:end_idx) / h.NI_sample_rate - 2;  % -2 to convert to trial-relative time
    
    % Detect both up and down transitions (as in original function)
    up_state_times = [];
    down_state_times = [];
    
    try
        % Detect upward transitions
        [~, up_state_times] = findpeaks(stim_signal - stim_mean, t, ...
                                       'MinPeakProminence', minProminence, ...
                                       'MinPeakDistance', minDistance);
        
        % Detect downward transitions
        [~, down_state_times] = findpeaks(stim_mean - stim_signal, t, ...
                                         'MinPeakProminence', minProminence, ...
                                         'MinPeakDistance', minDistance);
    catch ME
        warndlg(['Peak detection failed: ' ME.message]);
        return;
    end
    
    % Combine and sort all frame times
    frame_times = sort([up_state_times, down_state_times]);
    
    % Convert from offset to onset times (shift by one frame interval)
    if length(frame_times) > 1
        IFI = median(diff(frame_times));
        frame_times = [frame_times(1)-IFI, frame_times(1:end-1)];
    end
    
    % Store the detected frame times
    h.frame_times.time{tr} = frame_times;
    
    % Update display
    call_load_trial(h);
    
    fprintf('Detected %d frames in trial %d (expected: %d)\n', ...
            length(frame_times), tr, h.expectedFrames(tr));
end

function call_auto_distribute(h)
    % Automatically distribute frame times evenly across the trial
    
    if ~isfield(h, 'photodiode_signal')
        return;
    end
    
    tr = h.currentTrial;
    
    % Get analysis window
    if ~isfield(h, 'analysisWindow')
        start_time = 0;  % Trial starts at t=0
        end_time = (length(h.photodiode_signal{tr}) - 3*h.NI_sample_rate) / h.NI_sample_rate;
    else
        start_time = (h.analysisWindow(tr, 1) - 2*h.NI_sample_rate) / h.NI_sample_rate;
        end_time = (h.analysisWindow(tr, 2) - 2*h.NI_sample_rate) / h.NI_sample_rate;
    end
    
    % Get expected number of frames
    nFrames = h.expectedFrames(tr);
    
    % Generate evenly spaced frame times
    frame_times = linspace(start_time, end_time, nFrames);
    
    % Store the frame times
    h.frame_times.time{tr} = frame_times;
    
    % Update display
    call_load_trial(h);
    
    msgbox(sprintf('Distributed %d frames evenly between %.3fs and %.3fs', ...
                   nFrames, start_time, end_time), ...
           'Auto Distribution Complete');
end