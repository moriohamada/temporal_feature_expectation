function f = visualize_baseline_change_by_mouse(resps, t_ax, indexes, areas, ops)
% 
% Simplified gain 
% keyboard
%%
resps.FRsd = resps.FRsd * ops.spBinWidth/1000;
fexpf = (resps.FexpF - resps.FRmu)./resps.FRsd;
fexps = (resps.FexpS - resps.FRmu)./resps.FRsd;
sexpf = (resps.SexpF - resps.FRmu)./resps.FRsd;
sexps = (resps.SexpS - resps.FRmu)./resps.FRsd;

% fexpf = smoothdata(fexpf, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);
% fexps = smoothdata(fexps, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);
% sexpf = smoothdata(sexpf, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);
% sexps = smoothdata(sexps, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);

% tf_sensitive =   indexes.tf_short_p<.01;% & sign(indexes.tfExpF_short)==sign(indexes.tfExpS_short);% & (indexes.tfExpF_p<sqrt(.05)&indexes.tfExpS_p<sqrt(.05));
% tf_sensitive = indexes.tfExpF_short_p<.05 & indexes.tfExpS_short_p<.05;#
tf_sensitive = indexes.tf_short_p<.01 & sign(indexes.tfExpF_short)==sign(indexes.tfExpS_short);% & indexes.tf_short_p<.05;% (indexes.tfExpF_p<.05|indexes.tfExpS_p<.05);

pre_t  = isbetween(t_ax.tf, [-.5 -.1]);


% roi_colors = [ops.colors.Vis; ops.colors.Vis; ops.colors.PPC; ops.colors.PPC; ops.colors.MOs; ops.colors.MOs];
roi_colors = [ops.colors.Vis; ops.colors.PPC; ops.colors.MOs];

%%
indexes.animal = string(indexes.animal);
animals = unique(indexes.animal);

for a = 1:length(animals)
        animal = animals{a};

    %%
    f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .11 .32]);
    for r = 3%1:length(areas)


        in_area = contains(resps.loc, areas{r}) & strcmp(indexes.animal, animal);

        if r<=2
            fast  = indexes.tf_short < 0 & tf_sensitive & in_area;
            slow  = indexes.tf_short > 0 & tf_sensitive & in_area;
        else
            fast  = indexes.tf_short > 0 & tf_sensitive & in_area;
            slow  = indexes.tf_short < 0 & tf_sensitive & in_area;
        end
        
        if sum(fast)<2 | sum(slow)<2
            fprintf('Insufficient TF responsive unist for %s\n', strrep(animal, '_', ' '))
            continue
        end


        % calculate bl offset
        if r<=2
            ramp_expF = nanmean([fexps(:,pre_t), sexps(:,pre_t)],2);
            ramp_expS = nanmean([fexpf(:,pre_t), sexpf(:,pre_t)],2);
        else
            ramp_expF = nanmean([fexpf(:,pre_t), sexpf(:,pre_t)],2);
            ramp_expS = nanmean([fexps(:,pre_t), sexps(:,pre_t)],2);
        end

        % Plot
        subplot(3,1,1); hold on
        spread = .01;

        scatter(repelem(-.15+r,1,sum(fast)) + spread*randn(1, sum(fast)), ramp_expF(fast), 12, ...
                'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .25, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);
        scatter(repelem(0.6+r,1,sum(fast)) + spread*randn(1, sum(fast)), ramp_expS(fast), 12, ...
                'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .25, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);

        scatter(repelem(-.1+r,1,sum(slow)) + spread*randn(1, sum(slow)), ramp_expF(slow), 12, ...
                'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .2, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);
        scatter(repelem(0.65+r,1,sum(slow)) + spread*randn(1, sum(slow)), ramp_expS(slow), 12, ...
                'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .2, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);

        % plot means and errorbars
        plot([0 .5]+r, [mean(ramp_expF(fast)), mean(ramp_expS(fast))], ...
              'MarkerFaceColor', ops.colors.F_pref, ...
             'linewidth', 1.5, 'color', ops.colors.F_pref);
        plot([r r],mean(ramp_expF(fast)) + [-ci_95_magnitude(ramp_expF(fast)), ci_95_magnitude(ramp_expF(fast))], ...
              'linewidth', 1.5, 'color', 'k');
        plot([r r]+.5,mean(ramp_expS(fast)) + [-ci_95_magnitude(ramp_expS(fast)), ci_95_magnitude(ramp_expS(fast))], ...
              'linewidth', 1.5, 'color', 'k');
        scatter([0 .5]+r,  [mean(ramp_expF(fast)), mean(ramp_expS(fast))], 60, '>',...
                'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeColor', 'k');

        plot([0 .5]+r, [mean(ramp_expF(slow)), mean(ramp_expS(slow))],  ...
             'MarkerFaceColor', ops.colors.S_pref,...
             'linewidth', 1.5, 'color', ops.colors.S_pref);    
        plot([r r],mean(ramp_expF(slow)) + [-ci_95_magnitude(ramp_expF(slow)), ci_95_magnitude(ramp_expF(slow))], ...
              'linewidth', 1.5, 'color', 'k');
        plot([r r]+.5,mean(ramp_expS(slow)) + [-ci_95_magnitude(ramp_expS(slow)), ci_95_magnitude(ramp_expS(slow))], ...
              'linewidth', 1.5, 'color',  'k');
        scatter([0 .5]+r,  [mean(ramp_expF(slow)), mean(ramp_expS(slow))], 60, '<', ...
                'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeColor', 'k');



         % Plot delta (histograms + scatter)
         subplot(3,1,2); hold on
         spread = .02;

         fast_ramps = ramp_expF(fast) - ramp_expS(fast);
         slow_ramps = ramp_expF(slow) - ramp_expS(slow);

         % histograms
         violinPlot(fast_ramps, 'histOri', 'left', 'widthDiv', [2 1], 'showMM', 0, 'xValues', r, ...
                    'color', ops.colors.F_pref_light);
         violinPlot(slow_ramps, 'histOri', 'right', 'widthDiv', [2 2], 'showMM', 0, 'xValues', r, ...
                    'color', ops.colors.S_pref_light)
         % scatter
         scatter(repelem(r-.1,sum(fast),1)+spread*randn(sum(fast),1), fast_ramps, 12, ...
                 'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .5, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .4)
         scatter(repelem(r+.1,sum(slow),1)+spread*randn(sum(slow),1), slow_ramps, 12, ...
                 'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .5, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .4)

         % mean and error bars
         plot([r-.3 r-.3], nanmean(fast_ramps) + [-ci_95_magnitude(fast_ramps) ci_95_magnitude(fast_ramps)], ...
              'linewidth', 1.5, 'Color', 'k');
         plot([r+.3 r+.3], nanmean(slow_ramps) + [-ci_95_magnitude(slow_ramps) ci_95_magnitude(slow_ramps)], ...
              'linewidth', 1.5, 'Color', 'k');
         scatter(r-.3, nanmean(fast_ramps), 60, '>', ...
                 'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeColor', 'k');
         scatter(r+.3, nanmean(slow_ramps), 60, '<', ...
                 'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeColor', 'k');

         % significance tests
    %      pf = signrank(fast_ramps); txtf = get_sig_text(pf);
    %      ps = signrank(slow_ramps); txts = get_sig_text(ps);
    %      [~,pf] = ttest(fast_ramps); txtf = get_sig_text(pf);
    %      [~,ps] = ttest(slow_ramps); txts = get_sig_text(ps);
         pf = permutationTestOneSample(fast_ramps, ops.nIter, 'mean'); txtf = get_sig_text(pf);
         ps = permutationTestOneSample(slow_ramps, ops.nIter, 'mean'); txts = get_sig_text(ps);
         pd = permutationTest(fast_ramps, slow_ramps, ops.nIter); txtd = get_sig_text(pd);
         mysigstar(gca, r-.2, -12, pf, 'k');
         mysigstar(gca, r+.2, -12, ps, 'k');
    %      text(r-.2, -12, txtf, 'fontweight', 'normal', 'fontsize', 8, 'HorizontalAlignment', 'center');
    %      text(r+.2, -12, txts, 'fontweight', 'normal', 'fontsize', 8, 'HorizontalAlignment', 'center');
         mysigstar(gca, r + [-.3 .3], 12, pd, 'k');
    %      keyboard

         % combined F and S
         subplot(3,1,3); hold on;
         spread = .04;
         all_ramps = [fast_ramps; -1*slow_ramps];
         violinPlot(all_ramps, 'histOri', 'center', 'widthDiv', [2 1], 'showMM', 0, 'xValues', r, ...
                    'color', roi_colors(r,:));
         scatter(repelem(r+.15, length(all_ramps),1)+spread*randn(length(all_ramps),1), all_ramps, 12, ...
                 'MarkerFaceColor', roi_colors(r,:), 'MarkerFaceAlpha', .2, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1)
         plot([r+.3 r+.3], nanmean(all_ramps) + [-ci_95_magnitude(all_ramps) ci_95_magnitude(all_ramps)], ...
              'linewidth', 1.5, 'color', 'k');
         scatter(r+.3, nanmean(all_ramps), 60, '^', 'MarkerFaceColor', roi_colors(r,:), 'MarkerEdgeColor','k');

        % signf test
        p = permutationTestOneSample(all_ramps, ops.nIter); 
        mysigstar(gca, r, 16, p, 'k')

    end

    %%
    % 
    subplot(3,1,1); hold on
    set(gca, 'XColor', 'none')

    ylim([-5 12])
    % xlim([0.5 4])
    yticks([-5:5:10])

    subplot(3,1,2); hold on
    plot([0 4], [0 0], 'k', 'LineWidth', .5);
    % xlim([0.24 3.75])
    ylim([-15 12])
    yticks([-10 0 10])

    set(gca, 'XColor', 'none')

    subplot(3,1,3); hold on;
    plot([0 4], [0 0], 'k', 'LineWidth', .5);
    ylim([-11 20]);
    % xlim([.24 3.75])
    yticks([-10 0 10 20])
    set(gca, 'xcolor', 'none')
    
    sgtitle(animal);
end
end