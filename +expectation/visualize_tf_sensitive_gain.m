function f = visualize_tf_sensitive_gain(avg_resps, t_ax, indexes,  ops)
% PLOT_TF_SENSITIVE_GAIN - Visualize gain changes between fast and slow responses
%
% Plots F-S response expF vs expS and quantifies gain differences
%
% Inputs:
%   resps    - Response data structure
%   t_ax     - Time axis structure
%   indexes  - Index structure containing tf_short
%   ops      - Options structure with parameters
%
% Outputs:
%   f        - Array of figure handles

% Calculate smoothing factor
sm = ops.spSmoothSize/ops.spBinWidth;
 
[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);

% tf_sensitive =  indexes.tf_short_p<.01 & ...
%                 indexes.tf_short~=0 & ~isnan(indexes.tf_short);
            
rois = utils.group_rois_fine;
multi = utils.get_multi(avg_resps, indexes);
avg_resps = utils.match_FS_sds(avg_resps, indexes);
pre_t = isbetween(t_ax.tf, ops.respWin.tfContext);

R.fexpf = (avg_resps.FexpF - avg_resps.FRmu)./avg_resps.FRsd;
% fexpf = (fexpf - nanmean(fexpf(:,  pre_t), 2))./nanstd(fexpf(:, pre_t),[],2);
% R.fexpf = utils.detrend_resp(fexpf,  isbetween(t_ax.tf, [-.5 -.1]), isbetween(t_ax.tf, [.7 1.2]));
% fexpf = smoothdata(fexpf, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);

R.fexps = (avg_resps.FexpS - avg_resps.FRmu)./avg_resps.FRsd;
% fexps = (fexps - nanmean(fexps(:,  pre_t), 2))./nanstd(fexps(:, pre_t),[],2);
% R.fexps = utils.detrend_resp(fexps,  isbetween(t_ax.tf, [-.5 -.1]), isbetween(t_ax.tf, [.7 1.2]));
% fexps = smoothdata(fexps, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);

R.sexpf = (avg_resps.SexpF - avg_resps.FRmu)./avg_resps.FRsd;
% R.sexpf = utils.detrend_resp(sexpf,  isbetween(t_ax.tf, [-.5  -.1]), isbetween(t_ax.tf, [.7 1.2]));
% R.sexpf = (sexpf - nanmean(sexpf(:,  pre_t), 2))./nanstd(sexpf(:, pre_t),[],2);
% sexpf = smoothdata(sexpf, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);

R.sexps = (avg_resps.SexpS - avg_resps.FRmu)./avg_resps.FRsd;
% R.sexps = utils.detrend_resp(sexps,  isbetween(t_ax.tf, [-.5 -.1]), isbetween(t_ax.tf, [.7 1.2]));
% R.sexps = (sexps - nanmean(sexps(:,  pre_t), 2))./nanstd(sexps(:, pre_t),[],2);
% sexps = smoothdata(sexps, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);


resp_t = isbetween(t_ax.tf, ops.respWin.tfShort);
pre_t  = isbetween(t_ax.tf, ops.respWin.tfContext);
% gain_expF = (signed_absmax(fexpf(:,resp_t),2) - nanmean(fexpf(:, pre_t),2)) + ...
%     (signed_absmax(sexpf(:,resp_t),2) - nanmean(sexpf(:, pre_t),2));
% gain_expS = (signed_absmax(fexps(:,resp_t),2) - nanmean(fexps(:, pre_t),2)) + ...
%     (signed_absmax(sexps(:,resp_t),2) - nanmean(sexps(:, pre_t),2));

flip_tfs = [1 1 1 1 1 1]*1;
% Process each brain area
pvals = ones(height(rois),1);
for r = 1:height(rois)
    flip_tf = flip_tfs(r);
    % Create figure
    f = figure('Units', 'normalized', 'OuterPosition', [.1+r*.1 .1 .08 .11]);
    
    % Filter for current area
    in_area = utils.get_units_in_area(avg_resps.loc, rois{r,2});
    
    % Separate fast and slow responses
    if flip_tf
        fast = tf_sensitive & ~multi & in_area & tf_pref.*indexes.conts>0;
        slow = tf_sensitive & ~multi & in_area & tf_pref.*indexes.conts<0;
    else
        fast = tf_sensitive & ~multi & in_area & tf_pref>0;
        slow = tf_sensitive & ~multi & in_area & tf_pref<0;
    end
    % Plot TF responses
    tf_types = {'fexpf', 'sexpf'; ...
                'fexps', 'sexps'}; 
    cols = {ops.colors.E, ops.colors.L};
    
    for ii = 1:height(tf_types)
        tf_type1 = tf_types{ii,1};
        tf_type2 = tf_types{ii,2};
        
        % Calculate difference
        X = smoothdata((R.(tf_type1) - R.(tf_type2)), 2, 'movmean', [sm 0]);
         % Detrend and normalize
        %X = utils.detrend_resp(X, isbetween(t_ax.tf, [-.4 -.1]), isbetween(t_ax.tf, [.7 1.2]));
        pre_pulse = isbetween(t_ax.tf, [-.5 -0]);
        X = X - nanmean(X(:, pre_pulse), 2);
        if flip_tf
            X(indexes.conts==-1,:) = -1*X(indexes.conts==-1,:);
        end
        % Plot fast responses
        subplot(1,3,1); hold on
        shadedErrorBar(t_ax.tf, nanmean(X(fast,:), 1), ci_95_magnitude(X(fast,:), 1), ...
            'lineprops', {'color', cols{ii}, 'linewidth', 1.5});
        ylim([-.75 .75])
        xlim([-.2 1])
        % Plot slow responses
        subplot(1,3,2); hold on
        shadedErrorBar(t_ax.tf, nanmean(X(slow,:), 1), ci_95_magnitude(X(slow,:), 1), ...
            'lineprops', {'color', cols{ii}, 'linewidth', 1.5});
        ylim([-.75 .75])
        xlim([-.2 1])
    end
    
    % Apply offset to axes
    for ii = 1:2 
        subplot(1,3,ii);
        offsetAxes();
    end
    
    % Calculate gain quantification
    resp_t = isbetween(t_ax.tf, ops.respWin.tfShort);
    pre_t = isbetween(t_ax.tf, [-.4 -.1]);
 
    
    % Calculate gains for different conditions
    gain_expF_fast = (absoluteMax(R.fexpf(fast,resp_t),2)-nanmean(R.fexpf(fast,pre_t),2)) - ...
                     (absoluteMax(R.sexpf(fast,resp_t),2)-nanmean(R.sexpf(fast,pre_t),2));
    gain_expS_fast = (absoluteMax(R.fexps(fast,resp_t),2)-nanmean(R.fexps(fast,pre_t),2)) - ...
                     (absoluteMax(R.sexps(fast,resp_t),2)-nanmean(R.sexps(fast,pre_t),2));
    gain_expF_slow = (absoluteMax(R.sexpf(slow,resp_t),2)-nanmean(R.sexpf(slow,pre_t),2)) - ...
                     (absoluteMax(R.fexpf(slow,resp_t),2)-nanmean(R.fexpf(slow,pre_t),2));
    gain_expS_slow = (absoluteMax(R.sexps(slow,resp_t),2)-nanmean(R.sexps(slow,pre_t),2)) - ...
                     (absoluteMax(R.fexps(slow,resp_t),2)-nanmean(R.fexps(slow,pre_t),2));
    fast_gains = gain_expF_fast - gain_expS_fast ;
    slow_gains = gain_expF_slow - gain_expS_slow ;
      
    if flip_tf
        fast_gains(indexes.conts(fast)==-1) = -1 * fast_gains(indexes.conts(fast)==-1);
        slow_gains(indexes.conts(slow)==-1) = -1 * slow_gains(indexes.conts(slow)==-1);
    end
     
    % Plot gain quantification
    subplot(1,3,3); cla; hold on
    spread = .005;
     

    
    % Scatter fast gains
    scatter(repelem(.085, 1, sum(fast)) + spread*randn(1, sum(fast)), fast_gains, 15, ...
        'MarkerFaceColor', ops.colors.F_pref, 'MarkerFaceAlpha', .25, ...
        'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);
    
    % Scatter slow gains
    scatter(repelem(.115, 1, sum(slow)) + spread*randn(1, sum(slow)), slow_gains, 15, ...
        'MarkerFaceColor', ops.colors.S_pref, 'MarkerFaceAlpha', .25, ...
        'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .1);
    
    
    % Plot confidence intervals
    plot([.09 .09], nanmean(fast_gains) + [-1 1].*ci_95_magnitude(fast_gains), 'linewidth', 1, 'color', 'k');
    plot([.11 .11], nanmean(slow_gains) + [-1 1].*ci_95_magnitude(slow_gains), 'linewidth', 1, 'color', 'k');
    
    % Plot means
    scatter(.09, nanmean(fast_gains), 60, '^', 'MarkerFaceColor', ops.colors.F_pref, 'MarkerEdgeColor', 'k');
    scatter(.11, nanmean(slow_gains), 60, '^', 'MarkerFaceColor', ops.colors.S_pref, 'MarkerEdgeColor', 'k');
    
    % Set axis limits
    xlim([.07 .13]);
    
    % Significance test
%     [~,p] = ttest2(fast_gains, slow_gains )
    p = permutationTest(fast_gains, slow_gains, ops.nIter)
    p_sym = get_sig_symbol(p);
    ylim([-1.5 1.5])
    yticks([-1.5 1.5])
    yl = ylim;
    text(.1, yl(2) + range(yl)*.1, p_sym, 'fontsize', 8, 'HorizontalAlignment', 'center');
    ylim([yl(1), yl(2) + range(yl)*.11]);
    xl = xlim;
    plot(xl, [0 0], '-k')
    set(gca, 'xcolor','none')
%     sgtitle(rois{r,1})
    if ops.saveFigs
    save_figures_multi_format(f, fullfile(ops.saveDir, 'expectation', ['gain_visual_', rois{r,1}]), {'fig', 'svg', 'png', 'pdf'})
    end
    pvals(r) = p;
    
    
end
pvals = utils.fdr_correction(pvals);

end