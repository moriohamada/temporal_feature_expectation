function [f_resp, f_dim] = visualize_moveSpace_alignment(alignments, ops)


%%
f_resp=figure('Units', 'normalized', 'OuterPosition', [.3 .1 .1 .16]);

tf_resp_indexes = alignments.tfIndexes  - alignments.tfIndexes_control;
hold on;
pot_clrs  = flipud(cbrewer2('Greens', 2));
% null_clrs = flipud(cbrewer2('Blues', 4));
null_clrs = [[196 146 186]/255; [238 181 120]/255];
mov_clrs = [pot_clrs(1,:); null_clrs];
set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin')
scatter(squeeze(tf_resp_indexes(2,1,:)), squeeze(tf_resp_indexes(2,2,:)), 30, 's', ...
        'markerfacecolor', null_clrs(1,:), 'MarkerEdgeAlpha', 0, 'MarkerFaceAlpha', .2);
scatter(squeeze(tf_resp_indexes(3,1,:)), squeeze(tf_resp_indexes(3,2,:)), 30, ...
        'markerfacecolor', null_clrs(2,:), 'MarkerEdgeAlpha', 0, 'MarkerFaceAlpha', .3);
scatter(squeeze(tf_resp_indexes(1,1,:)), squeeze(tf_resp_indexes(1,2,:)), 30, '^', ...
        'markerfacecolor', pot_clrs(1,:), 'MarkerEdgeAlpha', 0, 'MarkerFaceAlpha', .2);
    
% add averages + 95% confidence intervals
cols = [pot_clrs(1,:); null_clrs(1:2,:)];
shps = {'^', 's', 'o'};
sz = [30, 50, 30];
for mot_dim = 1:3
    vert_ci = prctile(squeeze(tf_resp_indexes(mot_dim,2,:)), [2.5, 97.5]);
    horz_ci = prctile(squeeze(tf_resp_indexes(mot_dim,1,:)), [2.5, 97.5]);
    vert_mu = mean(squeeze(tf_resp_indexes(mot_dim,2,:)));
    horz_mu = mean(squeeze(tf_resp_indexes(mot_dim,1,:)));
    plot([horz_mu, horz_mu], vert_ci, '-k');
    plot(horz_ci, [vert_mu vert_mu], '-k');
    % diagonal ci
%     keyboard
    ci_diag = prctile(squeeze(tf_resp_indexes(mot_dim,1,:))-squeeze(tf_resp_indexes(mot_dim,2,:)), [2.5, 97.5]);
    plot(horz_mu+ci_diag/sqrt(2)-(horz_mu-vert_mu)/sqrt(2), vert_mu-ci_diag/sqrt(2)-(vert_mu-horz_mu)/sqrt(2), '-k')
    scatter(horz_mu, vert_mu, sz(mot_dim), shps{mot_dim}, ...
            'markerfacecolor', cols(mot_dim,:), 'markerfacealpha', 1, ...
            'markeredgecolor', 'k', 'markeredgealpha', 1)
end
xl = xlim; yl = ylim;
% plot([-1 1], [-1 1], '-k');
xlim(xl); ylim(yl);
xlabel(sprintf('TF index\nexp fast'))
ylabel(sprintf('TF index\nexp slow'))
%%
% keyboard

%% dimension alignment - tf projected onto movespace
tf_cols = [ops.colors.F_pref; ops.colors.S_pref; .5 .5 .5];
f_dim=figure('Units', 'normalized', 'OuterPosition', [.3 .3 .1 .16]);
hold on
for iter = 1:10:size(alignments.dims,3)
    for tf_dim = 1:3
        quiver3(0, 0, 0, ...
                alignments.tf_dims_projected(2, tf_dim, iter), ...
                alignments.tf_dims_projected(3, tf_dim, iter), ...
                alignments.tf_dims_projected(1, tf_dim, iter), ...
                'color', tf_cols(tf_dim,:), 'LineWidth', .5)
%         scatter3(alignments.tf_dims_projected(2, tf_dim, iter), ...
%                 alignments.tf_dims_projected(3, tf_dim, iter), ...
%                 alignments.tf_dims_projected(1, tf_dim, iter), ...
%                 20, 'MarkerFaceColor', tf_cols(tf_dim,:), 'MarkerEdgeAlpha', 0)
    end
end
% for tf_dim = 1:3
%     quiver3(0, 0, 0, ...
%             mean(alignments.tf_dims_projected(2, tf_dim, :),3), ...
%             mean(alignments.tf_dims_projected(3, tf_dim, :),3), ...
%             mean(alignments.tf_dims_projected(1, tf_dim, :),3), ...
%             'color', tf_cols(tf_dim,:), 'LineWidth', 1.5);
% end
xlabel('Null 1')
ylabel('Null 2')
zlabel('Potent')
grid on
% view([-64, 25])
view([-31.5, 12])
% view([-88, 15])
% get(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin', 'ZAxisLocation', 'origin')

%% Mov dims on F/S



%% Quantify extent of alignment 

dim_cos = nan(2,3,size(alignments.dims,3)); %F/S vs null 1/2
dim_cos_cntrl = nan(2,3,size(alignments.dims,3));
for mov_dim = 1:3 %null 1/2
    for tf_dim = 1:2 % F/S/M
        dim_cos(mov_dim, tf_dim, :) = alignments.dims(mov_dim, tf_dim+3,:) - alignments.dims_control(mov_dim, tf_dim+3, :);
        dim_cos_cntrl(mov_dim, tf_dim, :) = alignments.dims_control(mov_dim, tf_dim+3,:);% - alignments.dims_control(mov_dim, tf_dim+3, :);

    end
end


% for mov_dim = 1:2 %null 1/2
%     for tf_dim = 1:2 % F/S/M
%         dim_proj(mov_dim, tf_dim, :) = alignments.tf_dims_projected(mov_dim+1, tf_dim,:);
%     end
% end

f_dim=figure('Units', 'normalized', 'OuterPosition', [.5 .3 .2 .16]);
subplot(1,2,1)
hold on
for mov_dim = 1:3
    scatter(dim_cos(mov_dim,1,:), dim_cos(mov_dim,2,:), sz(mov_dim), shps{mov_dim}, ...
            'MarkerFaceColor', mov_clrs(mov_dim,:), 'MarkerFaceAlpha', .2, ...
            'MarkerEdgeAlpha', 0);
end
for mov_dim = 1:3
    vert_ci = prctile(squeeze(dim_cos(mov_dim,2,:)), [2.5, 97.5]);
    horz_ci = prctile(squeeze(dim_cos(mov_dim,1,:)), [2.5, 97.5]);
    vert_mu = mean(squeeze(dim_cos(mov_dim,2,:)));
    horz_mu = mean(squeeze(dim_cos(mov_dim,1,:)));
    plot([horz_mu, horz_mu], vert_ci, '-k');
    plot(horz_ci, [vert_mu vert_mu], '-k');
    scatter(horz_mu, vert_mu, sz(mov_dim), shps{mov_dim}, ...
            'markerfacecolor', cols(mov_dim,:), 'markerfacealpha', 1, ...
            'markeredgecolor', 'k', 'markeredgealpha', 1)
end
set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin')
xl = xlim; yl = ylim;
subplot(1,2,2);
hold on
for mov_dim = 1:3
    scatter(dim_cos_cntrl(mov_dim,1,:), dim_cos_cntrl(mov_dim,2,:), sz(mov_dim), shps{mov_dim}, ...
            'MarkerFaceColor', mov_clrs(mov_dim,:), 'MarkerFaceAlpha', .6, ...
            'MarkerEdgeAlpha', 0);
end
set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin')
xlim(xl); ylim(yl);
%%
% %% dimension alignment control - tf projected onto movespace
% tf_cols = [ops.colors.F; ops.colors.S; .5 .5 .5];
% f_dim=figure('Units', 'normalized', 'OuterPosition', [.3 .3 .1 .16]);
% hold on
% % for iter = 1:size(alignments.dims,3)
%     for tf_dim = 1:3
%         quiver3(0, 0, 0, ...
%                 mean(alignments.tf_dims_projected_control(2, tf_dim, :),3), ...
%                 mean(alignments.tf_dims_projected_control(3, tf_dim, :),3), ...
%                 mean(alignments.tf_dims_projected_control(1, tf_dim, :),3), ...
%                 'color', tf_cols(tf_dim,:), 'LineWidth', .5)
%     end
% % end
% xlabel('Null 1')
% ylabel('Null 2')
% zlabel('Potent')
% grid on
% view([-64, 25])
% title('control dims')
end