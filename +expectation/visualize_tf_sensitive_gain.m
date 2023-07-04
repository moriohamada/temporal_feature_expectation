function f = plot_tf_sensitive_gain(resps, t_ax, indexes, areas, ops)
% 
% Quick visual of gain changes - plot F-S response expF vs expS, and quantify gain
% 
% --------------------------------------------------------------------------------------------------

%%

sm = ops.spSmoothSize/ops.spBinWidth;
resps.FRsd = resps.FRsd * ops.spBinWidth/1000;

% conts = indexes.conts;

tf_idx = indexes.tf_short ;%.* conts;

% yls = [-3 5; -3 5; -3 5; -3 5; -4 4; -6 8; -6 8]; % for fine split


fexpf = (resps.FexpF - resps.FRmu)./resps.FRsd;
fexps = (resps.FexpS - resps.FRmu)./resps.FRsd;
sexpf = (resps.SexpF - resps.FRmu)./resps.FRsd;
sexps = (resps.SexpS - resps.FRmu)./resps.FRsd;

fexpf = smoothdata(fexpf, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);
fexps = smoothdata(fexps, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);
sexpf = smoothdata(sexpf, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);
sexps = smoothdata(sexps, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);

for r = 1:length(areas)

    f{r} = figure('Units', 'normalized', 'OuterPosition', [.1+r*.1 .1 .1 .1]);
%     yl = yls(r,:);
    
    in_area = contains(resps.loc, areas{r});
    
    fast = tf_idx>0;
    slow = tf_idx<0;
    
    respsF = resps(fast & in_area,:);
    respsS = resps(slow & in_area,:);
    
    psthF   = nanmean(smoothdata((respsF.hitF - respsF.FRmu)./respsF.FRsd, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]),1);
    psthS   = nanmean(smoothdata((respsS.hitS - respsS.FRmu)./respsS.FRsd, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]),1);
    
    psthF   = psthF(isbetween(t_ax.ch, [-.4 .1]));
    psthS   = psthS(isbetween(t_ax.ch, [-.4 .1]));
    scale_F = range(psthS)/range(psthF);

    
    % TF resps
    tf_types = {'FexpF', 'SexpF'; 'FexpS', 'SexpS'};
    cols = {ops.colors.E, ops.colors.L};
    for ii = 1:height(tf_types)
        tf_type1 = tf_types{ii,1};
        tf_type2 = tf_types{ii,2};
        X = smoothdata((resps.(tf_type1) - resps.(tf_type2))./resps.FRsd, 2, 'gaussian', sm);
        X(fast,:) = X(fast,:) * scale_F;
        X = detrend_resp(X, isbetween(t_ax.tf, [-.4 -.1]), isbetween(t_ax.tf, [.7 1.2]));
        pre_pulse = isbetween(t_ax.tf, [-.4 -.1]);
        X = X - nanmean(X(:, pre_pulse),2);
%         X = X.*conts;
        subplot(1,3,1); hold on
        shadedErrorBar(t_ax.tf, nanmean(X(in_area & fast,:),1), ci_95_magnitude(X(in_area & fast,:),1), ...
            'lineprops', {'color', cols{ii}, 'linewidth', 1.5})
        subplot(1,3,2); hold on
        shadedErrorBar(t_ax.tf, nanmean(X(in_area & slow,:),1), ci_95_magnitude(X(in_area & slow,:),1), ...
                      'lineprops', {'color', cols{ii}, 'linewidth', 1.5})
    end
%     % align ylims
%     yl_max = [inf -inf];
%     for ii = 1:2
%         subplot(1,3,ii); yl = ylim;
%         yl_max = [min([yl_max(1), yl(1)]), max([yl_max(2) yl(2)])];
%     end
%     for ii = 1:2 
%         subplot(1,3,ii);
%         ylim(yl_max);
%         offsetAxes
%     end
%     keyboard
    % gain quantification
    resp_t = isbetween(t_ax.tf, ops.respWin.tf);
    pre_t  = isbetween(t_ax.tf, [-.4 -.1]);
    tf_pref = fast-slow; tf_pref = tf_pref(in_area);
    gain_expF = (signed_absmax(fexpf(in_area,resp_t),2) - nanmean(fexpf(in_area, pre_t),2)) + ...
                (signed_absmax(sexpf(in_area,resp_t),2) - nanmean(sexpf(in_area, pre_t),2));
    gain_expS = (signed_absmax(fexps(in_area,resp_t),2) - nanmean(fexps(in_area, pre_t),2)) + ...
                (signed_absmax(sexps(in_area,resp_t),2) - nanmean(sexps(in_area, pre_t),2));
            
    fast_gains = gain_expF(tf_pref== 1) - gain_expS(tf_pref== 1);
    slow_gains = gain_expF(tf_pref==-1) - gain_expS(tf_pref==-1);
    % Plot gain quant
    subplot(1,3,3); cla; hold on
    spread=.005;
    scatter(repelem(.085,1,sum(tf_pref==1)) + spread*randn(1, sum(tf_pref==1)), fast_gains, 15, ...
            'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .25, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);
    scatter(repelem(.115,1,sum(tf_pref==-1)) + spread*randn(1, sum(tf_pref==-1)), slow_gains, 15, ...
            'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .25, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);
    plot([.09 .09], nanmedian(fast_gains) + [-1 1].*ci_95_magnitude(fast_gains), 'linewidth', 1, 'color', 'k');
    plot([.11 .11], nanmedian(slow_gains) + [-1 1].*ci_95_magnitude(slow_gains), 'linewidth', 1, 'color', 'k');
    scatter(.09, nanmean(fast_gains), 60, '^', 'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeColor', 'k');
    scatter(.11, nanmean(slow_gains), 60, '^', 'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeColor', 'k');
    xlim([.07 .13]);
    % signf test
    p = permutationTest(fast_gains, slow_gains, 10000);
    p_sym = get_sig_symbol(p);
    yl = ylim;
    text(.1, yl(2)+range(yl)*.1, p_sym, 'fontsize', 8, 'HorizontalAlignment', 'center')
    ylim([yl(1) yl(2)+range(yl)*.11])
%     keyboard
    
    % formatting
    
    
end

end