function plot_average_resps_by_tf_pref(avg_resps, t_ax, indexes, ops)

% select only good units
multi = utils.get_multi(avg_resps, indexes);

rois = utils.group_rois;

[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);
 
avg_resps = utils.match_FS_sds(avg_resps, indexes);
%% Plot TF pulse, change, and hit lick aligned activity by area

clrs = [ops.colors.S_pref; .5 .5 .5; ops.colors.F_pref]; % slow, non-pref, fast

for r = 1:height(rois)
    
    in_roi = utils.get_units_in_area(indexes.loc, rois{r,2})  & ~multi;
    
    fast    = tf_pref>0 & tf_sensitive & in_roi;
    slow    = tf_pref<0 & tf_sensitive &  in_roi;
    nontf   = ~tf_sensitive & in_roi;
        
    % label preferences: -1, 0, 1
    prefs = zeros(size(fast));
    prefs(fast) = 1;
    prefs(slow) = -1;
    prefs(nontf) = 0;
    
    f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .11 .15]);
    
    % loop through pref types
    for ii = 1:3
        
        pref_i = ii-2;
        sel = prefs == pref_i;

        %% TF pulse response
        
        % Fast pulse
        subplot(2,3,1); hold on;
        Rf = ((avg_resps{sel, 'FexpF'} + avg_resps{sel, 'FexpS'})/2 ...
              - avg_resps{sel, 'FRmu'}) ./ avg_resps{sel, 'FRsd'};
        Rf = utils.detrend_resp(Rf, isbetween(t_ax.tf, [-.5 -.2]), isbetween(t_ax.tf, [.7 1.2]));
        Rf = utils.remove_baseline(Rf, isbetween(t_ax.tf, ops.respWin.tfContext));
        shadedErrorBar(t_ax.tf, Rf, {@nanmean @ci_95_magnitude}, ...
                       'lineprops', {'color', clrs(ii,:), 'linewidth', 1.5});
        xlim([-.2 1])
        if ii==3
            yl = ylim;
            plot([0 0], yl, 'color', ops.colors.F, 'linewidth', .5);
        end
        
        % Slow pulse
        subplot(2,3,4); hold on;
        Rs = ((avg_resps{sel, 'SexpF'} + avg_resps{sel, 'SexpS'})/2 ...
              - avg_resps{sel, 'FRmu'}) ./ avg_resps{sel, 'FRsd'};
        Rs = utils.detrend_resp(Rs, isbetween(t_ax.tf, [-.5 -.2]), isbetween(t_ax.tf, [.7 1.2]));
        Rs = utils.remove_baseline(Rs, isbetween(t_ax.tf, ops.respWin.tfContext));
        shadedErrorBar(t_ax.tf, Rs, {@nanmean @ci_95_magnitude}, ...
                       'lineprops', {'color', clrs(ii,:), 'linewidth', 1.5});
        xlim([-.2 1])
        if ii==3
            yl = ylim;
            plot([0 0], yl, 'color', ops.colors.S, 'linewidth', .5);
        end
        
        %% Change response
        
        % Fast change
        subplot(2,3,2); hold on;
        Rchf = (avg_resps{sel, 'hitF'} - avg_resps{sel, 'FRmu'}) ./ avg_resps{sel, 'FRsd'};
        Rchf = utils.remove_baseline(Rchf, isbetween(t_ax.ch, [-1 0]));
        shadedErrorBar(t_ax.ch, Rchf, {@nanmean @ci_95_magnitude}, ...
                       'lineprops', {'color', clrs(ii,:), 'linewidth', 1.5});
        xlim([-.5 1])
        if ii==3
            yl = ylim;
            plot([0 0], yl, 'color', ops.colors.F, 'linewidth', .5);
        end
                   
        % Slow change
        subplot(2,3,5); hold on;
        Rchs = (avg_resps{sel, 'hitS'} - avg_resps{sel, 'FRmu'}) ./ avg_resps{sel, 'FRsd'};
        Rchs = utils.remove_baseline(Rchs, isbetween(t_ax.ch, [-1 0]));
        shadedErrorBar(t_ax.ch, Rchs, {@nanmean @ci_95_magnitude}, ...
                       'lineprops', {'color', clrs(ii,:), 'linewidth', 1.5});
        
        xlim([-.5 1])
        if ii==3
            yl = ylim;
            plot([0 0], yl, 'color', ops.colors.S, 'linewidth', .5);
        end
        %% Hit aligned
        
        % Fast hits
        subplot(2,3,3); hold on;
        Rhitf = (avg_resps{sel, 'hitLickF'} - avg_resps{sel, 'FRmu'}) ./ avg_resps{sel, 'FRsd'};
        Rhitf = utils.remove_baseline(Rhitf, isbetween(t_ax.hit, [-2 -1]));
        shadedErrorBar(t_ax.hit, Rhitf, {@nanmean @ci_95_magnitude}, ...
                       'lineprops', {'color', clrs(ii,:), 'linewidth', 1.5});
        xlim([-1 .5])
        if ii==3
            yl = ylim;
            plot([0 0], yl, 'color', ops.colors.F, 'linewidth', .5);
        end
        
        % Slow hits
        subplot(2,3,6); hold on;
        Rhits = (avg_resps{sel, 'hitLickS'} - avg_resps{sel, 'FRmu'}) ./ avg_resps{sel, 'FRsd'};
        Rhits = utils.remove_baseline(Rhits, isbetween(t_ax.hit, [-2 -1]));
        shadedErrorBar(t_ax.hit, Rhits, {@nanmean @ci_95_magnitude}, ...
                       'lineprops', {'color', clrs(ii,:), 'linewidth', 1.5});
        
        xlim([-1 .5])
        if ii==3
            yl = ylim;
            plot([0 0], yl, 'color', ops.colors.S, 'linewidth', .5);
        end
    end 
    if ops.saveFigs
        save_figures_multi_format(f, fullfile(ops.saveDir,'neural', ['avg_tf_responseive_basic_', rois{r,1}]), {'fig', 'svg', 'png', 'pdf'})
    end
end

end





