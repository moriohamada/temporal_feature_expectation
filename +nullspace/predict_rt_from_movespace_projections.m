function [f_quant, f_traj] = predict_rt_from_movespace_projections(projs_iters_aligned, t_ax_resps, ops)
%%
% dims  = fields(projs_iters_aligned{1});
dims = {'movement_potent', 'movement_null1', 'movement_null2', 'tf_fast', 'tf_slow'};
nIter = length(projs_iters_aligned);

proj_mag = nan(numel(dims), 2, 2, nIter); % F/S, short/long

resp_ids = isbetween(t_ax_resps.ch, [-.5 0]);

% tfs = [5 6 ; 2 3]; % works
tfs = [5 6 7; 1 2 3]; 
% all changes works
rts = {'short', 'long'};

for dd = 1:length(dims)
    dim = dims{dd};
    for iter = 1:nIter
        
        for tfi = 1:height(tfs)
            for rti = 1:length(rts)
                proj_val = 0;
                for ii = 1:width(tfs)
                    proj_val = mean(projs_iters_aligned{iter}.(dim). ...
                                (sprintf('hitE%s%d', rts{rti}, tfs(tfi,ii)))(resp_ids)) + proj_val;
                end 
                proj_mag(dd, tfi, rti, iter) = proj_val/width(tfs);
            end
        end
    end
end

%% Plot
% keyboard
cols = [ops.colors.F; ops.colors.S];
f_quant = figure('Units', 'normalized', 'OuterPosition', [.3 .1 .18 .2]);

for dd = 1:length(dims)
    subplot(1,length(dims),dd)
    hold on
    for tfi = 1:height(tfs) % fast, slow
        diffs = squeeze(proj_mag(dd, tfi, 1, :) - proj_mag(dd, tfi, 2, :));
%         violinPlot(diffs, 'showMM', 0,  'xValues', tfi+.6, ...
%               'color',mat2cell(cols(tfi,:), 1), 'histopt', 1, 'histori', 'right', 'divFactor', 1 );
        
        
        % scatter individual points
        % scatter individual points
        if tfi==2
            rand_x = tfi+.35+rand(nIter,1)*.3;
        else
            rand_x = tfi-.35-rand(nIter,1)*.3;
        end
        scatter(rand_x, diffs, 12, 'o', 'MarkerFaceColor', cols(tfi,:), 'markerfacealpha', .2, ...
                                        'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', 0)
%         for ii = 1:nIter
%             scatter(tfi+.35+rand*.3,diffs(ii), 12, 'o', ...
%                 'MarkerFaceColor', cols(tfi,:), 'markerfacealpha', .2, 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', 0)
%         end
        
        % scatter median and 95% ci
        plot([tfi tfi], prctile(diffs, [2.5 92.5]), '-k')
        scatter(tfi, nanmean(diffs), 90, '^', 'MarkerFaceColor', cols(tfi,:), 'MarkerEdgeColor', 'k')
    end
%     ylim([-1 1])
    yl = ylim; ylim([-1, 1].*max(abs(yl)));
    xlim([0.5 3]); xl = xlim;
    set(gca, 'ycolor', 'none', 'xcolor', 'none')
    plot(xl, [0 0], '-k', 'linewidth', .5);
%     title(dims{dd}, 'Interpreter', 'none');
end


%% visualization of trajectories
% keyboard
tfs = [5 6 7; 1 2 3];
rts = {'short', 'med', 'long'};
dims = {'movement_null1', 'movement_null2', 'movement_potent'};
% dims = {'tf_fast', 'tf_slow', 'movement_potent'};

resp_ids = isbetween(t_ax_resps.ch, [0 2]);
proj_vecs = nan(numel(dims), 2, 2, sum(resp_ids), nIter); % F/S, short/long
proj_vecs_raw = proj_vecs;
for dd = 1:length(dims)
    dim = dims{dd};
    for iter = 1:nIter
        
        for tfi = 1:height(tfs)
            for rti = 1:length(rts)
                proj_vec = zeros(width(tfs), sum(resp_ids));
                for ii = 1:width(tfs)
                    proj_vec_raw = smoothdata(projs_iters_aligned{iter}.(dim). ...
                                    (sprintf('hitE%s%d', rts{rti}, tfs(tfi,ii)))(resp_ids), 'movmean', [50 0]);
                    sm = smoothdata(projs_iters_aligned{iter}.(dim). ...
                                    (sprintf('hitE%s%d', rts{rti}, tfs(tfi,ii))), ...
                                    'movmean', [20 20]);
                    proj_vec(ii,:) = sm(resp_ids);
                end 
                proj_vecs(dd, tfi, rti, :, iter)     = nanmean(proj_vec,1);
                proj_vecs_raw(dd, tfi, rti, :, iter) = nanmean(proj_vec_raw,1);
            end
        end
    end
end
%
%% Plot changes in F, S, prelick
f_traj = figure('Units', 'normalized', 'OuterPosition', [.3 .1 .18 .2]);
subplot(1,2,1);
% ch_cols = [ops.colors.F; ops.colors.F_light; ops.colors.S; ops.colors.S_light];
ch_cols = flipud(RedGreyBlue(6));
ch_cols(4:6,:) = flipud(ch_cols(4:6,:));
subplot(1,2,1); hold on; % trajectories
[~, chon_t] =  min(abs(t_ax_resps.ch(resp_ids))); %chon_t = start_t + 5;
dt = mode(diff(t_ax_resps.ch));
marker_ts = abs(t_ax_resps.ch(resp_ids)/.25 - round(t_ax_resps.ch(resp_ids)/.25)) < dt/5;

for tfi = 1:height(tfs) % F, S
    for rti = [1 3]% short, long
        plot3(squeeze(nanmean(proj_vecs(1, tfi, rti, :, :), 5)), ...
              squeeze(nanmean(proj_vecs(2, tfi, rti, :, :), 5)), ...
              squeeze(nanmean(proj_vecs(3, tfi, rti, :, :), 5)), ...
              'color', ch_cols(rti + (tfi-1)*(length(rts)),:), 'linewidth', 1.5);
          
        
        % add dots indicating time every 250ms
        scatter3(squeeze(nanmean(proj_vecs(1, tfi, rti, marker_ts, :), 5)), ...
                 squeeze(nanmean(proj_vecs(2, tfi, rti, marker_ts, :), 5)), ...
                 squeeze(nanmean(proj_vecs(3, tfi, rti, marker_ts, :), 5)), ...
                 20, 'o', ...
                 'MarkerFaceColor', ch_cols(rti + (tfi-1)*(length(rts)),:), ...
                 'MarkerEdgeAlpha', 0);
             
        scatter3(squeeze(nanmean(proj_vecs(1, tfi, rti, chon_t, :), 5)), ...
                 squeeze(nanmean(proj_vecs(2, tfi, rti, chon_t, :), 5)), ...
                 squeeze(nanmean(proj_vecs(3, tfi, rti, chon_t, :), 5)), ...
                 80, 'd', ...
                 'MarkerFaceColor', ch_cols(rti + (tfi-1)*(length(rts)),:), ...
                 'MarkerEdgeColor', 'k');
             
%         keyboard
    end
end
view([-51 42])
grid on
xlabel('Null 1'); ylabel('Null 2'); zlabel('Potent')

xl = xlim; yl = ylim; zl = zlim;

% project shadows
subplot(1,2,2); hold on;
ax_lims = [xl(2); yl(2); zl(1)];
for tfi = 1:height(tfs) % F, S
    for rti = [1 3]% short, long
            start_coords = zeros(3,1);
            start_errors = zeros(3,2);
            for dim = 1:3
                start_coords(dim)  = squeeze(nanmean(proj_vecs_raw(dim, tfi, rti, chon_t, :), 5));
                start_errors(dim,:) = prctile(squeeze(proj_vecs_raw(dim, tfi, rti, chon_t, :)), [2.5 97.5]);
            end
            scatter3(start_coords(1), start_coords(2), start_coords(3), ...
                     80, 'd', ...
                     'MarkerFaceColor', ch_cols(rti + (tfi-1)*(length(rts)),:), ...
                     'MarkerFaceAlpha', 1, ...
                     'MarkerEdgeColor', 'k');
%              plot3(start_errors(1,:), ...
%                    [start_coords(2) start_coords(2)],...
%                     [start_coords(3) start_coords(3)], 'color',  ch_cols(rti + (tfi-1)*(length(rts)),:))
%              plot3([start_coords(1) start_coords(1)], ...
%                     start_errors(2,:),...
%                     [start_coords(3) start_coords(3)], 'color',  ch_cols(rti + (tfi-1)*(length(rts)),:))
%              plot3([start_coords(1) start_coords(1)], ...
%                    [start_coords(2) start_coords(2)],...
%                    start_errors(3,:), 'color',  ch_cols(rti + (tfi-1)*(length(rts)),:)) 
               
             % draw line to z plane
             plot3([start_coords(1) start_coords(1)], [start_coords(2) start_coords(2)], [-4 start_coords(3)], '-k');
    end
end
% plot plane
[x, y] = meshgrid(-1:.5:2, -2:.5:1);
z = -4 * ones(size(x));
surf(x,y,z, 'FaceColor', [.8 .8 .8], 'FaceAlpha', .5, 'EdgeAlpha', .2)

view([-51 42])
xlim([-1 2]); ylim([-2 1]); zlim([-4 3])
grid on
xlabel('Null 1'); ylabel('Null 2'); zlabel('Potent')

% projected down onto null 1
end