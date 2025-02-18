function pvals = visualize_tf_sensitive_ramp(avg_resps, t_ax, indexes, ops)
% VISUALIZE_BASELINE_CHANGE - Visualize baseline activity changes across brain areas
%
% Plots baseline activity changes for fast and slow preferring neurons
%
% Inputs:
%   avg_resps - Response data structure
%   t_ax      - Time axis structure
%   indexes   - Index structure containing tf_short
%   ops       - Options structure with parameters
%
% Outputs:
%   f         - Figure handle
 
% Normalize responses
fexpf = (avg_resps.FexpF - avg_resps.FRmu)./avg_resps.FRsd;
fexps = (avg_resps.FexpS - avg_resps.FRmu)./avg_resps.FRsd;
sexpf = (avg_resps.SexpF - avg_resps.FRmu)./avg_resps.FRsd;
sexps = (avg_resps.SexpS - avg_resps.FRmu)./avg_resps.FRsd;

% Apply detrending to responses
% fexpf = utils.detrend_resp(fexpf, isbetween(t_ax.tf, [-.5 -.1]), isbetween(t_ax.tf, [.7 1.2]));
% fexps = utils.detrend_resp(fexps, isbetween(t_ax.tf, [-.5 -.1]), isbetween(t_ax.tf, [.7 1.2]));
% sexpf = utils.detrend_resp(sexpf, isbetween(t_ax.tf, [-.5 -.1]), isbetween(t_ax.tf, [.7 1.2]));
% sexps = utils.detrend_resp(sexps, isbetween(t_ax.tf, [-.5 -.1]), isbetween(t_ax.tf, [.7 1.2]));

% Get TF preferences and sensitive neurons
[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes); 
rois = utils.group_rois_fine;
multi = utils.get_multi(avg_resps,  indexes);

% Define pre-stimulus time window
pre_t = isbetween(t_ax.tf, ops.respWin.tfContext);

% Create figure
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .11 .32]);

% Define flip for each brain area (based on first function's logic)
flip_tf = 1;

clrs = [ops.colors.Vis; ops.colors.Vis; ...
        ops.colors.PPC; ops.colors.PPC; ...
        ops.colors.MOs; ops.colors.MOs];
    
ramp_expF = nanmean([fexpf(:,pre_t)+sexpf(:,pre_t)]/2, 2);
ramp_expS = nanmean([fexps(:,pre_t)+sexps(:,pre_t)]/2, 2);
if flip_tf
    ramp_expF = ramp_expF .* indexes.conts;
    ramp_expS = ramp_expS .* indexes.conts;
    tf_pref = tf_pref .* indexes.conts;
end
 
% Process each brain area
pvals = ones(height(rois),1);
for r = 1:height(rois) 
    
    % Filter for current area
    in_area = utils.get_units_in_area(avg_resps.loc, rois{r,2});
    
    % Define fast and slow neurons based on TF preference 
    fast = tf_sensitive & ~multi & in_area & tf_pref>0;
    slow = tf_sensitive & ~multi & in_area & tf_pref<0;
     
    % Calculate baseline offset
    
%     end
    
    %% First subplot: Raw baseline values
    subplot(3,1,1); hold on
    spread = .01;
    
    % Scatter fast neurons
    scatter(repelem(-.15+r, 1, sum(fast)) + spread*randn(1, sum(fast)), ramp_expF(fast), 15, ...
        'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .25, ...
        'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', 0);
    scatter(repelem(0.6+r, 1, sum(fast)) + spread*randn(1, sum(fast)), ramp_expS(fast), 15, ...
        'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .25, ...
        'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', 0);
    
    % Scatter slow neurons
    scatter(repelem(-.1+r, 1, sum(slow)) + spread*randn(1, sum(slow)), ramp_expF(slow), 15, ...
        'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .2, ...
        'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', 0);
    scatter(repelem(0.65+r, 1, sum(slow)) + spread*randn(1, sum(slow)), ramp_expS(slow), 15, ...
        'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .2, ...
        'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', 0);
    
    % Plot means and error bars for fast neurons
    plot([0 .5]+r, [mean(ramp_expF(fast)), mean(ramp_expS(fast))], ...
        'linewidth', 1.5, 'color', ops.colors.F_pref);
    plot([r r], mean(ramp_expF(fast)) + [-ci_95_magnitude(ramp_expF(fast)), ci_95_magnitude(ramp_expF(fast))], ...
        'linewidth', 1.5, 'color', 'k');
    plot([r r]+.5, mean(ramp_expS(fast)) + [-ci_95_magnitude(ramp_expS(fast)), ci_95_magnitude(ramp_expS(fast))], ...
        'linewidth', 1.5, 'color', 'k');
    scatter([0 .5]+r, [mean(ramp_expF(fast)), mean(ramp_expS(fast))], 40, '>', ...
        'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeColor', 'k', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', .4);
    
    % Plot means and error bars for slow neurons
    plot([0 .5]+r, [mean(ramp_expF(slow)), mean(ramp_expS(slow))], ...
        'linewidth', 1.5, 'color', ops.colors.S_pref);
    plot([r r], mean(ramp_expF(slow)) + [-ci_95_magnitude(ramp_expF(slow)), ci_95_magnitude(ramp_expF(slow))], ...
        'linewidth', 1.5, 'color', 'k');
    plot([r r]+.5, mean(ramp_expS(slow)) + [-ci_95_magnitude(ramp_expS(slow)), ci_95_magnitude(ramp_expS(slow))], ...
        'linewidth', 1.5, 'color', 'k');
    scatter([0 .5]+r, [mean(ramp_expF(slow)), mean(ramp_expS(slow))], 40, '<', ...
        'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeColor', 'k', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', .4);
    
    %% Second subplot: Delta (baseline differences)
    subplot(3,1,2); hold on
    spread = .02;
    
    % Calculate differences
    fast_ramps = ramp_expF(fast) - ramp_expS(fast);
    slow_ramps = ramp_expF(slow) - ramp_expS(slow);
    all_ramps  = ramp_expF(fast|slow) - ramp_expS(fast|slow);
    %keyboard
    fast_ramps = fast_ramps - nanmean(all_ramps);
    slow_ramps = slow_ramps - nanmean(all_ramps);
    
    % Plot violin plots
    violinPlot(fast_ramps, 'histOri', 'left', 'widthDiv', [2 1], 'showMM', 0, 'xValues', r, ...
        'color', ops.colors.F_pref_light);
    violinPlot(slow_ramps, 'histOri', 'right', 'widthDiv', [2 2], 'showMM', 0, 'xValues', r, ...
        'color', ops.colors.S_pref_light);
%     boxplot(fast_ramps, 'positions', r-0.05, 'plotstyle', 'compact', ...
%             'colors', ops.colors.F_pref_light, 'MedianStyle', 'line', 'symbol', '')
%     boxplot(slow_ramps, 'positions', r+0.05, 'plotstyle', 'compact', ...
%             'colors', ops.colors.S_pref_light, 'MedianStyle', 'line', 'symbol', '')

    % Scatter individual points
    scatter(repelem(r-.1, sum(fast), 1) + spread*randn(sum(fast), 1), fast_ramps, 15, ...
        'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .5, ...
        'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);
    scatter(repelem(r+.1, sum(slow), 1) + spread*randn(sum(slow), 1), slow_ramps, 15, ...
        'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .5, ...
        'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);
    
    % Plot means and error bars
    plot([r-.3 r-.3], nanmean(fast_ramps) + [-ci_95_magnitude(fast_ramps) ci_95_magnitude(fast_ramps)], ...
        'linewidth', 1.5, 'Color', 'k');
    plot([r+.3 r+.3], nanmean(slow_ramps) + [-ci_95_magnitude(slow_ramps) ci_95_magnitude(slow_ramps)], ...
        'linewidth', 1.5, 'Color', 'k');
    scatter(r-.3, nanmean(fast_ramps), 40, '>', ...
        'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeColor', 'k','MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', .4);
    scatter(r+.3, nanmean(slow_ramps), 40, '<', ...
        'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeColor', 'k','MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', .4);
    
    % Significance tests
%     pf = permutationTestOneSample(fast_ramps, ops.nIter, 'mean');
%     ps = permutationTestOneSample(slow_ramps, ops.nIter, 'mean');
    [~, pf] = ttest(fast_ramps);
    [~, ps] = ttest(slow_ramps);
    pd = permutationTest(fast_ramps, slow_ramps, ops.nIter);
    
    % Add significance stars
    mysigstar(gca, r-.2, -1.2, pf, 'k');
    mysigstar(gca, r+.2, -1.2, ps, 'k');
    mysigstar(gca, r + [-.3 .3], 1.2, pd, 'k');
    set(gca, 'box', 'off')
    %% Third subplot: Combined fast and slow
    subplot(3,1,3); hold on;
    spread = .04;
    
    % Combine data (invert slow values to match direction)
    all_ramps = [fast_ramps; -1*slow_ramps];
    
    % Plot violin and scatter
    violinPlot(all_ramps, 'histOri', 'center', 'widthDiv', [2 1], 'showMM', 0, 'xValues', r, ...
        'color', clrs(r,:));
    scatter(repelem(r+.15, length(all_ramps), 1) + spread*randn(length(all_ramps), 1), all_ramps, 15, ...
        'MarkerFaceColor', clrs(r,:), 'MarkerFaceAlpha', .2, ...
        'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', 0);
    
    % Plot mean and error bars
    plot([r+.3 r+.3], nanmean(all_ramps) + [-ci_95_magnitude(all_ramps) ci_95_magnitude(all_ramps)], ...
        'linewidth', 1.5, 'color', 'k');
    scatter(r+.3, nanmean(all_ramps), 40, '^', ...
        'MarkerFaceColor', clrs(r,:), 'MarkerEdgeColor', 'k','MarkerFaceAlpha', .5, 'MarkerEdgeAlpha', .4);
    
    % Significance test
%     p = permutationTestOneSample(all_ramps, ops.nIter);
    [~,p] = ttest(all_ramps);
    mysigstar(gca, r, 1.6, p, 'k');
    pvals(r)=p;
end

% Formatting for first subplot
subplot(3,1,1); hold on
set(gca, 'XColor', 'none');
ylim([-.5 1.2]);
yticks(-.5:.5:1);
% offsetAxes();

% Formatting for second subplot
subplot(3,1,2); hold on
plot([0 7], [0 0], 'k', 'LineWidth', .5);
ylim([-1.5 1.2]);
yticks([-1 0 1]);
set(gca, 'XColor', 'none');
% offsetAxes();

% Formatting for third subplot
subplot(3,1,3); hold on;
plot([0 7], [0 0], 'k', 'LineWidth', .5);
ylim([-1.1 2.0]);
yticks([-1 0 1 2]);
set(gca, 'xcolor', 'none');
% offsetAxes();
xl = xlim;
plot(xl, [0 0], '-k', 'linewidth', .5)

% Save figures in multiple formats
if ops.saveFigs
save_figures_multi_format(f, fullfile(ops.saveDir, 'expectation', 'baseline_changes_fine'), {'fig', 'svg', 'png', 'pdf'});
end
pvals = utils.fdr_correction(pvals);
end