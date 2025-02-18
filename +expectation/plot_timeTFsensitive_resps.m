function plot_timeTFsensitive_resps(avg_resps, t_ax, indexes, ops)
% 
% Plot heatmaps all all time & tf sensitive units
% 
% --------------------------------------------------------------------------------------------------
%%

% select only good units
multi = utils.get_multi(avg_resps, indexes);

rois = utils.group_rois;
% rois = rois([1 3],:);
[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);
[time_sensitive, time_pref] = utils.get_time_pref(indexes);
time_pref = indexes.timeBL;
%% Sort units by time
selection = ~multi & tf_sensitive & abs(indexes.timeBL)>0.025;
resps = avg_resps(selection, :);
inds  = indexes(selection, :);
time_pref = time_pref(selection);
[~, order] = sort(time_pref, 'ascend');
% [~, order] = sort(tf_pref(selection), 'descend');

resps = resps(order,:);
inds  = inds(order,:);

% sort units again, by region
locs = inds.loc;
units_by_loc = [];
n_per_loc = [];
for r = 1:height(rois)
    this_roi_areas = rois{r,2};

    in_area = utils.get_units_in_area(locs, this_roi_areas);
    units_by_loc = vertcat(units_by_loc, find(in_area));
    n_per_loc(end+1) = sum(in_area);
end
n_per_loc = cumsum(n_per_loc);
n_per_loc = [0, n_per_loc];

resps = resps(units_by_loc,:);
inds  = inds(units_by_loc,:);
conts = inds.conts;

%% Plot heatmaps

f = figure('Units', 'normalized', 'OuterPosition', [.1 .3 .1 .3]);

%% baseline activity

relt=isbetween(t_ax.bl(1:end-1), [-1 12]);
bl_resp = resps.bl(:,relt); 
X = (bl_resp - resps.FRmu)./resps.FRsd;
X = (X - nanmean(X,2));%./nanstd( (X),[],2);
X(conts==-1,:) = -(X(conts==-1,:));
 % add blank lines between areas
X_locSep = [];
for ii = 1:length(n_per_loc)-1
    this_loc_X = smoothdata(X(n_per_loc(ii)+1:n_per_loc(ii+1), :), 2, 'movmean',  [50 0]);

    X_locSep = [X_locSep; ...
                this_loc_X; ...
                zeros(10,size(X,2))];
end
X=X_locSep;


% smooth out time axis
t = t_ax.bl(relt);
new_tax = linspace(t(1), t(end), length(t)*50);
X_new = nan(size(X,1), size(X,2)*50);
for ii=1:size(X,1)
    if ~all(isnan(X(ii,:)))
        X_new(ii,:) = interp1(t, X(ii,:), new_tax, 'cubic');
    end
end
X = X_new;

imAlpha = ones(size(X));
imAlpha(isnan(X)) = 0;
 
subplot(1, 3, [1 2])
h=imagesc(X, 'alphadata', imAlpha);
h.XData = t_ax.bl(relt);
colormap(ops.colors.heatmap);
set(gca, 'ydir', 'reverse');
ax=gca;
set(ax, 'box', 'off') 
diff_n = diff(n_per_loc);
yticks([1 n_per_loc(2) n_per_loc(2)+10 n_per_loc(3)+10 ])
yticklabels([1 diff_n(1) 1 diff_n(2)  ])
 
ylim([0 size(X,1)+1])
xlabel(sprintf('Time from \nbaseline onset (s)'));
caxis([-1 1])

colorbar;
xlim([2 10])
xticks([0 11])

%% TF resps - F-S

X = ((resps.FexpF - resps.SexpF) + (resps.FexpS - resps.SexpS))/2;
X = X./resps.FRsd;
% flip eslf animals
% X(inds.conts==-1,:) = -1 * X(inds.conts==-1,:);
relt=isbetween(t_ax.tf, [-.2 1]);
X = utils.remove_baseline(X, isbetween(t_ax.tf, ops.respWin.tfContext));
% add blank lines between areas
X_locSep = [];
for ii = 1:length(n_per_loc)-1
    this_loc_X = smoothdata(X(n_per_loc(ii)+1:n_per_loc(ii+1), :), 2, ...
                            'movmean', 5*ops.spSmoothSize/ops.spBinWidth);
    X_locSep = [X_locSep; ...
                this_loc_X/(std(this_loc_X(:))/nanstd(X(:))); ... % to visualize across areas
                zeros(10,size(X,2))];
end
X=X_locSep;

imAlpha = ones(size(X));
imAlpha(isnan(X)) = 0;
 
subplot(1, 3, 3)
h=imagesc(X, 'alphadata', imAlpha);
h.XData = t_ax.tf(relt);
xlim(minmax(t_ax.tf(relt)));
colormap(ops.colors.heatmap);
set(gca, 'ydir', 'reverse');
% caxis([-5 5])
ax=gca;
set(ax, 'box', 'off') 
diff_n = diff(n_per_loc);
yticks([1 n_per_loc(2) n_per_loc(2)+10 n_per_loc(3)+10])
yticklabels([1 diff_n(1) 1 diff_n(2)])
 
ylim([0 size(X,1)+1])
xlabel(sprintf('Time from \nTF pulse (s)'));
% colorbar;
caxis([-.35 .35])
xticks([0 .6])

if ops.saveFigs
save_figures_multi_format(f, fullfile(ops.saveDir, 'expectation', ['tfBL_responses_heatmap', rois{r,1}]), {'fig', 'svg', 'png', 'pdf'})
end

end