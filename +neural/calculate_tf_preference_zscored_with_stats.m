function indexes = calculate_tf_preference_zscored_with_stats(t_ax, indexes, ops)
%
% Calculate TF preference based on z-scored average activity with permutation testing
%
% --------------------------------------------------------------------------------------------------
%%

% Remove existing z-scored fields if they exist
existing_fields = contains(fields(indexes), '_z_');
if sum(existing_fields)~=0 
    indexes = indexes(:, ~existing_fields(1:end-3)); % keep last 3 columns (properties)
end

% Get unique sessions
unique_sess = unique(indexes(:, {'animal', 'session'}));
n_shuffles = 1000;

% Define comparison types
comps = {'F', 'S', ''; ...
         'FexpF', 'SexpF', 'ExpF'; ...
         'FexpS', 'SexpS', 'ExpS'};

ev_types = {'FexpF', 'FexpS', 'SexpF', 'SexpS'};
norm_win = isbetween(t_ax.tf, ops.respWin.tfContext);
resp_win = isbetween(t_ax.tf, [0.05 .35]);

% Initialize output table
prefs = table();

% Pre-allocate all fields
for c = 1:height(comps)
    comp_name = comps{c,3};
    prefs.(sprintf('tf%s_z_peakD_p', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_absPeakD_p', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_absPeakF', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_absPeakS', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_absPeakD', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_absPeakTimeF', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_absPeakTimeS', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_absPeakTimeD', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_peakF', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_peakS', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_peakD', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_peakTimeF', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_peakTimeS', comp_name)) = zeros(height(indexes), 1);
    prefs.(sprintf('tf%s_z_peakTimeD', comp_name)) = zeros(height(indexes), 1);
end

for s = 1:height(unique_sess)
    animal = unique_sess.animal{s};
    session = unique_sess.session{s};

    fprintf('Session %d/%d: %s, %s\n', s, height(unique_sess), animal, session)
    
    % Load event PSTH data for this session
    ev_psths_path = fullfile(ops.eventPSTHdir, [animal,'_',session,'.mat']);
    ev_psths = load(ev_psths_path, 'psth_FexpF', 'psth_FexpS', 'psth_SexpF', 'psth_SexpS');
    
    % Find neurons belonging to this session
    sess_mask = strcmp(indexes.animal, animal) & strcmp(indexes.session, session);
    sess_idx = find(sess_mask);
    n_neurons = length(sess_idx);
    
    % Get dimensions - each event type can have different numbers of events
    [n_neurons_file, n_FexpF, n_time] = size(ev_psths.psth_FexpF);
    [~, n_FexpS, ~] = size(ev_psths.psth_FexpS);
    [~, n_SexpF, ~] = size(ev_psths.psth_SexpF);
    [~, n_SexpS, ~] = size(ev_psths.psth_SexpS);
    
    % Only use neurons that exist in our indexes table
    psth_FexpF = ev_psths.psth_FexpF(1:n_neurons, :, :);
    psth_FexpS = ev_psths.psth_FexpS(1:n_neurons, :, :);
    psth_SexpF = ev_psths.psth_SexpF(1:n_neurons, :, :);
    psth_SexpS = ev_psths.psth_SexpS(1:n_neurons, :, :);
    
    % Compute actual values from the data
    actual_avg_resps.FexpF = squeeze(mean(psth_FexpF, 2, 'omitmissing'));
    actual_avg_resps.FexpS = squeeze(mean(psth_FexpS, 2, 'omitmissing'));
    actual_avg_resps.SexpF = squeeze(mean(psth_SexpF, 2, 'omitmissing'));
    actual_avg_resps.SexpS = squeeze(mean(psth_SexpS, 2, 'omitmissing'));
    
    % Process responses: smooth and z-score
    actual_psths = struct();
    for evi = 1:length(ev_types)
        ev = ev_types{evi};
        psth = actual_avg_resps.(ev);
        psth = smoothdata(psth, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);
        
        % Z-score relative to baseline period
        norm = std(psth(:, norm_win), [], 2);
        norm(norm==0) = 1e-6;
        actual_psths.(ev) = (psth - mean(psth(:, norm_win), 2, 'omitmissing')) ./ norm;
    end
    
    % Average F and S conditions
    actual_psths.F = (actual_psths.FexpF + actual_psths.FexpS) / 2;
    actual_psths.S = (actual_psths.SexpF + actual_psths.SexpS) / 2;
    
    % Calculate actual preference metrics
    actual_peaks = zeros(n_neurons, height(comps));
    actual_abspeaks = zeros(n_neurons, height(comps));
    
    for c = 1:height(comps)
        resp_f = actual_psths.(comps{c,1})(:, resp_win);
        resp_s = actual_psths.(comps{c,2})(:, resp_win);
        resp_d = resp_f - resp_s;
        
        % Use vectorized absoluteMax for all neurons
        [abspeak_f, abspeak_time_f] = absoluteMax(resp_f, 2);
        [abspeak_s, abspeak_time_s] = absoluteMax(resp_s, 2);
        [abspeak_d, abspeak_time_d] = absoluteMax(resp_d, 2);
        
        % findFirstAbsPeaks handles all neurons at once
        [peak_f, peak_time_f] = utils.findFirstAbsPeaks(resp_f);
        [peak_s, peak_time_s] = utils.findFirstAbsPeaks(resp_s);
        [peak_d, peak_time_d] = utils.findFirstAbsPeaks(resp_d);
        
        actual_peaks(:, c) = peak_d;
        actual_abspeaks(:, c) = abspeak_d;
        
        % Store results for all neurons in this session
        prefs.(sprintf('tf%s_z_absPeakF', comps{c,3}))(sess_idx) = abspeak_f;
        prefs.(sprintf('tf%s_z_absPeakS', comps{c,3}))(sess_idx) = abspeak_s;
        prefs.(sprintf('tf%s_z_absPeakD', comps{c,3}))(sess_idx) = abspeak_d;
        prefs.(sprintf('tf%s_z_absPeakTimeF', comps{c,3}))(sess_idx) = abspeak_time_f;
        prefs.(sprintf('tf%s_z_absPeakTimeS', comps{c,3}))(sess_idx) = abspeak_time_s;
        prefs.(sprintf('tf%s_z_absPeakTimeD', comps{c,3}))(sess_idx) = abspeak_time_d;
        prefs.(sprintf('tf%s_z_peakF', comps{c,3}))(sess_idx) = peak_f;
        prefs.(sprintf('tf%s_z_peakS', comps{c,3}))(sess_idx) = peak_s;
        prefs.(sprintf('tf%s_z_peakD', comps{c,3}))(sess_idx) = peak_d;
        prefs.(sprintf('tf%s_z_peakTimeF', comps{c,3}))(sess_idx) = peak_time_f;
        prefs.(sprintf('tf%s_z_peakTimeS', comps{c,3}))(sess_idx) = peak_time_s;
        prefs.(sprintf('tf%s_z_peakTimeD', comps{c,3}))(sess_idx) = peak_time_d;
    end
    
    % Build null distributions using permutation
    null_peaks = zeros(n_neurons, n_shuffles, height(comps));
    null_abspeaks = zeros(n_neurons, n_shuffles, height(comps));
    
    % Combine ALL events for shuffling
    all_events = cat(2, psth_FexpF, psth_FexpS, psth_SexpF, psth_SexpS);
    
    % Create unique labels for each event type
    labels = [ones(n_FexpF, 1);      % FexpF = 1 (Fast stim, exp Fast)
              2*ones(n_FexpS, 1);     % FexpS = 2 (Fast stim, exp Slow)
              3*ones(n_SexpF, 1);     % SexpF = 3 (Slow stim, exp Fast)
              4*ones(n_SexpS, 1)];    % SexpS = 4 (Slow stim, exp Slow)
    
    % Parallel shuffling loop - do everything in one loop
    for shuf = 1:n_shuffles
        % Shuffle the event type labels
        % shuf_labels = labels(randperm(length(labels)));
        % shuffle keeping expectation
        expF_idx = find(labels == 1 | labels == 3);  % FexpF and SexpF events
        expS_idx = find(labels == 2 | labels == 4);  % FexpS and SexpS events

        % Get the labels for each expectation context
        expF_labels = labels(expF_idx);  % Will be mix of 1s and 3s
        expS_labels = labels(expS_idx);  % Will be mix of 2s and 4s

        % Shuffle within each expectation
        expF_labels_shuf = expF_labels(randperm(length(expF_labels)));
        expS_labels_shuf = expS_labels(randperm(length(expS_labels)));

        % Reconstruct the full shuffled labels array
        shuf_labels = labels;  % Start with original
        shuf_labels(expF_idx) = expF_labels_shuf;  % Replace with shuffled expF
        shuf_labels(expS_idx) = expS_labels_shuf;  % Replace with shuffled expS
        
        % Reconstruct the four conditions based on shuffled labels
        shuf_avg = struct();
        shuf_avg.FexpF = squeeze(mean(all_events(:, shuf_labels==1, :), 2, 'omitmissing'));
        shuf_avg.FexpS = squeeze(mean(all_events(:, shuf_labels==2, :), 2, 'omitmissing'));
        shuf_avg.SexpF = squeeze(mean(all_events(:, shuf_labels==3, :), 2, 'omitmissing'));
        shuf_avg.SexpS = squeeze(mean(all_events(:, shuf_labels==4, :), 2, 'omitmissing'));
        
        % Apply same processing pipeline as actual data
        shuf_psths = struct();
        for evi = 1:length(ev_types)
            psth = shuf_avg.(ev_types{evi});
            psth = smoothdata(psth, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);
            norm = std(psth(:, norm_win), [], 2);
            norm(norm==0) = inf;
            shuf_psths.(ev_types{evi}) = (psth - mean(psth(:, norm_win), 2, 'omitmissing')) ./ norm;
        end
        
        % Average to get F and S
        shuf_psths.F = (shuf_psths.FexpF + shuf_psths.FexpS) / 2;
        shuf_psths.S = (shuf_psths.SexpF + shuf_psths.SexpS) / 2;
        
        % Calculate null metrics for all comparisons
        shuf_results_peak = zeros(n_neurons, height(comps));
        shuf_results_abspeak = zeros(n_neurons, height(comps));
        
        for c = 1:height(comps)
            resp_f = shuf_psths.(comps{c,1})(:, resp_win);
            resp_s = shuf_psths.(comps{c,2})(:, resp_win);
            resp_d = resp_f - resp_s;
            
            [shuf_results_abspeak(:, c), ~] = absoluteMax(resp_d, 2);
            [shuf_results_peak(:, c), ~] = utils.findFirstAbsPeaks(resp_d);
        end
        
        % Store results from this shuffle
        null_peaks(:, shuf, :) = shuf_results_peak;
        null_abspeaks(:, shuf, :) = shuf_results_abspeak;
    end
    
    % Calculate p-values
    for n = 1:n_neurons
        idx = sess_idx(n);
        
        for c = 1:height(comps)
            comp_name = comps{c,3};
            
            % Two-tailed test
            p_val_peak = mean(abs(squeeze(null_peaks(n, :, c))) > abs(actual_peaks(n, c)), 'omitmissing');
            p_val_abspeak = mean(abs(squeeze(null_abspeaks(n, :, c))) > abs(actual_abspeaks(n, c)), 'omitmissing');
            
            prefs.(sprintf('tf%s_z_peakD_p', comp_name))(idx) = p_val_peak;
            prefs.(sprintf('tf%s_z_absPeakD_p', comp_name))(idx) = p_val_abspeak;
        end
    end
end

% Add new fields to indexes table
indexes = horzcat(indexes, prefs);

end