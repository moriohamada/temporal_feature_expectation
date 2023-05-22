function f = plot_glm_kernels(kernels, areas, ops)

%% first sort by region
%%
% randomly shuffle initially
kernels = kernels(randperm(height(kernels)),:);

% sort by resp
sig_tfe = kernels.TFbl_e_p < .025;
sig_tfl = kernels.TFbl_l_p < .025;

tf_kern_e = cell2mat(kernels.TFbl_e')';
tf_kern_e = mean(tf_kern_e(:,3:13),2)-nanmean(tf_kern_e(:,1:3),2); %0-750ms
tf_kern_l = cell2mat(kernels.TFbl_l')';
tf_kern_l = mean(tf_kern_l(:,3:13),2)-nanmean(tf_kern_l(:,1:3),2); %0-750ms

% sort by peak time
kern_e = smoothdata(cell2mat(kernels.TFbl_e')', 'movmean',[3 0]);

[~,peak]  = max(abs(kern_e(:,3:12) - mean(kern_e,2)),[],2);
[~,order] = sort(peak, 'ascend');

% get resp mag/sign
resp_mag = (tf_kern_e + tf_kern_l)/2;
[resp_mag, order] = sort(sign(resp_mag), 'descend');

kernels = kernels(order,:);
kernels.resp_mag_e = tf_kern_e(order);
kernels.resp_mag_l = tf_kern_l(order);
kernels.resp_mag   = resp_mag;

tf_resp_kernels = kernels(kernels.tf_p<.05 |( kernels.TFbl_e_p<.05 & kernels.TFbl_e_p<.05), :);

% sort by loc
locs = tf_resp_kernels.loc;
units_by_loc = [];
n_per_loc = [];
for r = 1:length(areas)
    this_roi_areas = areas{r};

    in_area = contains(locs, this_roi_areas);
    units_by_loc = vertcat(units_by_loc, sort(find(in_area)));
    n_per_loc(end+1) = sum(in_area);
end
n_per_loc = cumsum(n_per_loc);
n_per_loc = [0, n_per_loc];
% sort again
tf_resp_kernels = tf_resp_kernels(units_by_loc,:);

%% plot TF, baseline, lick kernels for tf sensitive

f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .1 .4]);

% tf resps
subplot(1,2,1); hold on

% choices = randi(2, size(X,1),1);

X = cell2mat(tf_resp_kernels.TFbl_e')';
% X = X(:,sub2ind(size(X), 1:size(X,1) , 1:size(X,2), choices))

% X = X./nanstd(X,[],2);

X_locSep = [];
for ii = 1:length(n_per_loc)-1
    this_loc_X = smoothdata(X(n_per_loc(ii)+1:n_per_loc(ii+1),:), 2, 'movmean', [2 1]);
    X_locSep = [X_locSep; ...
                this_loc_X; ...
                zeros(5, size(X,2))];
    
end
X = X_locSep;
X = (X-nanmean(X,2))./nanstd(X,[],2);

imAlpha = ones(size(X));
imAlpha(isnan(X)) = 0;
h=imagesc(X(:,[1:end]), 'alphadata', imAlpha(:,[1:end]));

h.XData = [-.15:.05:2];
line([0 0], [0 size(X,1)], 'color', [.4 .4 .4])
caxis([-1.5 1.5]) 
xlim([-.1 1.5])
colormap(RedWhiteBlue)
xticks([0 1])
xticklabels([0 1])
ax = gca;
set(ax, 'YDir', 'reverse', 'box', 'off')
ax.YAxis.Visible = 'off';
ylim([0 size(X,1)+1])

% tf resps
subplot(1,2,2)

X = cell2mat(tf_resp_kernels.TFbl_l')';
% X = X./nanstd(X(:,20:30),[],2);

X_locSep = [];
for ii = 1:length(n_per_loc)-1
    this_loc_X = smoothdata(X(n_per_loc(ii)+1:n_per_loc(ii+1),:), 2, 'movmean', [2 1]);
    X_locSep = [X_locSep; ...
                this_loc_X; ...
                zeros(5, size(X,2))];
    
end
X = X_locSep;


X = (X-nanmean(X,2))./nanstd(X,[],2);

imAlpha = ones(size(X));
imAlpha(isnan(X)) = 0;
h=imagesc(-X(:,2:end), 'alphadata', imAlpha(:,2:end));
h.XData = [-.1:.05:2];
line([0 0], [0 size(X,1)], 'color', [.4 .4 .4])
caxis([-1.5 1.5]) 
xlim([-.1 1.5])
colormap(RedWhiteBlue)
ax = gca;
set(ax, 'YDir', 'reverse', 'box', 'off')
ax.YAxis.Visible = 'off';
ylim([0 size(X,1)+1])
xticks([0 1])
xticklabels([0 1])

% 
% 
% % baseline
% 
% subplot(1,3,2)
% 
% X = [cell2mat(tf_resp_kernels.baselineOnset')', cell2mat(tf_resp_kernels.baseline')'];
% X_locSep = [];
% X = X./nanstd(X,[],2);
% 
% for ii = 1:length(n_per_loc)-1
%     this_loc_X = smoothdata(X(n_per_loc(ii)+1:n_per_loc(ii+1),:), 2, 'movmean', [3 0]);
%     X_locSep = [X_locSep; ...
%                 this_loc_X; ...
%                 zeros(5, size(X,2))];
%     
% end
% X = X_locSep;
% imagesc(X)
% caxis([-1 1])
% xlim([0 30])
% colormap(RedWhiteBlue)
% 
% % lick
% 
% subplot(1,2,2)
% 
% X = cell2mat(tf_resp_kernels.Lick')';
% % X = X./nanstd(X,[],2);
% 
% X_locSep = [];
% for ii = 1:length(n_per_loc)-1
%     this_loc_X = smoothdata(X(n_per_loc(ii)+1:n_per_loc(ii+1),:), 2, 'movmean', [3 0]);
%     X_locSep = [X_locSep; ...
%                 this_loc_X; ...
%                 zeros(5, size(X,2))];
%     
% end
% X = X_locSep;
% 
% imagesc(X)
% caxis([-.5 .5])
% xlim([size(X,2)-20, size(X,2)])
% colormap(RedWhiteBlue)

end