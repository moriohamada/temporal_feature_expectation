function scatter_unit_preferences(avg_resps, indexes, ops)
% Create scatter plots showing relationships between:
% 1) TF prefs (expF vs expS)
% 2) Pre-lick mod (expF vs expS)
% 3) TF pref vs pre-lick mod
% 
% --------------------------------------------------------------------------------------------------

%% select only good units
multi = utils.get_multi(avg_resps, indexes) ;

rois = utils.group_rois;

[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);

tf_sensitive = ((indexes.tf_z_peakF)>1.96 | (indexes.tf_z_peakS)>1.96) & ...
                indexes.tf_short_p<.05 & ...
                indexes.tf_short~=0 & ~isnan(indexes.tf_short) & sign(indexes.tf_short)==sign(indexes.tf_z_peakD);

%% Scatter 

clrs  = [.6 .6 .6; ops.colors.S_pref; ops.colors.F_pref]; % non, slow, fast
alphs = [.3, .6, .6]; 
szs   = [20, 30, 30];

for r = 1:height(rois)
    
    in_roi = utils.get_units_in_area(indexes.loc, rois{r,2}) & ~multi;
    
    fast    = tf_pref>0 & in_roi & tf_sensitive;
    slow    = tf_pref<0 &  in_roi & tf_sensitive;
    nontf   = ~tf_sensitive & in_roi;
        
    % label preferences: -1, 0, 1
    prefs = zeros(size(fast));
    prefs(fast)  = 3;
    prefs(slow)  = 2;
    prefs(nontf) = 1;
    
    f=figure('Units', 'normalized', 'OuterPosition', [.1 .1 .11 .07]);

    % loop through pref types
    for pref_i = 1:3
        
        
        %% TF expF vs expS
        
        subplot(1,3,1); hold on;
        sel = prefs == pref_i & ...
              (indexes.tfExpF_short_p<.05 & indexes.tfExpS_short_p<.05); 
        scatter(indexes{sel, 'tfExpF_short'}, indexes{sel, 'tfExpS_short'}, szs(pref_i), ...
                'MarkerFaceColor', clrs(pref_i,:), 'MarkerFaceAlpha', alphs(pref_i), ...
                'MarkerEdgeAlpha', 0)
        set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin')
        xlim([-.5 .5]); ylim([-.5 .5])
        plot([-.5 .5], [-.5 .5], 'k', 'linewidth', .5)
        
        %% Prelick expF vs expS
        subplot(1,3,2); hold on;
        
        sel = prefs == pref_i & ...
              (indexes.prelickExpF_p < .01 & indexes.prelickExpS_p < .01);
        scatter(indexes{sel, 'prelickExpF'}, indexes{sel, 'prelickExpS'}, szs(pref_i), ...
                'MarkerFaceColor', clrs(pref_i,:), 'MarkerFaceAlpha', alphs(pref_i), ...
                'MarkerEdgeAlpha', 0)
        set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin')
        xlim([-.5 .5]); ylim([-.5 .5])
        plot([-.5 .5], [-.5 .5], 'k', 'linewidth', .5)
        
        %% TF vs prelick
        
        subplot(1,3,3); hold on;
        
        sel = prefs == pref_i  &  indexes.prelick_p < .01;
        scatter(indexes{sel, 'tf_short'}, indexes{sel, 'prelick'}, szs(pref_i), ...
                'MarkerFaceColor', clrs(pref_i,:), 'MarkerFaceAlpha', alphs(pref_i), ...
                'MarkerEdgeAlpha', 0)
        set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin')
        xlim([-.5 .5]); ylim([-.5 .5])
         
        
        
    end
    if ops.saveFigs
        save_figures_multi_format(f, fullfile(ops.saveDir, 'neural', ['unit_preference_scatters_', rois{r,1}]), {'fig', 'svg', 'png', 'pdf'})
    end
end