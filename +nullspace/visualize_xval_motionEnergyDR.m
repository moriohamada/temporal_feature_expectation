function f = visualize_xval_motionEnergyDR(projs_iters, ops)
%  visualize dimnesionality-reduced motion energy around hit licks and TF
%%
nIter = length(projs_iters);

f= figure('Units', 'normalized', 'OuterPosition', [.1 .1 .15 .1]);
%
% Plot licks
subplot(1,2,1); hold on
ch_clrs   = [flipud(cbrewer2('Blues', 3)); cbrewer2('Reds', 3)];

all_iter_projs = nan(nIter, length(projs_iters{1}.Mdr.hitLickE1));
t = linspace(-2,1,300);
for ee = 1:6
    ev = sprintf('hitLickE%d', ee);
    for iter = 1:nIter
        all_iter_projs(iter,:) = smoothdata(projs_iters{iter}.Mdr.(ev), 'movmean', [5 0]);
    end
    all_iter_projs = all_iter_projs - nanmean(all_iter_projs(:,isbetween(t,[-2 -1])),2);
    ci_95 = ci_95_bootstrapped(all_iter_projs,1); 
    plot(t, nanmean(all_iter_projs,1), 'color', ch_clrs(ee,:), 'linewidth', 1);
    shade_handle = fill([t, fliplr(t)], [ci_95(1,:), fliplr(ci_95(2,:))],  ch_clrs(ee,:), 'FaceAlpha', .2, 'EdgeColor', 'none');
end
yl = ylim;
% plot TF
subplot(1,2,2); hold on;
all_iter_projs = nan(nIter, length(projs_iters{1}.Mdr.FexpF));
tf_cats =  {'FexpF', 'FexpS', 'SexpF', 'SexpS'};
tf_clrs =[ops.colors.F; ops.colors.F*.6; ops.colors.S*.6; ops.colors.S];
t = linspace(-1,2,301);
for ee = 1:4
    ev = tf_cats{ee};
    for iter = 1:nIter
        all_iter_projs(iter,:) = smoothdata(projs_iters{iter}.Mdr.(ev), 'movmean', [5 0]);
    end
    all_iter_projs = all_iter_projs - nanmean(all_iter_projs(:,isbetween(t,[-1 -.5])),2);
    ci_95 = ci_95_bootstrapped(all_iter_projs,1); 
    plot(t, nanmean(all_iter_projs,1), 'color', tf_clrs(ee,:), 'linewidth', 1);
    shade_handle = fill([t, fliplr(t)], [ci_95(1,:), fliplr(ci_95(2,:))],  tf_clrs(ee,:), 'FaceAlpha', .2, 'EdgeColor', 'none');
    xlim([-.5 1]);
end
yltf = ylim;
ylim(yltf * (range(yl)/range(yltf))/15);
end