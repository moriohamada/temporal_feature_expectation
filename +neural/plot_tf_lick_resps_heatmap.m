function plot_tf_lick_resps_heatmap(avg_resps, t_ax, indexes, ops)
% 
% Plot PSTHs of all tf-responsive units, aligned to TF pulses and changes
% 
% --------------------------------------------------------------------------------------------------
%%
avg_resps = utils.match_FS_sds(avg_resps, indexes);
% select only tf responsive, good units
[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);
% use different tf sensitivity criteria here - we want to capture anything responsive to fast OR slow
 
tf_sensitive = (abs(indexes.tf_z_peakF)>2.58 | abs(indexes.tf_z_peakS)>2.58) & ...
                 sign(indexes.tf_short)==sign(indexes.tf_z_peakD);
 multi = utils.get_multi(avg_resps, indexes) ;
select = tf_sensitive & ~multi ;
areas = utils.group_rois_fine();

% before filtering out non tf-sesnstive units, store totals per location
total_n_per_loc = nan(height(areas),1);
for r = 1:length(areas)
    this_roi_areas = areas{r,2};
    in_area = utils.get_units_in_area(indexes.loc, this_roi_areas);
    total_n_per_loc(r) = sum(in_area & ~multi & ~isnan(tf_pref) & ~(tf_pref==0) );
end

inds  = indexes(select,:);
resps = avg_resps(select,:);

% sort by TF response peak time
% tfresp = smoothdata(resps.FexpF, 'movmean', 1) - smoothdata(resps.FexpS, 'movmean', 1);%resps.FexpF;
% bl_t = isbetween(t_ax.tf, ops.respWin.tfContext);
% pk_t = isbetween(t_ax.tf, ops.respWin.tf);
% [~,peak] = max(abs(tfresp(:,pk_t) - nanmean(tfresp(:,bl_t),2)),[],2);
% [~,order] = sort(peak, 'ascend');
[~, order] = sort(inds.tf_z_peakTimeD, 'ascend');
inds = inds(order,:);
resps = resps(order,:);

% sort by tf response preference sign
[~, order] = sort(sign(inds.tf_z_peakD), 'descend');
inds = inds(order,:);
resps = resps(order,:);

% sort by loc
locs = resps.loc;
units_by_loc = [];
units_per_loc = [];


for r = 1:length(areas)
    this_roi_areas = areas{r,2};
    in_area = utils.get_units_in_area(locs, this_roi_areas);
    units_by_loc = vertcat(units_by_loc, find(in_area));
    units_per_loc(end+1) = sum(in_area);
end
n_per_loc = cumsum(units_per_loc);
n_per_loc = [0, n_per_loc];

% sort again
resps = resps(units_by_loc,:);
inds = inds(units_by_loc,:);
conts = inds.conts;

nN = height(resps);
% avg_resps.FRsd = ones(height(avg_resps),1);

%% Plot

f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .3 .6]);

clim_tf = [-.5 .5];
clim_ch = [-5 5];

tlim_tf = [-.2 1];
tlim_ch = [-.2 1];
 
mu = resps.FRmu;
sd = resps.FRsd;

for ev = 1:4 % each event type: tf fast, tf slow, change fast, change slow
    if ev == 1
        X = (resps.FexpF + resps.FexpS)/2;
        cax = clim_tf;
        pre_norm_t = isbetween(t_ax.tf, ops.respWin.tfContext);
        tlim = tlim_tf;
        t = t_ax.tf;
    elseif ev == 2
        X = (resps.SexpF + resps.SexpS)/2;
        cax = clim_tf;
        pre_norm_t = isbetween(t_ax.tf, ops.respWin.tfContext);
        tlim = tlim_tf;
        t = t_ax.tf;
    elseif ev == 3
        X = resps.hitF;
        cax = clim_ch;
        pre_norm_t = isbetween(t_ax.ch, [-1 0]);
        tlim = tlim_ch;
        t = t_ax.ch;
    elseif ev == 4
        X = resps.hitS;
        cax = clim_ch;
        pre_norm_t = isbetween(t_ax.ch, [-1 0]);
        tlim = tlim_ch;
        t = t_ax.ch;
    end
    
    if ev==1 | ev==2 % TF pulse
        X = utils.detrend_resp(X, isbetween(t_ax.tf, [-.5 -.1]),isbetween(t_ax.tf, [1 1.5]));
    end
    % normalize
    X = (X-mu)./sd;
    mu_pre = nanmean(X(:,pre_norm_t),2);
    sd_pre  = nanstd(X(:, pre_norm_t),[],2);
    X = X-mu_pre;
%     X = (X-mu_pre)./sd_pre;
    
    
    % add a few blank lines between areas to separate
    X_locSep = [];
    tick_locs = [];
    spaces = 0;
    X = smoothdata(X, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);

    for ii = 1:length(n_per_loc)-1
        this_loc_X = smoothdata(X(n_per_loc(ii)+1:n_per_loc(ii+1), :), 2, 'movmean', 2);

        X_locSep = [X_locSep; ...
                    this_loc_X; ...
                    zeros(5,size(X,2))];
        tick_locs(end+1:end+2) =[ n_per_loc(ii), n_per_loc(ii+1)] + spaces;
        spaces = spaces + 5;
    end

    X = X_locSep;
    
    % smooth out time axis
    new_tax = linspace(t(1), t(end), length(t)*50);
    X_new = nan(size(X,1), size(X,2)*50);
    for ii=1:size(X,1)
        if ~all(isnan(X(ii,:)))
            X_new(ii,:) = interp1(t, X(ii,:), new_tax, 'cubic');
        end
    end
    X = X_new;
    
    % plot
    subplot(1,4,ev);
    hold on;
    
    % set transparency
    imalpha = ones(size(X));
    imalpha(isnan(X))=0;
    
    h = imagesc(X, 'alphadata', imalpha);
    h.XData = new_tax;
    
    % line at t=0
    line([0 0], [0 size(X,1)], 'color', [.4 .4 .4])
    
    % format axes
    xlim(tlim);
    xticks([0 1]);
    colormap(ops.colors.heatmap);
    caxis(cax);
    set(gca, 'ydir', 'reverse');
    cb = colorbar('northoutside'); 
    
    ax=gca;
    set(ax, 'box', 'off')
    ax.YAxis.Visible = 'on';
    ylim([1 size(X,1)+5])
    
    % label locs with ticks
    y_tick_locs = n_per_loc;
    for r = 2:length(n_per_loc)
        y_tick_locs(r) = n_per_loc(r) + 5*(r-2);
    end
    yticks(y_tick_locs(2:end))
    
    % set labels: count and percentage
    yt_labels = cell(length(n_per_loc)-1,1);
    for r = 1:length(n_per_loc)-1
        num_in_roi = total_n_per_loc(r);
        yt_labels{r} = sprintf('%s: %d (%.0f%s)', areas{r}, units_per_loc(r), 100*units_per_loc(r)/num_in_roi,'%');
    end
    if ev==1
        yticklabels(yt_labels)
    else
        yticklabels(units_per_loc);
    end
%     keyboard
end
% if ops.saveFigs
%     save_figures_multi_format(f, fullfile(ops.saveDir, 'neural', 'all_tf_responsive_heatmap'), {'fig', 'svg'})
% end
end