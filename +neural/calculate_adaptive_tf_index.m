function calculate_adaptive_tf_index(sessions, sp_all, ops)
% CALCULATE_ADAPTIVE_TF_INDEX - Calculate TF preference with adaptive windows
%
% Finds initial peak response, then expands symmetrically around it until
% index no longer improves or limits are reached.
%
% Steps:
% 1) Find peak in [50, 350]ms window; use 50ms initial window centered on peak
% 2) Expand window symmetrically in 50ms increments (25ms each side)
% 3) Respect limits: window start ≥ 50ms, window end ≤ 350ms
% 4) Stop when index no longer improves
% 5) Calculate final index with optimal window
% 
% Note: to speed this function up, this is only calculated for units in some region of interest.
% 
% --------------------------------------------------------------------------------------------------

fprintf('Calculating adaptive TF preference indexes\n');

% Define parameter bounds
min_time = 25;    % ms - minimum start time
max_time = 400;   % ms - maximum end time
init_window = 50; % ms - initial window width
expand_step = 50; % ms - amount to expand window (25ms each side)
max_width = 250;  % ms - maximum window width

rois = utils.all_rois;

for s = 1:length(sessions)
    animal = sessions(s).animal;
    session = sessions(s).session;
    
    fprintf('Session %d/%d: %s_%s\n', s, length(sessions), animal, session);
    
    % Skip non-recording sessions
    if strcmp(session(1), 'h')
        continue;
    end
    
    % Get unit info
    sp = sp_all{s};
    cids = sp.cids;
    locs = sp.clu_locs';
    
    in_roi = utils.get_units_in_area(locs, rois);
    
      
    % Load PSTHs
    psth_file = fullfile(ops.eventPSTHdir, sprintf('%s_%s.mat', animal, session));
    tf_tax = loadVariable(psth_file, 'tf_tax');
    [FRmu, FRsd] = loadVariables(psth_file, 'fr_mu', 'fr_sd');
    
    bad = FRmu<.1 | FRsd<.1;
    in_roi(bad)=0;
    nN = sum(in_roi);

    rel_win = isbetween(tf_tax, [min(ops.respWin.tfContext), max(ops.respWin.tf)]);
    
    % Load PSTHs and trim to relevant window
    psth_FexpF = loadVariable(psth_file, 'psth_FexpF');
    psth_FexpS = loadVariable(psth_file, 'psth_FexpS');
    psth_SexpF = loadVariable(psth_file, 'psth_SexpF');
    psth_SexpS = loadVariable(psth_file, 'psth_SexpS'); 
    
    psth_FexpF = psth_FexpF(in_roi,:,rel_win);
    psth_FexpS = psth_FexpS(in_roi,:,rel_win);
    psth_SexpF = psth_SexpF(in_roi,:,rel_win);
    psth_SexpS = psth_SexpS(in_roi,:,rel_win);
    tf_tax = tf_tax(rel_win);
    
    % Combine for F and S conditions with balanced trials
    psth_F = balance_trials(psth_FexpF, psth_FexpS);
    psth_S = balance_trials(psth_SexpF, psth_SexpS);
    
    % Prepare arrays for results
    windows = zeros(nN, 2);
    idx_adaptive = zeros(nN, 1);
    idx_adaptive_p = ones(nN, 1);
    idx_expF_adaptive = zeros(nN, 1);
    idx_expF_adaptive_p = ones(nN, 1);
    idx_expS_adaptive = zeros(nN, 1);
    idx_expS_adaptive_p = ones(nN, 1);
    
    % Process each neuron and each condition
    parfor n = 1:nN 
        
        % Find optimal window for combined condition
        windows(n,:) = find_centered_window(...
            psth_F(n,:,:), psth_S(n,:,:), tf_tax, min_time, max_time, ...
            init_window, expand_step, max_width);
        
        % full trial
        [idx_adaptive(n), idx_adaptive_p(n)] = ...
            calculate_preference_from_window(windows(n,:), psth_S(n,:,:), psth_F(n,:,:), tf_tax, ops.nIter);
        
        % expF
        [idx_expF_adaptive(n), idx_expF_adaptive_p(n)] = ...
            calculate_preference_from_window(windows(n,:), psth_SexpF(n,:,:), psth_FexpF(n,:,:), tf_tax, ops.nIter);
        
        % expS
        [idx_expS_adaptive(n), idx_expS_adaptive_p(n)] = ...
            calculate_preference_from_window(windows(n,:), psth_SexpS(n,:,:), psth_FexpS(n,:,:), tf_tax, ops.nIter);
         
    end
    
    % Append results to existing index file
    ind_save_file = fullfile(ops.indexesDir, sprintf('%s_%s.mat', animal, session));
    
    % Load existing indexes
    load(ind_save_file, 'indexes');
    
    % Append new adaptive indexes
    indexes.tf_adaptive(in_roi) = idx_adaptive;
    indexes.tf_adaptive_p(in_roi) = idx_adaptive_p;
    indexes.tfExpF_adaptive(in_roi) = idx_expF_adaptive;
    indexes.tfExpF_adaptive_p(in_roi) = idx_expF_adaptive_p;
    indexes.tfExpS_adaptive(in_roi) = idx_expS_adaptive;
    indexes.tfExpS_adaptive_p(in_roi) = idx_expS_adaptive_p;
    indexes.adaptive_windows(in_roi,:) = windows;
    
    indexes.tf_adaptive(~in_roi) = 0;
    indexes.tf_adaptive_p(~in_roi) = 1;
    indexes.tfExpF_adaptive(~in_roi) = 0;
    indexes.tfExpF_adaptive_p(~in_roi) = 1;
    indexes.tfExpS_adaptive(~in_roi) = 0;
    indexes.tfExpS_adaptive_p(~in_roi) = 1;
    indexes.adaptive_windows(~in_roi,:) = nan;
    
    % Save updated file
    save(ind_save_file, 'indexes');
    
    % Clear large variables
    clear psth_F psth_S psth_FexpF psth_SexpF psth_FexpS psth_SexpS indexes;
end

fprintf('Done!\n');
end

function combined = balance_trials(psth1, psth2)
% Balance trial counts between two PSTHs
if size(psth1,2) > size(psth2,2)
    longer = size(psth1,2);
    shorter = size(psth2,2);
    combined = cat(2, psth1(:,randperm(longer,shorter),:), psth2);
else
    longer = size(psth2,2);
    shorter = size(psth1,2);
    combined = cat(2, psth1, psth2(:,randperm(longer,shorter),:));
end
combined = cat(2, psth1, psth2);
end

function best_window = find_centered_window(fast_psth, slow_psth, tf_tax, min_time, max_time, init_window, expand_step, max_width)
% Find window that maximizes preference index, centered on peak response

% Check for valid data
if all(isnan(fast_psth(:))) || all(isnan(slow_psth(:)))
    best_window = [NaN, NaN];
    best_idx = NaN;
    best_p = NaN;
    return;
end

% Find valid time range for peak detection
valid_range = find(tf_tax >= min_time/1000 & tf_tax <= max_time/1000);
if isempty(valid_range)
    best_window = [NaN, NaN];
    best_idx = NaN;
    best_p = NaN;
    return;
end

% Calculate mean responses
fast_mean = squeeze(nanmean(fast_psth(:,:,valid_range), 2));
slow_mean = squeeze(nanmean(slow_psth(:,:,valid_range), 2));

% Smooth for better peak detection
fast_smooth = smoothdata(fast_mean, 'movmean', 5);
slow_smooth = smoothdata(slow_mean, 'movmean', 5);

% Find first peak in absolute difference
diff_resp = abs(fast_smooth - slow_smooth);
% Use findpeaks to identify the first peak
[~, locs] = findpeaks(diff_resp);
if ~isempty(locs)
    peak_idx = locs(1); % Take first peak
else
    % If no peaks found, use maximum value
    [~, peak_idx] = max(diff_resp);
end
peak_idx = valid_range(peak_idx); % Convert to full time axis index

% Get peak time in ms
peak_time = tf_tax(peak_idx) * 1000;

% If no clear peak found, use 150ms
if isempty(peak_time) || isnan(peak_time)
    peak_time = 150;
    peak_idx = find(tf_tax >= peak_time/1000, 1);
end

% Initialize with window centered on peak
half_width = init_window / 2;
window_start = max(peak_time - half_width, min_time);
window_end = min(peak_time + half_width, max_time);

% Convert to indices
start_idx = find(tf_tax >= window_start/1000, 1);
end_idx = find(tf_tax >= window_end/1000, 1);
if isempty(start_idx) || isempty(end_idx)
    best_window = [NaN, NaN];
    best_idx = NaN;
    best_p = NaN;
    return;
end

% Calculate initial index
fast_resp = nanmean(fast_psth(:,:,start_idx:end_idx), 3);
slow_resp = nanmean(slow_psth(:,:,start_idx:end_idx), 3);
[best_idx, best_p] = utils.calculate_preference_index(slow_resp, fast_resp, 1); % Quick calculation
best_window = [window_start, window_end];

% Expand window until max width or no improvement
current_width = window_end - window_start;
half_step = expand_step / 2;
keep_expanding = true;

while keep_expanding && current_width < max_width
    % Calculate new window bounds
    new_start = max(window_start - half_step, min_time);
    new_end = min(window_end + half_step, max_time);
    
    % If no expansion possible, stop
    if new_start == window_start && new_end == window_end
        break;
    end
    
    % Convert to indices
    start_idx = find(tf_tax >= new_start/1000, 1);
    end_idx = find(tf_tax >= new_end/1000, 1);
    if isempty(start_idx) || isempty(end_idx)
        break;
    end
    
    % Calculate index with expanded window
    fast_resp = nanmean(fast_psth(:,:,start_idx:end_idx), 3);
    slow_resp = nanmean(slow_psth(:,:,start_idx:end_idx), 3);
    [new_idx, ~] = utils.calculate_preference_index(slow_resp, fast_resp, 1);
    
    % Compare to current best
    if abs(new_idx) > abs(best_idx)
        best_idx = new_idx;
        window_start = new_start;
        window_end = new_end;
        current_width = window_end - window_start;
    else
        % If no improvement, stop expanding
        keep_expanding = false;
    end
end


% Return final window bounds
best_window = [window_start, window_end];

end

function [pref, p] = calculate_preference_from_window(best_window, slow_psth, fast_psth, tf_tax, nIter)

% Final calculation with permutation test for optimal window
window_start = best_window(1);
window_end = best_window(2);
start_idx = find(tf_tax >= window_start/1000, 1);
end_idx = find(tf_tax >= window_end/1000, 1);
fast_resp = nanmean(fast_psth(:,:,start_idx:end_idx), 3);
slow_resp = nanmean(slow_psth(:,:,start_idx:end_idx), 3);
[pref, p] = utils.calculate_preference_index(slow_resp, fast_resp, nIter);


end