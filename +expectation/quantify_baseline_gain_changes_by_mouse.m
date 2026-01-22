function quantify_baseline_gain_changes_by_mouse(avg_resps, t_ax, indexes, ops)
% Quantify change in baseline activity depending on expectation state
% avg_resps = utils.match_FS_sds(avg_resps, indexes);

% get all units responses to differenct TF pulses 
fexpf = smoothdata((avg_resps.FexpF - avg_resps.FRmu)./avg_resps.FRsd, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);
fexps = smoothdata((avg_resps.FexpS - avg_resps.FRmu)./avg_resps.FRsd, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);
sexpf = smoothdata((avg_resps.SexpF - avg_resps.FRmu)./avg_resps.FRsd, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);
sexps = smoothdata((avg_resps.SexpS - avg_resps.FRmu)./avg_resps.FRsd, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);
 
expf  = (fexpf + sexpf)/2;
exps  = (fexps + sexps)/2;

multi = utils.get_multi(avg_resps, indexes);
rois = utils.group_rois;
 
% tf_pref = indexes.tf_short;  
[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);

tf_sensitive   = indexes.tf_short_p < 0.01 & ~isnan(indexes.tf_short);
tf_pref  = indexes.tf_short;  

pre_t  = isbetween(t_ax.tf, [-.5 -.1]);
resp_t = isbetween(t_ax.tf, ops.respWin.tf);


%% Make plots


% plot params
spread = .02;
flip_tfs = [1 1 1];
animals = unique(indexes.animal);

for a = 1:length(animals)
    animal = animals{a};
    this_mouse = strcmp(indexes.animal, animal);
    f = figure('Units', 'normalized', 'OuterPosition', [.4 .4 .3 .4]);
    
    for r = [1 3]%1:height(rois)

        in_area = utils.get_units_in_area(indexes.loc, rois{r,2}) & this_mouse;
        flip_tf = flip_tfs(r); % flip tf instead of time
        tf_pref_roi = tf_pref .* in_area;
        if flip_tf
            tf_pref_roi = tf_pref_roi .* indexes.conts;
        end

        fast = tf_pref_roi > 0 & tf_sensitive & in_area & ~multi ;
        slow = tf_pref_roi < 0 & tf_sensitive & in_area & ~multi ;
        
        if sum(fast)<2 | sum(slow)<2
            fprintf('Insufficient data for animal %s\n', animal);
            continue
        end

        %% Baseline ramp
        subplot(2,height(rois),r); hold on;
        ramp_all  = nanmedian(nanmean(expf(fast | slow, pre_t),2) - nanmean(exps(fast | slow, pre_t),2));
        ramp_fast = nanmean(expf(fast, pre_t),2) - nanmean(exps(fast, pre_t),2) ;
        ramp_slow = nanmean(expf(slow, pre_t),2) - nanmean(exps(slow, pre_t),2) ; 

%         if flip_tf
%             ramp_fast(indexes.conts(fast)==-1) = -1*ramp_fast(indexes.conts(fast)==-1); 
%             ramp_slow(indexes.conts(slow)==-1) = -1*ramp_slow(indexes.conts(slow)==-1);
%         end
%         ramp_fast = ramp_fast-ramp_all;
%         ramp_slow = ramp_slow-ramp_all;
        % histograms
        violinPlot(ramp_fast, 'histOri', 'left', 'widthDiv', [2 1], 'divFactor',  2, 'showMM', 0, 'xValues', 0, ...
                    'color', ops.colors.F_pref_light);
        violinPlot(ramp_slow, 'histOri', 'right', 'widthDiv', [2 2], 'divFactor', 2, 'showMM', 0, 'xValues', 0, ...
                    'color', ops.colors.S_pref_light)
        % box plots?
    %     boxplot(ramp_fast, 'positions', -0.05, 'plotstyle', 'compact', ...
    %             'colors', ops.colors.F_pref_light, 'MedianStyle', 'line', 'symbol', '')
    %     boxplot(ramp_slow, 'positions', 0.05, 'plotstyle', 'compact', ...
    %             'colors', ops.colors.S_pref_light, 'MedianStyle', 'line', 'symbol', '')

        % scatter
        scatter(repelem(-.1,sum(fast),1)+spread*randn(sum(fast),1), ramp_fast, 8, ...
                 'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .5, ...
                 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .2)
        scatter(repelem(.1,sum(slow),1)+spread*randn(sum(slow),1), ramp_slow, 8, ...
                 'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .5, ...
                 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .2)


         % mean and error bars
         plot([-.2 -.2], nanmean(ramp_fast) + [-ci_95_magnitude(ramp_fast) ci_95_magnitude(ramp_fast)], ...
              'linewidth', 1.5, 'Color', 'k');
         plot([.2 .2], nanmean(ramp_slow) + [-ci_95_magnitude(ramp_slow) ci_95_magnitude(ramp_slow)], ...
              'linewidth', 1.5, 'Color', 'k');
         scatter(-.2, nanmean(ramp_fast), 60, '>', ...
                 'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeColor', 'k');
         scatter(.2, nanmean(ramp_slow), 60, '<', ...
                 'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeColor', 'k');

         % significance 
         [~, pf] = ttest(ramp_fast );
         [~, ps] = ttest(ramp_slow );
         pd = permutationTest(ramp_fast, ramp_slow, ops.nIter, 'sidedness', 'both'); 
         txtf = get_sig_text(pf);
         txts = get_sig_text(ps); 
         txtd = get_sig_text(pd);
         mysigstar(gca, -.2, -1.2, pf, 'k');
         mysigstar(gca, .2, -1.2, ps, 'k');

         ylim([-1.2 1.2])
         yticks([-1 0 1])
         yl = ylim;
         mysigstar(gca,  [-.2 .2], yl(2), pd, 'k');

         % 0 line
         xl = xlim;
         plot(xl, [0 0], '-k', 'linewidth', .5)
         set(gca, 'box', 'off', 'xcolor', 'none')

         fprintf('Baseline ramp means for %s: F = %.3f, S = %.3f\n', rois{r,1}, nanmean(ramp_fast), nanmean(ramp_slow))

         %% Gain 
         subplot(2,height(rois),r+height(rois)); hold on;

         fast = tf_pref_roi > 0 & tf_sensitive & in_area & ~multi ;
         slow = tf_pref_roi < 0 & tf_sensitive & in_area & ~multi ;

         gain_expF_fast = (absoluteMax(fexpf(fast,resp_t),2)-nanmean(fexpf(fast,pre_t),2)) - ...
                          (absoluteMax(sexpf(fast,resp_t),2)-nanmean(sexpf(fast,pre_t),2));
         gain_expS_fast = (absoluteMax(fexps(fast,resp_t),2)-nanmean(fexps(fast,pre_t),2)) - ...
                          (absoluteMax(sexps(fast,resp_t),2)-nanmean(sexps(fast,pre_t),2));
         gain_expF_slow = (absoluteMax(sexpf(slow,resp_t),2)-nanmean(sexpf(slow,pre_t),2)) - ...
                          (absoluteMax(fexpf(slow,resp_t),2)-nanmean(fexpf(slow,pre_t),2));
         gain_expS_slow = (absoluteMax(sexps(slow,resp_t),2)-nanmean(sexps(slow,pre_t),2)) - ...
                          (absoluteMax(fexps(slow,resp_t),2)-nanmean(fexps(slow,pre_t),2));
%          gain_all = nanmedian([gain_expF_fast; gain_expF_slow]-[gain_expS_fast; gain_expS_slow]);
%          gain_fast = gain_expF_fast - gain_expS_fast - gain_all; 
%          gain_slow = gain_expF_slow - gain_expS_slow - gain_all; 
         gain_fast = gain_expF_fast - gain_expS_fast ;
         gain_slow = gain_expF_slow - gain_expS_slow ;

    %     fast = tf_pref_roi > 0 & tf_sensitive & in_area & ~multi ;
    %     slow = tf_pref_roi < 0 & tf_sensitive & in_area & ~multi ;
    %      if flip_tf
    %         gain_fast(indexes.conts(fast)==-1) = -1*gain_fast(indexes.conts(fast)==-1); 
    %         gain_slow(indexes.conts(slow)==-1) = -1*gain_slow(indexes.conts(slow)==-1);
    %     end
         % histograms
         violinPlot(gain_fast, 'histOri', 'left', 'widthDiv', [2 1], 'showMM', 0, 'xValues', 0, ...
                    'color', ops.colors.F_pref_light);
         violinPlot(gain_slow, 'histOri', 'right', 'widthDiv', [2 2], 'showMM', 0, 'xValues', 0, ...
                    'color', ops.colors.S_pref_light)
    %       

         % box plots

    %      boxplot(gain_fast, 'positions', -0.05, 'plotstyle', 'compact', ...
    %             'colors', ops.colors.F_pref_light, 'MedianStyle', 'line', 'symbol', '')
    %      boxplot(gain_slow, 'positions', 0.05, 'plotstyle', 'compact', ...
    %             'colors', ops.colors.S_pref_light, 'MedianStyle', 'line', 'symbol', '')

         % scatter
         scatter(repelem(-.1,sum(fast),1)+spread*randn(sum(fast),1), gain_fast, 8, ...
                 'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .5, ...
                 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .2)
         scatter(repelem(.1,sum(slow),1)+spread*randn(sum(slow),1), gain_slow, 8, ...
                 'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .5, ...
                 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .2)

         % mean and error bars
         plot([-.2 -.2], nanmean(gain_fast) + [-ci_95_magnitude(gain_fast) ci_95_magnitude(gain_fast)], ...
              'linewidth', 1.5, 'Color', 'k');
         plot([.2 .2], nanmean(gain_slow) + [-ci_95_magnitude(gain_slow) ci_95_magnitude(gain_slow)], ...
              'linewidth', 1.5, 'Color', 'k');
         scatter(-.2, nanmean(gain_fast), 60, '>', ...
                 'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeColor', 'k');
         scatter(.2, nanmean(gain_slow), 60, '<', ...
                 'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeColor', 'k');

         % significance   
          [~, pf] = ttest(gain_fast );
          [~, ps] = ttest(gain_slow );
    %      pf = permutationTestOneSample(gain_fast, ops.nIter, 'mean'); 
    %      ps = permutationTestOneSample(gain_slow, ops.nIter, 'mean'); 

    %      pf = signrank(gain_fast);
    %      ps = signrank(gain_slow);
         pd = permutationTest(gain_fast, gain_slow, ops.nIter, 'sidedness', 'both');
         txtf = get_sig_text(pf);
         txts = get_sig_text(ps);
         txtd = get_sig_text(pd);
         mysigstar(gca, -.2, -1.2, pf, 'k');
         mysigstar(gca, .2, -1.2, ps, 'k');
         ylim([-1.2 1.2])
         yticks([-1 0 1])
         yl = ylim;
         mysigstar(gca,  [-.2 .2], yl(2), pd, 'k');

         % 0 line
         xl = xlim;
         plot(xl, [0 0], '-k', 'linewidth', .5)
         set(gca, 'box', 'off', 'xcolor', 'none')

         fprintf('Gain means for %s: F = %.3f, S = %.3f\n', rois{r,1}, nanmean(gain_fast), nanmean(gain_slow))
    end
    sgtitle(animal, 'interpreter', 'none')
end
if ops.saveFigs
    save_figures_multi_format(f, fullfile(ops.saveDir, 'expectation', 'ramp_gain_quants'), {'fig', 'svg', 'png', 'pdf'})
end
 
end