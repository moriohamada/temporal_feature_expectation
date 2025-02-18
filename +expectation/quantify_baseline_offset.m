function quantify_baseline_gain_changes(avg_resps, t_ax, indexes, ops)
% Quantify change in baseline activity depending on expectation state

% get all units responses to differenct TF pulses
fexpf = (avg_resps.FexpF - avg_resps.FRmu)./avg_resps.FRsd;
fexps = (avg_resps.FexpS - avg_resps.FRmu)./avg_resps.FRsd;
sexpf = (avg_resps.SexpF - avg_resps.FRmu)./avg_resps.FRsd;
sexps = (avg_resps.SexpS - avg_resps.FRmu)./avg_resps.FRsd;

expf  = (fexpf + sexpf)/2;
exps  = (fexps + sexps)/2;

multi = utils.get_multi(avg_resps);
rois = utils.group_rois;

[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);
[time_sensitive, time_pref] = utils.get_time_pref(indexes);

pre_t  = isbetween(t_ax.tf, ops.respWin.tfContext);
resp_t = isbetween(t_ax.tf, ops.respWin.tfShort);

%% Make plots

f1 = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .11 .32]);

for r = 1:height(rois)
    
    in_area = utils.get_units_in_area(indexes.loc, rois{r,2});
    fast = tf_pref > 0 & tf_sensitive & in_area & ~multi;
    slow = tf_pref < 0 & tf_sensitive & in_area & ~multi;
    
    %% Baseline ramp
    subplot(2,3,r); hold on;
    ramp_fast = nanmean(expf(fast, pre_t),2) - nanmean(exps(fast, pre_t),2);
    ramp_slow = nanmean(expf(slow, pre_t),2) - nanmean(exps(slow, pre_t),2);
    
    % histograms
    violinPlot(ramp_fast, 'histOri', 'left', 'widthDiv', [2 1], 'showMM', 0, 'xValues', r, ...
                'color', ops.colors.F_pref_light);
    violinPlot(ramp_slow, 'histOri', 'right', 'widthDiv', [2 2], 'showMM', 0, 'xValues', r, ...
                'color', ops.colors.S_pref_light)
    
    
    
end

%% Gain change

end