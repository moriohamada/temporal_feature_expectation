function f_tf = plot_average_time_tf_sensitive_response(resps, t_ax, indexes, areas, ops)
% 
% Plot mean activity of F/S preferring units and E/L preferring units to TF pulses & time
% 
% --------------------------------------------------------------------------------------------------

%%
off = [.1 .1 -.1];
% off_early = [.2 .05 -.1];
% first shuffle around all cells so there arent weird correlations
shuffle = randperm(height(indexes));
resps = resps(shuffle,:);
indexes = indexes(shuffle,:);

% sort units by region
locs = resps.loc;
units_by_loc = [];
n_per_loc = [];
for r = 1:length(areas)
    this_roi_areas = areas{r};

    in_area = contains(resps.loc, this_roi_areas);
    units_by_loc = vertcat(units_by_loc, find(in_area));
    n_per_loc(end+1) = sum(in_area);
end
n_per_loc = cumsum(n_per_loc);
n_per_loc = [0, n_per_loc];

% sort again
resps = resps(units_by_loc,:);
indexes = indexes(units_by_loc,:);
conts = indexes.conts;

% indexes.timeBL = indexes.timeBL .* indexes.conts;
nN = height(resps);

resps.FRsd = resps.FRsd * ops.spBinWidth/1000;
%% Fast slow split
% 
% resps.FRmu = nanmean(resps.bl(:,isbetween(t_ax.bl, [1 11])),2);
% resps.FRsd = nanstd(resps.bl(:,isbetween(t_ax.bl, [1 11])),[],2);
f_tf = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .2 .35]);

yl = [-3 3];
sm = [20 20];
for r = 1:length(areas)
    
    this_area_idx = n_per_loc(r)+1:n_per_loc(r+1);
    in_area = logical(zeros(size(resps.bl,1),1));
    in_area(this_area_idx) = 1;
    fast  = indexes.tf_short > 0;
    slow  = indexes.tf_short < 0;
    
    % need to flip  base!
   
    % baseline
    subplot(length(areas), 6, (r-1)*6+[1 2]); hold on
    X = smoothdata((resps.bl - resps.FRmu)./resps.FRsd, 2, 'movmean', [50 50]);%.*conts;
    X(isinf(X)) = nan;
    X = X.*conts;
    shadedErrorBar(t_ax.bl, smoothdata(nanmean(X(in_area & fast,:),1),'movmean',sm), smoothdata(nanStdError(X(in_area & fast,:),1), 'movmean', sm), ...
                   'patchsaturation', .1, 'lineprops', {'color', ops.colors.F_pref})
    shadedErrorBar(t_ax.bl, smoothdata(nanmean(X(in_area & slow,:),1), 'movmean', sm), smoothdata(nanStdError(X(in_area & slow,:),1), 'movmean', sm), ...
                   'patchsaturation', .1, 'lineprops', {'color', ops.colors.S_pref})
    xlim([2 10])
    ylim([-.5 .5])
%     set(gca, 'YColor', 'none')
    offsetAxes
    % fast early outlier
    subplot(length(areas), 6, (r-1)*6+3); hold on
    X = (resps.FexpF - resps.FRmu) ./ resps.FRsd;
    X(isinf(X)) = nan;
%     X = X.*conts;

%     X = smoothdata(X, 2, 'movmean', sm);
    shadedErrorBar(t_ax.tf, nanmean(X(in_area & fast,:),1), nanStdError(X(in_area & fast,:),1), ...
                   'patchsaturation', .1,'lineprops', {'color', ops.colors.F_pref})
    shadedErrorBar(t_ax.tf, nanmean(X(in_area & slow,:),1), nanStdError(X(in_area & slow,:),1), ...
                   'patchsaturation', .1,'lineprops', {'color', ops.colors.S_pref})
    plot([0 0], yl, 'color', 'r')
    xlim([-.2 .6])
    ylim([yl])
    set(gca, 'YColor', 'none')

    % slow early outlier
    subplot(length(areas), 6, (r-1)*6+5); hold on
    X = (resps.SexpF - resps.FRmu) ./ resps.FRsd;
%     X = smoothdata(X, 2, 'movmean', sm);
    X(isinf(X)) = nan;
%     X = X.*conts;

    shadedErrorBar(t_ax.tf, nanmean(X(in_area & fast,:),1), nanStdError(X(in_area & fast,:),1), ...
                   'patchsaturation', .1,'lineprops', {'color', ops.colors.F_pref})
    shadedErrorBar(t_ax.tf, nanmean(X(in_area & slow,:),1), nanStdError(X(in_area & slow,:),1), ...
                   'patchsaturation', .1,'lineprops', {'color', ops.colors.S_pref})
    plot([0 0], yl, 'color', 'b')
    xlim([-.2 .6])
    ylim([yl])
    set(gca, 'YColor', 'none')

    % fast late outlier
    subplot(length(areas), 6, (r-1)*6+4); hold on
    X = (resps.FexpS - resps.FRmu) ./ resps.FRsd;
        X(isinf(X)) = nan;
%     X = X.*conts;

%     X = smoothdata(X, 2, 'movmean', sm);

    shadedErrorBar(t_ax.tf, nanmean(X(in_area & fast,:),1)+off(r), nanStdError(X(in_area & fast,:),1), ...
                   'patchsaturation', .1,'lineprops', {'color', ops.colors.F_pref})
    shadedErrorBar(t_ax.tf, nanmean(X(in_area & slow,:),1)-off(r), nanStdError(X(in_area & slow,:),1), ...
                    'patchsaturation', .1,'lineprops', {'color', ops.colors.S_pref})
    plot([0 0], yl,'color', 'r')
    xlim([-.2 .6])
    ylim([yl])
    set(gca, 'YColor', 'none')
    
    % slow late outlier
    subplot(length(areas), 6, (r-1)*6+6); hold on
    X = (resps.SexpS - resps.FRmu) ./ resps.FRsd;
        X(isinf(X)) = nan;
%     X = X.*conts;
% 
%     X = smoothdata(X, 2, 'movmean', sm);

    shadedErrorBar(t_ax.tf, nanmean(X(in_area & fast,:),1)+off(r), nanStdError(X(in_area & fast,:),1), ...
                   'patchsaturation', .1,'lineprops', {'color', ops.colors.F_pref})
    shadedErrorBar(t_ax.tf, nanmean(X(in_area & slow,:),1)-off(r), nanStdError(X(in_area & slow,:),1), ...
                   'patchsaturation', .1, 'lineprops', {'color', ops.colors.S_pref})
    plot([0 0], yl, 'color', 'b')

    xlim([-.2 .6]) 
    ylim([yl])
    set(gca, 'YColor', 'none')
end
% 
% %% early late split
% 
% 
% f_time = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .2 .35]);
% 
% for r = 1:length(areas)
%     
%     this_area_idx = n_per_loc(r)+1:n_per_loc(r+1);
%     in_area = logical(zeros(size(resps.bl,1),1));
%     in_area(this_area_idx) = 1;
% %     fast  = indexes.tfExpF > 0;
% %     slow  = indexes.tfExpS < 0;
%     if r == 1
%         early = indexes.timeBL < -.1;
%         late  = indexes.timeBL > 0.1;
%     else
%         early = indexes.timeBL < 0;
%         late  = indexes.timeBL > 0;
%     end
%     
%     % baseline
%     subplot(length(areas), 8, (r-1)*8+[1 2]); hold on
%     X = (resps.bl - resps.FRmu)./resps.FRsd;
%     shadedErrorBar(t_ax.bl, nanmean(X(in_area & early,:),1), nanStdError(X(in_area & early,:),1), ...
%                    'lineprops', {'color', ops.colors.F_pref})
%     shadedErrorBar(t_ax.bl, nanmean(X(in_area & late,:),1), nanStdError(X(in_area & early,:),1), ...
%                    'lineprops', {'color', ops.colors.S_pref})
%     xlim([-1 10])
%     ylim([yl])
%     
%     % early early outlier
%     subplot(length(areas), 6, (r-1)*6+3); hold on
%     X = (resps.FexpF - resps.FRmu) ./ resps.FRsd;
%     shadedErrorBar(t_ax.tf, nanmean(X(in_area & early,:),1), nanStdError(X(in_area & early,:),1), ...
%                    'lineprops', {'color', ops.colors.F_pref})
%     shadedErrorBar(t_ax.tf, nanmean(X(in_area & late,:),1), nanStdError(X(in_area & early,:),1), ...
%                    'lineprops', {'color', ops.colors.S_pref})
%     plot([0 0], yl, 'color', 'r')
%     xlim([-.2 .6])
%     ylim([yl])
%     
%     % late early outlier
%     subplot(length(areas), 6, (r-1)*6+4); hold on
%     X = (resps.SexpF - resps.FRmu) ./ resps.FRsd;
%     shadedErrorBar(t_ax.tf, nanmean(X(in_area & early,:),1), nanStdError(X(in_area & early,:),1), ...
%                    'lineprops', {'color', ops.colors.F_pref})
%     shadedErrorBar(t_ax.tf, nanmean(X(in_area & late,:),1), nanStdError(X(in_area & early,:),1), ...
%                    'lineprops', {'color', ops.colors.S_pref})
%     plot([0 0], yl, 'color', 'b')
%     xlim([-.2 .6])
%     ylim([yl])
%     % early late outlier
%     subplot(length(areas), 6, (r-1)*6+5); hold on
%     X = (resps.FexpS - resps.FRmu) ./ resps.FRsd;
%     shadedErrorBar(t_ax.tf, nanmean(X(in_area & early,:),1), nanStdError(X(in_area & early,:),1), ...
%                    'lineprops', {'color', ops.colors.F_pref})
%     shadedErrorBar(t_ax.tf, nanmean(X(in_area & late,:),1), nanStdError(X(in_area & early,:),1), ...
%                    'lineprops', {'color', ops.colors.S_pref})
%     plot([0 0], yl, 'color', 'r')
%     xlim([-.2 .6])
%     ylim([yl])
%     % late late outlier
%     subplot(length(areas), 6, (r-1)*6+6); hold on
%     X = (resps.SexpS - resps.FRmu) ./ resps.FRsd;
%     shadedErrorBar(t_ax.tf, nanmean(X(in_area & early,:),1), nanStdError(X(in_area & early,:),1), ...
%                    'lineprops', {'color', ops.colors.F_pref})
%     shadedErrorBar(t_ax.tf, nanmean(X(in_area & late,:),1), nanStdError(X(in_area & early,:),1), ...
%                    'lineprops', {'color', ops.colors.S_pref})
%                    plot([0 0], yl, 'color', 'b')
% 
%     xlim([-.2 .6]) 
%     ylim([yl])
% end



end


