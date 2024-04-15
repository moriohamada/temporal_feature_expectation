function f = visualize_gain_change(resps, t_ax, indexes, areas, ops)
% 
% Simplified gain 
% keyboard
%%
resps.FRsd = resps.FRsd * ops.spBinWidth/1000;
fexpf = (resps.FexpF - resps.FRmu)./resps.FRsd;
fexps = (resps.FexpS - resps.FRmu)./resps.FRsd;
sexpf = (resps.SexpF - resps.FRmu)./resps.FRsd;
sexps = (resps.SexpS - resps.FRmu)./resps.FRsd;

fexpf = smoothdata(fexpf, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);
fexps = smoothdata(fexps, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);
sexpf = smoothdata(sexpf, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);
sexps = smoothdata(sexps, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);

tf_sensitive =   indexes.tf_short_p<.01;% & sign(indexes.tfExpF_short)==sign(indexes.tfExpS_short);% & (indexes.tfExpF_p<sqrt(.05)&indexes.tfExpS_p<sqrt(.05));
% tf_sensitive = indexes.tfExpF_short_p<.05 & indexes.tfExpS_short_p<.05;
pre_t  = isbetween(t_ax.tf, [-.5 0]);
resp_t = isbetween(t_ax.tf, [.05 .4]);


roi_colors = [ops.colors.Vis; ops.colors.PPC; ops.colors.MOs];
%%
% keyboard
%%
f = figure('Units', 'normalized', 'OuterPosition', [.25 .1 .11 .32]);
for r = 1:length(areas)
    
    
    in_area = contains(resps.loc, areas{r});
    if r<=2
        fast  = indexes.tf < 0 & tf_sensitive & in_area;
        slow  = indexes.tf > 0 & tf_sensitive & in_area;
    else
        fast  = indexes.tf > 0 & tf_sensitive & in_area;
        slow  = indexes.tf < 0 & tf_sensitive & in_area;
    end
    % rescale gains
    respsF = resps(fast & in_area,:);
    respsS = resps(slow & in_area,:);
    
    psthF_hitF   = nanmean(smoothdata((respsF.hitLickF - respsF.FRmu)./respsF.FRsd, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]),1);
    psthS_hitS   = nanmean(smoothdata((respsS.hitLickS - respsS.FRmu)./respsS.FRsd, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]),1);
    
    scale_F = range(psthS_hitS)/range(psthF_hitF);
    
    fexpf(fast,:) = fexpf(fast,:)*scale_F;
    fexps(fast,:) = fexps(fast,:)*scale_F;
    sexpf(fast,:) = sexpf(fast,:)*scale_F;
    sexps(fast,:) = sexps(fast,:)*scale_F;
    
    %%

    
    % calculate gain 
    if r<=2
        gain_expF = (absoluteMax(sexps(:,resp_t),2)-nanmean(sexps(:,pre_t),2)) - ...
                    (absoluteMax(fexps(:,resp_t),2)-nanmean(fexps(:,pre_t),2));
        gain_expS = (absoluteMax(sexpf(:,resp_t),2)-nanmean(sexpf(:,pre_t),2)) - ...
                    (absoluteMax(fexpf(:,resp_t),2)-nanmean(fexpf(:,pre_t),2));
    else
        gain_expF = (absoluteMax(fexpf(:,resp_t),2)-nanmean(fexpf(:,pre_t),2)) - ...
                    (absoluteMax(sexpf(:,resp_t),2)-nanmean(sexpf(:,pre_t),2));
        gain_expS = (absoluteMax(fexps(:,resp_t),2)-nanmean(fexps(:,pre_t),2)) - ...
                    (absoluteMax(sexps(:,resp_t),2)-nanmean(sexps(:,pre_t),2));
    end    
%     gain_expF = absoluteMax(fexpf(:,resp_t),2) - absoluteMax(sexpf(:,resp_t),2);
%     gain_expS = absoluteMax(fexps(:,resp_t),2) - absoluteMax(sexps(:,resp_t),2);
%     gain_expF = gain_expF./std(gain_expF);
%     gain_expS = gain_expS./std(gain_expS);
    
    
    % Plot
    subplot(3,1,1); hold on
    spread = .01;

%     plot([-.1 .55]+r,[gain_expF(fast), gain_expS(fast)]', 'linewidth', .2, 'color', [ops.colors.F_pref, 0.2]);
    scatter(repelem(-.15+r,1,sum(fast)) + spread*randn(1, sum(fast)), gain_expF(fast), 15, ...
            'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .25, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);
    scatter(repelem(0.6+r,1,sum(fast)) + spread*randn(1, sum(fast)), gain_expS(fast), 15, ...
            'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .25, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);
        
%     plot([-.05 .6]+r,-1*[gain_expF(slow), gain_expS(slow)]', 'linewidth', .2, 'color', [ops.colors.S_pref, 0.1]);
    scatter(repelem(-.1+r,1,sum(slow)) + spread*randn(1, sum(slow)), -gain_expF(slow), 15, ...
            'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .2, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);
    scatter(repelem(0.65+r,1,sum(slow)) + spread*randn(1, sum(slow)), -gain_expS(slow), 15, ...
            'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .2, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);
    
    % plot means and errorbars
%     
    plot([0 .5]+r, [mean(gain_expF(fast)), mean(gain_expS(fast))], ...
          'MarkerFaceColor', ops.colors.F_pref, ...
         'linewidth', 1.5, 'color', ops.colors.F_pref);
    plot([r r],mean(gain_expF(fast)) + [-ci_95_magnitude(gain_expF(fast)), ci_95_magnitude(gain_expF(fast))], ...
          'linewidth', 1.5, 'color', 'k');
    plot([r r]+.5,mean(gain_expS(fast)) + [-ci_95_magnitude(gain_expS(fast)), ci_95_magnitude(gain_expS(fast))], ...
          'linewidth', 1.5, 'color', 'k');
    scatter([0 .5]+r,  [mean(gain_expF(fast)), mean(gain_expS(fast))], 60, '>',...
            'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeColor', 'k');

    plot([0 .5]+r, -1*[mean(gain_expF(slow)), mean(gain_expS(slow))],  ...
         'MarkerFaceColor', ops.colors.S_pref,...
         'linewidth', 1.5, 'color', ops.colors.S_pref);    
    plot([r r],-1*mean(gain_expF(slow)) + [-ci_95_magnitude(gain_expF(slow)), ci_95_magnitude(gain_expF(slow))], ...
          'linewidth', 1.5, 'color', 'k');
    plot([r r]+.5,-1*mean(gain_expS(slow)) + [-ci_95_magnitude(gain_expS(slow)), ci_95_magnitude(gain_expS(slow))], ...
          'linewidth', 1.5, 'color',  'k');
    scatter([0 .5]+r,  -1*[mean(gain_expF(slow)), mean(gain_expS(slow))], 60, '<', ...
            'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeColor', 'k');

    
     
     % Plot delta (histograms + scatter)
     subplot(3,1,2); hold on
     spread = .02;

     fast_gains = gain_expF(fast) - gain_expS(fast);
     slow_gains = -gain_expF(slow) - -gain_expS(slow);
    
     % histograms
     violinPlot(fast_gains, 'histOri', 'left', 'widthDiv', [2 1], 'showMM', 0, 'xValues', r, ...
                'color', ops.colors.F_pref_light);
     violinPlot(slow_gains, 'histOri', 'right', 'widthDiv', [2 2], 'showMM', 0, 'xValues', r, ...
                'color', ops.colors.S_pref_light)
     % scatter
     scatter(repelem(r-.1,sum(fast),1)+spread*randn(sum(fast),1), fast_gains, 12, ...
             'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .5, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .4)
     scatter(repelem(r+.1,sum(slow),1)+spread*randn(sum(slow),1), slow_gains, 12, ...
             'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .5, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .4)
     
     % mean and error bars
     plot([r-.3 r-.3], nanmean(fast_gains) + [-ci_95_magnitude(fast_gains) ci_95_magnitude(fast_gains)], ...
          'linewidth', 1.5, 'Color', 'k');
     plot([r+.3 r+.3], nanmean(slow_gains) + [-ci_95_magnitude(slow_gains) ci_95_magnitude(slow_gains)], ...
          'linewidth', 1.5, 'Color', 'k');
     scatter(r-.3, nanmean(fast_gains), 60, '>', ...
             'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeColor', 'k');
     scatter(r+.3, nanmean(slow_gains), 60, '<', ...
             'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeColor', 'k');
         
     % significance tests
%      pf = signrank(fast_gains); txtf = get_sig_text(pf);
%      ps = signrank(slow_gains); txts = get_sig_text(ps);
%      [~,pf] = ttest(fast_gains); txtf = get_sig_text(pf);
%      [~,ps] = ttest(slow_gains); txts = get_sig_text(ps);
     pf = permutationTestOneSample(fast_gains, ops.nIter); txtf = get_sig_text(pf);
     ps = permutationTestOneSample(slow_gains, ops.nIter); txts = get_sig_text(ps);
     pd = permutationTest(fast_gains, slow_gains, ops.nIter); txtd = get_sig_text(pd);
%      text(r-.2, -15, txtf, 'fontweight', 'normal', 'fontsize', 8, 'HorizontalAlignment', 'center');
%      text(r+.2, -15, txts, 'fontweight', 'normal', 'fontsize', 8, 'HorizontalAlignment', 'center');
     mysigstar(gca, r-.2, -12, pf, 'k');
     mysigstar(gca, r+.2, -12, ps, 'k');
     mysigstar(gca, r + [-.3 .3], 13, pd, 'k');
%      keyboard

     % combined F and S
     subplot(3,1,3); hold on;
     spread = .04;
     all_gains = [fast_gains; -1*slow_gains];
     violinPlot(all_gains, 'histOri', 'center', 'widthDiv', [2 1], 'showMM', 0, 'xValues', r, ...
                'color', roi_colors(r,:));
     scatter(repelem(r+.15, length(all_gains),1)+spread*randn(length(all_gains),1), all_gains, 12, ...
             'MarkerFaceColor', roi_colors(r,:), 'MarkerFaceAlpha', .2, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1)
     plot([r+.3 r+.3], nanmean(all_gains) + [-ci_95_magnitude(all_gains) ci_95_magnitude(all_gains)], ...
          'linewidth', 1.5, 'color', 'k');
     scatter(r+.3, nanmean(all_gains), 60, '^', 'MarkerFaceColor', roi_colors(r,:), 'MarkerEdgeColor','k');

    % signf test
    p = permutationTestOneSample(all_gains, ops.nIter); 
    mysigstar(gca, r, 16, p, 'k')
    
end

%%

subplot(3,1,1); hold on
set(gca, 'XColor', 'none')

ylim([0 15])
xlim([0.5 4])

subplot(3,1,2); hold on
plot([0 4], [0 0], 'k', 'LineWidth', .5);
xlim([0.24 3.75])
ylim([-16 13])

set(gca, 'XColor', 'none')

subplot(3,1,3); hold on;
plot([0 4], [0 0], 'k', 'LineWidth', .5);
ylim([-10 16]);
xlim([.24 3.75])
set(gca, 'xcolor', 'none')
end