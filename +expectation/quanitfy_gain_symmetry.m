function f = plot_gain_offset_changes_to_outlier(resps, t_ax, indexes, areas, ops)


% conts = indexes.conts;
% indexes.timeBL = indexes.timeBL .* indexes.conts;
nN = height(resps);
% keyboard
%%
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .2 .4]);

% resps.FRmu = nanmean(resps.bl(:,isbetween(t_ax.blOn, [2 10])),2);
% resps.FRsd = nanstd(resps.bl(:,isbetween(t_ax.blOn, [2 10])),[],2);
scat= .02;

% resps.FRmu = nanmean(resps.bl(:,isbetween(t_ax.bl, [2 10])),2);
% resps.FRsd = nanstd(resps.bl(:,isbetween(t_ax.bl, [2 10])),[],2);
pre_pulse = isbetween(t_ax.tf, [-.4 -.1]);
% % 
pre_pulse_resp = cat(2, resps.FexpF(:, pre_pulse), resps.SexpF(:, pre_pulse));
% 
resps.FRmu = nanmean(pre_pulse_resp, 2);
resps.FRsd = nanstd(pre_pulse_resp,[],2);

% resps.FRmu = nanmean(resps.bl(:,isbetween(t_ax.bl, [1 11])),2);
% resps.FRsd = nanstd(resps.bl(:,isbetween(t_ax.bl, [1 11])),[],2);

fast  = indexes.tf_short > 0 & indexes.tf_short_p < .05;
slow  = indexes.tf_short < 0 & indexes.tf_short_p < .05;

for r = 1:length(areas)
    
    %%
    in_area = contains(resps.loc, areas{r});
    
    % baseline shift --------------------------------------------------------------------------------------------------
    pre_pulse = isbetween(t_ax.tf, [-.45 -.05]);

    fexpf = (nanmean(nanmean(cat(3, resps.SexpF(in_area & fast, pre_pulse), resps.FexpF(in_area & fast, pre_pulse)),3),2))./resps.FRsd(in_area&fast);
        
    fexps = (nanmean(nanmean(cat(3, resps.SexpS(in_area & fast, pre_pulse), resps.FexpS(in_area & fast, pre_pulse)),3),2))./resps.FRsd(in_area&fast);
        
    sexpf = (nanmean(nanmean(cat(3, resps.FexpF(in_area & slow, pre_pulse), resps.SexpF(in_area & slow, pre_pulse)),3),2))./resps.FRsd(in_area&slow);
       
    sexps = (nanmean(nanmean(cat(3, resps.FexpS(in_area & slow, pre_pulse), resps.SexpS(in_area & slow, pre_pulse)),3),2))./resps.FRsd(in_area&slow);
   
    
%     fexpf = (nanmean(resps.FexpF(in_area & fast, pre_pulse),2));% - resps.FRmu(in_area & fast))./resps.FRsd(in_area&fast);
%         
%     fexps = (nanmean(resps.FexpS(in_area & fast, pre_pulse),2));% - resps.FRmu(in_area & fast))./resps.FRsd(in_area&fast);
%         
%     sexpf = (nanmean(resps.SexpF(in_area & slow, pre_pulse),2));% - resps.FRmu(in_area & slow))./resps.FRsd(in_area&slow);
%        
%     sexps = (nanmean(resps.SexpS(in_area & slow, pre_pulse),2));% - resps.FRmu(in_area & slow))./resps.FRsd(in_area&slow);
        
    
	% remove huge outliers
    range = [(fexpf - fexps); (sexpf - sexps)];
    range = prctile(range, [2.5 97.5]);
    
    F = (fexpf - fexps);
    F = F(isbetween(F, range));
    S = (sexpf - sexps);
    S = S(isbetween(S, range));
    
    ax=subplot(3,3,r);cla; hold on
    violinPlot(F, 'histOri', 'left', 'widthDiv', [2 1], 'showMM', 0, 'xValues', 1,...
             'color', mat2cell(ops.colors.F_pref_light, 1));
    violinPlot(S, 'histOri', 'right', 'widthDiv', [2 2], 'showMM', 0, 'xValues', 1, ...
             'color',mat2cell(ops.colors.S_pref_light, 1));  
         
    for n = 1:length(F)
        scatter(1-.2+randn*scat, F(n), 12, 'filled', 'o', 'MarkerFaceColor', ops.colors.F_pref*.9, 'markerfacealpha', 1, 'MarkerEdgeColor', ops.colors.F_pref*.5)
    end

    for n = 1:length(S)
        scatter(1+.2+randn*scat, S(n),12, 'filled', 'o',  'MarkerFaceColor', ops.colors.S_pref*.9, 'markerfacealpha', 1,'MarkerEdgeColor',ops.colors.S_pref*.5)
    end
        plot([.5 1.5], [0 0], '--','color', [0 0 0])

    % add mean, mean
%     plot([.7 .7], prctile((fexpf-fexps),[5 95]), 'Color', 'k')
%     plot([1.3 1.3], prctile((sexpf-sexps),[5 95]), 'Color', 'k')

    plot([.7 .7], [nanmean(F)-nanStdError(F)*1.96, nanmean(F)+nanStdError(F)*1.96], ...
         'Color', 'k')
    plot([1.3 1.3], [nanmean(S)-nanStdError(S)*1.96, nanmean(S)+nanStdError(S)*1.96], ...
         'Color', 'k')

    scatter(1-.3, nanmean(F),60, '>', 'filled', 'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeColor', 'k')
    scatter(1+.3, nanmean(S),60, '<', 'filled', 'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeColor', 'k')
    % plot boxplot
%     b1 = boxplot(fexpf-fexps, 'PlotStyle','compact', 'Colors', ops.colors.F_pref, 'Positions', .8,'Symbol','');
%     b1 = boxplot(sexpf-sexps, 'PlotStyle','compact', 'Colors', ops.colors.S_pref, 'Positions', 1.2,'Symbol','');

    p = signrank(F);
    mysigstar(gca, 1-.2, -.25, p);
    
    p = signrank(S);
    mysigstar(gca, 1+.2, -.25, p);
    
    % and difference of differences between f and s
    [p] = permutationTest(F, S, 1000);

    mysigstar(ax, [.8 1.2], .2, p);
%     keyboard

   %% % gain -----------------------------------------------------------------------------------------
    resp_pulse = isbetween(t_ax.tf, [0.1 .4]);
    pre_pulse  = isbetween(t_ax.tf, [-.4 -.05]);
%     fexpf_g = (max(resps.FexpF(in_area & fast, resp_pulse),[],2) - resps.FRmu(in_area & fast))./resps.FRsd(in_area&fast);
%     fexps_g = (max(resps.FexpS(in_area & fast, resp_pulse),[],2) - resps.FRmu(in_area & fast))./resps.FRsd(in_area&fast);
%     sexpf_g = (max(resps.SexpF(in_area & slow, resp_pulse),[],2) - resps.FRmu(in_area & slow))./resps.FRsd(in_area&slow);
%     sexps_g = (max(resps.SexpS(in_area & slow, resp_pulse),[],2) - resps.FRmu(in_area & slow))./resps.FRsd(in_area&slow);
    
%     fexpf_g = (max(resps.FexpF(in_area & fast, resp_pulse),[],2) - nanmean(resps.FexpF(in_area & fast, pre_pulse),2))./nanmean(resps.FexpF(in_area & fast, pre_pulse),2);
%     fexps_g = (max(resps.FexpS(in_area & fast, resp_pulse),[],2) - nanmean(resps.FexpS(in_area & fast, pre_pulse),2))./nanmean(resps.FexpS(in_area & fast, pre_pulse),2);
%     sexpf_g = (max(resps.SexpF(in_area & slow, resp_pulse),[],2) - nanmean(resps.SexpF(in_area & slow, pre_pulse),2))./nanmean(resps.SexpF(in_area & slow, pre_pulse),2);
%     sexps_g = (max(resps.SexpS(in_area & slow, resp_pulse),[],2) - nanmean(resps.SexpS(in_area & slow, pre_pulse),2))./nanmean(resps.SexpS(in_area & slow, pre_pulse),2);


%     fexpf_g = (max(resps.FexpF(in_area & fast, resp_pulse),[],2) - nanmean(resps.FexpF(in_area & fast, pre_pulse),2));%./nanmean(resps.FexpF(in_area & fast, pre_pulse),2);
%     fexps_g = (max(resps.FexpS(in_area & fast, resp_pulse),[],2) - nanmean(resps.FexpS(in_area & fast, pre_pulse),2));%./nanmean(resps.FexpS(in_area & fast, pre_pulse),2);
%     sexpf_g = (max(resps.SexpF(in_area & slow, resp_pulse),[],2) - nanmean(resps.SexpF(in_area & slow, pre_pulse),2));%./nanmean(resps.SexpF(in_area & slow, pre_pulse),2);
%     sexps_g = (max(resps.SexpS(in_area & slow, resp_pulse),[],2) - nanmean(resps.SexpS(in_area & slow, pre_pulse),2));%./nanmean(resps.SexpS(in_area & slow, pre_pulse),2);

    fexpf_g = (max(resps.FexpF(in_area & fast, resp_pulse),[],2) - nanmean(resps.FexpF(in_area & fast, pre_pulse),2));%./nanmean(resps.FexpF(in_area & fast, pre_pulse),2);
    fexps_g = (max(resps.FexpS(in_area & fast, resp_pulse),[],2) - nanmean(resps.FexpS(in_area & fast, pre_pulse),2));%./nanmean(resps.FexpS(in_area & fast, pre_pulse),2);
    sexpf_g = (max(resps.SexpF(in_area & slow, resp_pulse),[],2) - nanmean(resps.SexpF(in_area & slow, pre_pulse),2));%./nanmean(resps.SexpF(in_area & slow, pre_pulse),2);
    sexps_g = (max(resps.SexpS(in_area & slow, resp_pulse),[],2) - nanmean(resps.SexpS(in_area & slow, pre_pulse),2));%./nanmean(resps.SexpS(in_area & slow, pre_pulse),2);

    
    fexpf_g = fexpf_g;
    fexps_g = fexps_g;
    sexpf_g = sexpf_g;
    sexps_g = sexps_g;
%     fexpf = (fexpf_g - fexpf);
%     fexps = (fexps_g - fexps);
%     sexpf = (sexpf_g - sexpf);
%     sexps = (sexps_g - sexps);

	% remove huge outliers
%     keyboard
    range = [(fexpf_g - fexps_g)./fexps_g; (sexpf_g - sexps_g)./sexpf_g];
    range = prctile(range, [2.5 97.5]);
    
    F = (fexpf_g - fexps_g)./fexps_g;
    F = F(isbetween(F, range));
    S = (sexpf_g - sexps_g)./sexpf_g;
    S = S(isbetween(S, range));
    
    ax=subplot(3,3,(3)+r); cla; hold on
    violinPlot(F, 'histOri', 'left', 'widthDiv', [2 1], 'showMM', 0, 'xValues', 1, ...
             'color', mat2cell(ops.colors.F_pref_light, 1));
    violinPlot(S, 'histOri', 'right', 'widthDiv', [2 2], 'showMM', 0, 'xValues', 1, ...
             'color',mat2cell(ops.colors.S_pref_light, 1));   
    
%     violinPlot(((fexpf_g - fexps_g)), 'histOri', 'left', 'widthDiv', [2 1], 'showMM', 0, 'xValues', 1, ...
%              'color', mat2cell(ops.colors.F_pref_light, 1));
%     violinPlot((sexpf_g - sexps_g), 'histOri', 'right', 'widthDiv', [2 2], 'showMM', 0, 'xValues', 1, ...
%              'color',mat2cell(ops.colors.S_pref_light, 1));  
    for n = 1:length(F)
        
        scatter(1-.2+randn*scat, F(n), 12, 'filled', 'o', 'MarkerFaceColor', ops.colors.F_pref*.9, 'markerfacealpha', .8, 'MarkerEdgeColor', ops.colors.F_pref*.5)
    end

    for n = 1:length(S)
        scatter(1+.2+randn*scat,  S(n), 12, 'filled', 'o',  'MarkerFaceColor', ops.colors.S_pref*.9, 'markerfacealpha', .8,'MarkerEdgeColor', ops.colors.S_pref*.5)
    end
        plot([.5 1.5], [0 0], '--','color', [0 0 0])
  
%     plot([.7 .7], prctile((fexpf_g-fexps_g),[5 95]), 'Color', 'k')
%     plot([1.3 1.3], prctile((sexpf_g-sexps_g),[5 95]), 'Color', 'k')
    plot([.7 .7], [nanmean(F)-nanStdError(F)*1.96, nanmean(F)+nanStdError(F)*1.96], ...
         'Color', 'k')
    plot([1.3 1.3], [nanmean(S)-nanStdError(S), nanmean(S)+nanStdError(S)*1.96], ...
         'Color', 'k')
%     plot([.7 .7], [nanmean(F)-nanStdError(F)*1.96, nanmean(F)+nanStdError(F)*1.96], ...
%          'Color', 'k')
%     plot([1.3 1.3], [nanmean((sexpf_g - sexps_g))-nanStdError((sexpf_g - sexps_g)), nanmean((sexpf_g - sexps_g))+nanStdError((sexpf_g - sexps_g))*1.96], ...
%          'Color', 'k')
     
    scatter(1-.3, nanmean(F),60, '>', 'filled', 'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeColor', 'k')
    scatter(1+.3, nanmean(S),60, '<', 'filled', 'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeColor', 'k')
    
    p = signrank(F);
%     [~,p] = ttest(F);
%     [~,p] = ttest(F./fexps_g)
    mysigstar(gca, 1-.2, -4.5, p);
    
    p = signrank(S);
%     [h,p] = ttest(S);

%     [~,p] = ttest(S./sexps_g)
    mysigstar(gca, 1+.2, -4.5, p);
    
    % and difference of differences between f and s
    p = permutationTest(F,S, 1000);
%     p = ranksum((fexpf_g-fexps_g),(sexpf_g-sexps_g))/2;
    mysigstar(ax, [1-.2 1.2], 4.5, p);
    
    %% pref - unpref
    
    %% relationship
    
    subplot(3,3,6+r); hold on;
    
%     scatter((fexpf-fexps),F, 30, 'filled',  'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeAlpha', 0)
%     scatter((sexpf-sexps),S, 30, 'filled',  'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeAlpha', 0)
end

%%

% for ii = 1:3
%     ax=subplot(3,3,ii);
%     hold on;
%     ax.XLim = [.5 1.5];
%     plot([.5 1.5], [0 0], '--','color', [0 0 0])
%     ax.YLim = [-.3 .3];
%     xticks([])
%     ax.XColor = 'none';
% end
for ii = 4:6
    ax=subplot(3,3,ii);
    hold on;
    ax.XLim = [.5 1.5];
    plot([.5 1.5], [0 0], '--','color', [0 0 0])
    ax.YLim = [-4 4];
    xticks([])
    ax.XColor = 'none';
end

subplot(3,3,1)
ylabel('\DeltaBaseline shift')
subplot(3,3,4)
ylabel('\DeltaPeak amplitude (%)')
%%
% keyboard


end