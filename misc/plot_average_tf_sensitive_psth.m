function f = plot_average_tf_sensitive_psth(resps, t_ax, indexes, areas, ops)
% 
% Plot baseline activity and tf responses (early and late) of TF-sensitive units
% 
% --------------------------------------------------------------------------------------------------
%%
% keyboard

sm = ops.spSmoothSize/ops.spBinWidth;
resps.FRsd = resps.FRsd * ops.spBinWidth/1000;

%%


tf_idx = indexes.tf_short;% .* conts;
conts = indexes.conts;

% yls = [-3 5; -4 4; -6 8]; % for coarse area split
yls = [-3 5; -3 5; -3 5; -3 5; -4 4; -6 8; -6 8]; % for fine split

for r = 1:length(areas)
    
    f{r} = figure('Units', 'normalized', 'OuterPosition', [.1+r*.1 .1 .05 .25]);
    yl = yls(r,:);
    
    in_area = contains(resps.loc, areas{r});
    
        
    if r<=2
        fast = tf_idx<0;
        slow = tf_idx>0;
    else
        fast = tf_idx>0;
        slow = tf_idx<0;
    end
    % rescale
    respsF = resps(fast & in_area,:);
    respsS = resps(slow & in_area,:);
    
    
%     if r <= 2
%     psthF   = nanmean(smoothdata((respsF.hitS - respsF.FRmu)./respsF.FRsd, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]),1);
%     psthS   = nanmean(smoothdata((respsS.hitF - respsS.FRmu)./respsS.FRsd, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]),1);
%     else
    psthF   = nanmean(smoothdata((respsF.hitF - respsF.FRmu)./respsF.FRsd, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]),1);
    psthS   = nanmean(smoothdata((respsS.hitS- respsS.FRmu)./respsS.FRsd, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]),1);
%     end
    psthF   = psthF(isbetween(t_ax.ch, [-.4 .4]));
    psthS   = psthS(isbetween(t_ax.ch, [-.4 .4]));
%     psthF   = psthF(isbetween(t_ax.tf, [-.3 .3]));
%     psthS   = psthS(isbetween(t_ax.tf, [-.3 .3]));
%     if r >2
    scale_F = range(psthS)/range(psthF);
%     else
%         scale_F=1;
%     end
    
    % baseline
    subplot(3, 2, [1 2]); hold on
    X = smoothdata((resps.bl - resps.FRmu)./resps.FRsd, 2, 'gaussian', 5*(sm*5));%.*conts;
    X(isinf(X)) = nan;
    X = X(:,isbetween(t_ax.bl, [1 10]));
    t_bl = t_ax.bl(isbetween(t_ax.bl,[1 10]));
    if r<=1
        X(conts==1,:) = fliplr(X(conts==1,:));
    else
        X(conts==-1,:) = fliplr(X(conts==-1,:));
    end
    X(fast,:) = X(fast,:)*scale_F;
    shadedErrorBar(t_bl, smoothdata(nanmean(X(in_area & fast,:),1),'movmean',sm), smoothdata(1.95*nanStdError(X(in_area & fast,:),1), 'movmean', sm), ...
                   'patchsaturation', .2, 'lineprops', {'color', ops.colors.F_pref, 'linewidth', 1.5})
    shadedErrorBar(t_bl, smoothdata(nanmean(X(in_area & slow,:),1), 'movmean', sm), smoothdata(1.95*nanStdError(X(in_area & slow,:),1), 'movmean', sm), ...
                   'patchsaturation', .2, 'lineprops', {'color', ops.colors.S_pref, 'linewidth', 1.5})
    xlim([1 10])
    ylim(yl/1.5)
    offsetAxes
    % TF 
    if r<=2
        tf_types = {'SexpS', 'SexpF', 'FexpS', 'FexpF'};
    else
        tf_types = {'FexpF', 'FexpS', 'SexpF', 'SexpS'};
    end
    for ii = 1:length(tf_types)
       tf_type = tf_types{ii};
       X = smoothdata((resps.(tf_type) - resps.FRmu)./resps.FRsd, 2, 'movmean', [sm 0]);
       X(fast,:) = X(fast,:) * scale_F;
       X = detrend_resp(X, isbetween(t_ax.tf, [-.4 -.1]), isbetween(t_ax.tf, [.7 1.2]));
       subplot(3,2,2+ii); hold on
       shadedErrorBar(t_ax.tf, nanmean(X(in_area & fast,:),1), ci_95_magnitude(X(in_area & fast,:),1), ...
                      'lineprops', {'color', ops.colors.F_pref, 'linewidth', 1.5})
       shadedErrorBar(t_ax.tf, nanmean(X(in_area & slow,:),1), ci_95_magnitude(X(in_area & slow,:),1), ...
                      'lineprops', {'color', ops.colors.S_pref, 'linewidth', 1.5})
       xlim([-.5 1])
       ylim(yl)
%        set(gca, 'ycolor', 'none')
       if ii<=2
           plot([0 0], yl, 'color', ops.colors.F, 'linewidth', .5)
       else
           plot([0 0], yl, 'color', ops.colors.S, 'linewidth', .5)
       end
       offsetAxes
    end
    
end

% align y ax


end