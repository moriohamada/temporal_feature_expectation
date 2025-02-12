function  sliding_correlation_analysis(avg_resps, t_ax, indexes, ops)
% SLIDING_CORRELATION_ANALYSIS Calculate sliding correlations between fast and slow 
% stimulus responses for each unit, grouped by TF responsiveness
%
% Inputs:
%   avg_resps - Table with average responses for different conditions
%   t_ax - Structure with time axes for different event types
%   indexes - Structure with unit classifications and metadata
%   ops - Structure with operational parameters
% 

% Define sliding window parameters
win_step = 0.01;  % 10ms step
win_size = 0.15;   % 200ms window

% Define windows of interest
tf_win = [0  0.4];     % TF pulse window
ch_win = [0 .4];     % Change response window
hit_win = [-0.3 .1]; % Define time ranges for each event type

tf_range = [-0.5, 1];     % TF pulse time range
ch_range = [-0.5, 1];      % Change time range
hit_range = [-1, 0.5];    % Hit lick time range

% Get ROIs
rois = utils.group_rois;

% Identify TF-sensitive units
[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);
% 
% tf_sensitive = (abs(indexes.tf_z_peakF)>1.5 | abs(indexes.tf_z_peakS)>1.5) & indexes.tf_short_p<.01 & ...
%                 indexes.tf_short~=0 & ~isnan(indexes.tf_short);
% Get multi-units (to exclude)
% multi = utils.get_multi(avg_resps, indexes) | avg_resps.FRmu<1 | avg_resps.FRsd.^2<1; % need higher firing for reliable correlations
 multi = utils.get_multi(avg_resps, indexes) ;
% Initialize figure handles
fr = cell(1, height(rois));
fh = cell(1, height(rois));
% avg_resps = utils.match_FS_sds(avg_resps, indexes);

% Loop through ROIs
for r = [1 3]%1:height(rois)
    % Get units in this ROI
    in_roi = utils.get_units_in_area(indexes.loc, rois{r,2}) & ~multi;
    
    % Skip if no units in this ROI
    if sum(in_roi) == 0
        continue;
    end
    
    % Categorize units by TF responsiveness
    tf_resp = tf_sensitive & in_roi;
    nonr_resp = ~tf_sensitive & in_roi & (indexes.tf_short_p)>.2 & abs(indexes.tf_short)<.1 & indexes.prelick_p<.1 ;
    % Define the populations
    populations = {tf_resp, nonr_resp};
    pop_names = {'TF-responsive', 'Non-TF'};
    
    % Define colors for each population
    if isfield(ops.colors, 'TFresp')
        tf_resp_color = ops.colors.TFresp;
    else
        tf_resp_color = [0.2 0.6 0.8]; % Default blue for TF responsive
    end
    pop_colors = {tf_resp_color, [0.5 0.5 0.5]};
    
    % Create figure for sliding correlations
    f  = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .12 .24]);
    
    % Loop through populations
    for pop_idx = 1:length(populations)
        selection = populations{pop_idx};
        clr = pop_colors{pop_idx};
        
        % Skip if no units in this population
        if sum(selection) == 0
            continue;
        end
        
        % Get responses for selected units
        resps = avg_resps(selection, :);
        
        %% TF Pulse Sliding Correlation
        subplot(2, 3, 1); hold on;
        
        % Get TF pulse responses for Fast and Slow
        psth_F = (resps.FexpF + resps.FexpS) / 2;
        psth_S = (resps.SexpF + resps.SexpS) / 2;
        
        % Generate sliding window correlation
        win_starts = (tf_range(1)-win_size/2):win_step:(tf_range(2)+win_size/2);
        win_ends = win_starts + win_size;
        win_mids = (win_starts + win_ends) / 2;
        
        % Preallocate results
        num_windows = length(win_starts);
        num_units = size(psth_F, 1);
        tf_corr = nan(num_units, num_windows);
        
        tf_win_idx = isbetween(win_starts, tf_win) & isbetween(win_ends, tf_win);
%         tf_win_idx = isbetween(win_mids, tf_win);
        
        % Calculate sliding window correlations
        parfor w = 1:num_windows
            % Get window indices
            window_idx = find(t_ax.tf >= win_starts(w) & t_ax.tf <= win_ends(w));
            
            % Skip windows with too few points
            if sum(window_idx) < 3
                continue;
            end
            F_data = psth_F(:, window_idx) - psth_F(:,window_idx(1));
            S_data = psth_S(:, window_idx) - psth_S(:,window_idx(1));
            tf_corr(:,w)= diag(corr(F_data', S_data', 'type', 'pearson'));
%             % Calculate correlation for each unit
%             for u = 1:num_units
%                 F_data = psth_F(u, window_idx);
%                 S_data = psth_S(u, window_idx);
%                 
%                 % Calculate correlation
%                 tf_corr(u, w) = corr(F_data', S_data', 'rows', 'complete');
%             end
        end
        
        % Smooth correlations
        tf_corr = smoothdata(tf_corr, 2, 'movmean', [5 0]);
        
%         % Baseline subtraction
        baseline_idx = win_mids >= -0.4 & win_mids <= -0.1;
        if sum(baseline_idx) > 0
            tf_corr = tf_corr - nanmean(tf_corr(:, baseline_idx), 2);
        end 
        % Plot
        shadedErrorBar(win_mids, nanmean(tf_corr, 1), 1.96*nanStdError(tf_corr, 1), ...
                       'lineprops', {'LineWidth', 1, 'color', clr});
        
        %% Change Response Sliding Correlation
        subplot(2, 3, 2); hold on;
        
        % Get change responses
        psth_F = resps.hitF;
        psth_S = resps.hitS;
        
        psth_F = utils.remove_baseline(psth_F, isbetween(t_ax.ch, [-.5 0]));
        psth_S = utils.remove_baseline(psth_S, isbetween(t_ax.ch, [-.5 0]));
        
        % Generate sliding window correlation
        win_starts = ch_range(1)-win_size/2:win_step:(ch_range(2)-win_size/2);
        win_ends = win_starts + win_size;
        win_mids = (win_starts + win_ends) / 2;
%         ch_win_idx = isbetween(win_mids, ch_win);
        ch_win_idx = isbetween(win_starts, ch_win) & isbetween(win_ends, ch_win);
        
        % Preallocate results
        num_windows = length(win_starts);
        ch_corr = nan(num_units, num_windows);
        
        % Calculate sliding window correlations
        parfor w = 1:num_windows
            % Get window indices
            window_idx = find(t_ax.ch >= win_starts(w) & t_ax.ch <= win_ends(w));
            
            % Skip windows with too few points
            if sum(window_idx) < 3
                continue;
            end
            
            F_data = psth_F(:, window_idx) - psth_F(:,window_idx(1));
            S_data = psth_S(:, window_idx) - psth_S(:,window_idx(1));
            ch_corr(:,w)= diag(corr(F_data', S_data', 'type', 'pearson'));
            % Calculate correlation for each unit
%             for u = 1:num_units
%                 F_data = psth_F(u, window_idx);
%                 S_data = psth_S(u, window_idx);
%                 
%                 % Skip if too few valid data points or constant values
%                 if sum(~isnan(F_data)) < 3 || sum(~isnan(S_data)) < 3 || ...
%                    all(F_data == F_data(1)) || all(S_data == S_data(1))
%                     continue;
%                 end
%                 
%                 % Calculate correlation
%                 ch_corr(u, w) = corr(F_data', S_data', 'rows', 'complete');
%             end
        end
        
        % Smooth correlations
        ch_corr = smoothdata(ch_corr, 2, 'gaussian', 25);
        
        % Baseline subtraction
        baseline_idx = win_mids >= -0.5 & win_mids <= -0.1;
        if sum(baseline_idx) > 0
            ch_corr = ch_corr - nanmean(ch_corr(:, baseline_idx), 2);
        end
        
        % Plot
        shadedErrorBar(win_mids, nanmean(ch_corr, 1), 1.96*nanStdError(ch_corr, 1), ...
                       'lineprops', {'LineWidth', 1, 'color', clr});
        
        %% Hit Lick Sliding Correlation
        subplot(2, 3, 3); hold on;
        
        % Get hit lick responses
        psth_F = resps.hitLickF;
        psth_S = resps.hitLickS;
        psth_F = utils.remove_baseline(psth_F, isbetween(t_ax.hit, [-.5 0]));
        psth_S = utils.remove_baseline(psth_S, isbetween(t_ax.hit, [-.5 0]));
        
        % Generate sliding window correlation
        win_starts = hit_range(1)-win_size/2:win_step:(hit_range(2)-win_size/2);
        win_ends = win_starts + win_size;
        win_mids = (win_starts + win_ends) / 2;
        
        hit_win_idx = isbetween(win_mids, hit_win);
%         hit_win_idx = isbetween(win_starts, hit_win) & isbetween(win_ends, hit_win);
        % Preallocate results
        num_windows = length(win_starts);
        hit_corr = nan(num_units, num_windows);
        
        % Calculate sliding window correlations
        parfor w = 1:num_windows
            % Get window indices
            window_idx = find(t_ax.hit >= win_starts(w) & t_ax.hit <= win_ends(w));
            
            % Skip windows with too few points
            if sum(window_idx) < 3
                continue;
            end
            
            % Calculate correlation for each unit
            
            F_data = psth_F(:, window_idx);% - psth_F(:,window_idx(1));
            S_data = psth_S(:, window_idx);% - psth_S(:,window_idx(1));
            hit_corr(:,w)= diag(corr(F_data', S_data', 'type', 'pearson'));
%             for u = 1:num_units
%                 F_data = psth_F(u, window_idx);
%                 S_data = psth_S(u, window_idx);
%                 
%                 % Skip if too few valid data points or constant values
%                 if sum(~isnan(F_data)) < 3 || sum(~isnan(S_data)) < 3 || ...
%                    all(F_data == F_data(1)) || all(S_data == S_data(1))
%                     continue;
%                 end
%                 
%                 % Calculate correlation
%                 hit_corr(u, w) = corr(F_data', S_data', 'rows', 'complete');
%             end
        end
        
        % Smooth correlations
        hit_corr = smoothdata(hit_corr, 2, 'gaussian', 25);
        
        % Baseline subtraction
        baseline_idx = win_mids >= -1.5 & win_mids <= -0.7;
        if sum(baseline_idx) > 0
            hit_corr = hit_corr - nanmean(hit_corr(:, baseline_idx), 2);
        end
        
        % Plot
        shadedErrorBar(win_mids, nanmean(hit_corr, 1), 1.96*nanStdError(hit_corr, 1), ...
                       'lineprops', {'LineWidth', 1, 'color', clr});
        
        %% Store window correlations for later histogram analysis
        % Calculate correlation in window of interest for TF pulses
        tf_window_corr = mean(tf_corr(:,tf_win_idx),2);
        
        % Calculate correlation in window of interest for Changes
        ch_window_corr = mean(ch_corr(:,ch_win_idx),2);
        
        
        % Calculate correlation in window of interest for Hit Licks
        hit_window_corr = mean(hit_corr(:,hit_win_idx),2);
        
        
        % Store window correlations
        if pop_idx == 1
            tf_resp_corr = {tf_window_corr, ch_window_corr, hit_window_corr};
        else
            nonr_resp_corr = {tf_window_corr, ch_window_corr, hit_window_corr};
        end
    end
    
    % Add highlights, labels, and formatting to sliding correlation plots
    for ii = 1:3
        subplot(2, 3, ii); hold on;
        xl = xlim;
        plot(xl, [0 0], 'k');
        ylim([-0.65 0.65]);
        yl = ylim;
        plot([0 0], yl, 'k');
        
        % Add labels
        if ii == 1
            title('TF Pulse Responses');
            xlabel('Time from pulse (s)');
            xlim([-0.2 1]);
            
            % Add highlighted window
            patch([tf_win(1) tf_win(2) tf_win(2) tf_win(1)], ...
                  [-0.65 -0.65 0.65 0.65], [199 67 117]/255, 'FaceAlpha', 0.1, 'edgeAlpha', 0);
            
        elseif ii == 2
            title('Change Responses');
            xlabel('Time from change (s)');
            xlim([-0.5 1]);
            
            % Add highlighted window
            patch([ch_win(1) ch_win(2) ch_win(2) ch_win(1)], ...
                  [-0.65 -0.65 0.65 0.65], [199 67 117]/255, 'FaceAlpha', 0.1, 'edgeAlpha', 0);
            
        else
            title('Hit Lick Responses');
            xlabel('Time from lick (s)');
            xlim([-1 0.5]);
            
            % Add highlighted window
            patch([hit_win(1) hit_win(2) hit_win(2) hit_win(1)], ...
                  [-0.65 -0.65 0.65 0.65], [199 67 117]/255, 'FaceAlpha', 0.1, 'edgeAlpha', 0);
        end
        ylabel('Correlation (r)');
    end
    
    
    % Add title
    sgtitle(['ROI: ' rois{r, 1}]);
    
    %% Create histogram figure for window analysis
    % Only if we have both TF-responsive and non-responsive data 
        % Define histogram parameters
        bins = -1:0.2:1;
        marker_loc = 0.3; % y location
        yl = [0 0.34];
        
        % Plot window-specific histograms
        for ii = 1:3
            subplot(2, 3, ii+3); hold on;
            
            % Get data for this window
            rvals1 = nonr_resp_corr{ii};
            rvals2 = tf_resp_corr{ii};
            
            % Plot histograms
            histogram(rvals1, bins, 'FaceColor', pop_colors{2}, 'EdgeAlpha', 0, 'Normalization', 'probability');
            histogram(rvals2, bins, 'FaceColor', pop_colors{1}, 'EdgeAlpha', 0, 'Normalization', 'probability');
            
            % Plot means with confidence intervals
            med1 = nanmean(rvals1);
            ci1 = 1.96 * nanStdError(rvals1);
            plot([med1-ci1 med1+ci1], [marker_loc marker_loc], 'k', 'linewidth', 1.5);
            scatter(med1, marker_loc, 70, 'v', 'MarkerFaceColor', pop_colors{2}, 'MarkerEdgecolor', pop_colors{2});
            
            med2 = nanmean(rvals2);
            ci2 = 1.96 * nanStdError(rvals2);
            plot([med2-ci2 med2+ci2], [marker_loc marker_loc], 'k', 'linewidth', 1.5);
            scatter(med2, marker_loc, 70, 'v', 'MarkerFaceColor', pop_colors{1}, 'MarkerEdgecolor', pop_colors{1});
            
            % Draw comparison line
            plot([med1 med2], [marker_loc marker_loc] * 1.1, 'k', 'linewidth', 1);
            
            % Calculate center position for text
            centre = (med1 + med2) / 2;
            
            % Perform permutation test
            p = permutationTest(rvals1, rvals2, 1000);
            
            % Add significance marker
            if p < 0.001
                sig_txt = '***';
            elseif p < 0.01
                sig_txt = '**';
            elseif p < 0.05
                sig_txt = '*';
            else
                sig_txt = 'ns';
            end
            
            text(centre, marker_loc * 1.12, sig_txt, 'FontWeight', 'normal', ...
                 'FontSize', 10, 'HorizontalAlignment', 'center');
            
            % Set axis appearance
            ylim(yl);
            plot([0 0], [0 0.3], '--', 'color', 'k', 'linewidth', 0.5);
            
            % Add labels
            if ii == 1
                title('TF Pulse Window');
                xlabel(['Correlation (' num2str(tf_win(1)) '-' num2str(tf_win(2)) 's)']);
            elseif ii == 2
                title('Change Window');
                xlabel(['Correlation (' num2str(ch_win(1)) '-' num2str(ch_win(2)) 's)']);
            else
                title('Hit Lick Window');
                xlabel(['Correlation (' num2str(hit_win(1)) '-' num2str(hit_win(2)) 's)']);
            end
            ylabel('Probability');
        end
        
        sgtitle(['ROI: ' rois{r, 1} ]);
        if ops.saveFigs
            save_figures_multi_format(f, fullfile(ops.saveDir,'neural', ['avg_tf_response_correlations_', rois{r,1}]), {'fig', 'svg', 'png' })
        end
end
 
 