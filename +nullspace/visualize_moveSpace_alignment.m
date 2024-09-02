function [f_resp, f_dim] = visualize_moveSpace_alignment(alignments, ops)


%%
f_resp=figure('Units', 'normalized', 'OuterPosition', [.3 .1 .1 .16]);

tf_resp_indexes = alignments.tfIndexes;
hold on;
pot_clrs  = flipud(cbrewer2('Greens', 2));
null_clrs = flipud(cbrewer2('Blues', 4));
set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin')
scatter(squeeze(tf_resp_indexes(1,1,:)), squeeze(tf_resp_indexes(1,2,:)), 70, '^', ...
        'markerfacecolor', pot_clrs(1,:), 'MarkerEdgeAlpha', 0, 'MarkerFaceAlpha', .4);
scatter(squeeze(tf_resp_indexes(2,1,:)), squeeze(tf_resp_indexes(2,2,:)), 70, 's', ...
        'markerfacecolor', null_clrs(1,:), 'MarkerEdgeAlpha', 0, 'MarkerFaceAlpha', .7);
scatter(squeeze(tf_resp_indexes(3,1,:)), squeeze(tf_resp_indexes(3,2,:)), 50, ...
        'markerfacecolor', null_clrs(3,:), 'MarkerEdgeAlpha', 0, 'MarkerFaceAlpha', .6);
xlabel(sprintf('TF index\nexp fast'))
ylabel(sprintf('TF index\nexp slow'))

%% dimension alignment - tf projected onto movespace
tf_cols = [ops.colors.F; ops.colors.S; .5 .5 .5];
f_dim=figure('Units', 'normalized', 'OuterPosition', [.3 .1 .1 .16]);
hold on
for iter = 1:size(alignments.dims,3)
    for tf_dim = 1:3
        quiver3(0, 0, 0, ...
                alignments.tf_dims_projected(2, tf_dim, iter), ...
                alignments.tf_dims_projected(3, tf_dim, iter), ...
                alignments.tf_dims_projected(1, tf_dim, iter), ...
                'color', tf_cols(tf_dim,:), 'LineWidth', .5)
    end
end
xlabel('Null 1')
ylabel('Null 2')
zlabel('Potent')
grid on
view([-64, 25])
% get(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin', 'ZAxisLocation', 'origin')
end