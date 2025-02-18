function correlate_timeTF_preference(avg_resps, indexes, ops)
% Plot correlation between time preference and TF preference, by area

% select only good units
multi = utils.get_multi(avg_resps, indexes);

rois = utils.group_rois;
% rois = utils.group_rois_fine;

% load preferences
[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);
[time_sensitive, time_pref] = utils.get_time_pref(indexes);
time_pref = indexes.timeBL;

% uncomment to flip eslf - will preserve time dimension
tf_pref = tf_pref .* indexes.conts;
time_pref = time_pref .* indexes.conts;

%% Iterate through rois and plot

% some plotting params
sz = 30;
for r = 1:height(rois) 
    in_roi = utils.get_units_in_area(indexes.loc, rois{r,2});

    
    tf_pref_roi = tf_pref;
    time_pref_roi = time_pref;
    
    % group units by preference
    fast = in_roi & ~multi & tf_pref_roi > 0 & tf_sensitive;
    slow = in_roi & ~multi & tf_pref_roi < 0 & tf_sensitive;
    
    fast_time = fast & time_sensitive;
    slow_time = slow & time_sensitive;

    if sum(in_roi & (fast|slow))<5
        continue
    end
    
    f = figure('Units', 'normalized', 'OuterPosition', [.4 .1 .06 .14]); hold on;
    
    % plot all tf sensitive
    scatter(time_pref_roi(fast), tf_pref_roi(fast), ...
            sz, 'filled', 'MarkerFaceColor', ops.colors.F_pref_light, 'MarkerFaceAlpha', .4, ...
            'MarkerEdgeAlpha', 0);
    scatter(time_pref_roi(slow), tf_pref_roi(slow),  ...
            sz, 'filled', 'MarkerFaceColor', ops.colors.S_pref_light, 'MarkerFaceAlpha', .4, ...
            'MarkerEdgeAlpha', 0);
        
    % highlight time sensitive
    scatter(time_pref_roi(fast_time), tf_pref_roi(fast_time), ...
            sz*1.2, 'filled', 'MarkerFaceColor', ops.colors.F_pref_light, 'MarkerFaceAlpha', .6, ...
            'MarkerEdgeAlpha', .7, 'MarkerEdgeColor', 'k');
    scatter(time_pref_roi(slow_time), tf_pref_roi(slow_time),  ...
            sz*1.2, 'filled', 'MarkerFaceColor', ops.colors.S_pref_light, 'MarkerFaceAlpha', .6, ...
            'MarkerEdgeAlpha', .7, 'MarkerEdgeColor', 'k');
    
        
     % correlation - kendall's tau, on all tf_sensitive units. We only care about the sign here!
     
     % only tf sensitive
%      tau = corr(sign(time_pref_roi(fast|slow)), sign(tf_pref_roi(fast|slow)), 'Type','pearson');
     tau = corr((time_pref_roi(fast|slow)), (tf_pref_roi(fast|slow)), 'Type','kendall', 'rows', 'complete');
     % sig test
     null_taus = nan(ops.nIter, 1);
     for ii = 1:ops.nIter
         null_tf = tf_pref_roi(fast|slow);
         null_tf = null_tf(randperm(length(null_tf)));
         null_taus(ii) = corr(sign(time_pref_roi(fast|slow)), sign(null_tf), 'Type','pearson');
     end
     p = 1-sum(abs(tau) > abs(null_taus))/ops.nIter;
      
     xlabel('Time pref')
     ylabel('TF pref')
     title(sprintf('%s: t=%.3f, p=%.3f', rois{r,1}, tau, p), 'FontWeight', 'normal', 'FontSize', 8);
     set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin')
     xlim([-.5 .5]); ylim([-.3 .3])
     xticks([-.5:.5:.5])
     yticks([-.25:.25:.25])
     if ops.saveFigs
     save_figures_multi_format(f, fullfile(ops.saveDir, 'expectation', ['time_tf_index_', rois{r,1}]), {'fig', 'svg', 'png', 'pdf'})
     end
end




end