function [f1, f3] = visualize_xval_movementSpace_activity(projs_iters, t_ax_resps, ev_groups, dim_names, ops)
% 
% Visualize activity projected onto movement-related spaces in 1D and 3D. Called from
% null_space_analysis_wrapper.m
% 
% --------------------------------------------------------------------------------------------------
nIter = length(projs_iters);

%% 1D plots

f1 = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .3 .3]);

for ax_i = 1:length(dim_names)
    dim_name = dim_names{ax_i};
    
    for evg_i = 1:size(ev_groups,1)
        evs   = ev_groups{evg_i,1};
        cls   = ev_groups{evg_i,2};
        tlims = ev_groups{evg_i,3};
        
        if contains(evs, 'bl')
            t = t_ax_resps.bl;
        elseif (contains(evs, 'exp') & ~contains(evs, 'FA')) | contains(evs, 'tf')
            t = t_ax_resps.tf;
        elseif contains(evs, 'exp') & contains(evs, 'FA')
            t = t_ax_resps.fa;
        elseif contains(evs, 'Lick')
            t = t_ax_resps.hit;
        elseif contains(evs, 'hit')
            t = t_ax_resps.ch;
        else
            keyboard
        end
        
        subplot(numel(dim_names), size(ev_groups,1), evg_i + (ax_i-1)*size(ev_groups,1))
        hold on
        
        for ee = 1:numel(evs)
            ev = evs{ee};
            
            all_iter_projs = nan(nIter, length(projs_iters{1}.(dim_name).(ev)));
            for iter = 1:nIter
                all_iter_projs(iter,:) = smoothdata(projs_iters{iter}.(dim_name).(ev), 'movmean', 5);
            end
            if contains(evs, 'exp') & ~contains(evs, 'FA') % tf pulse
                start_ids = isbetween(t, [-.5 -.1]);
                end_ids   = isbetween(t, [.7 1.2]);
                all_iter_projs = detrend_resp(all_iter_projs, start_ids, end_ids);
                if ax_i < 3
                all_iter_projs = all_iter_projs - nanmedian(all_iter_projs(:, isbetween(t, [-.5 0])),2);
                end
            end
             
            ci_95 = ci_95_bootstrapped(all_iter_projs,1); 
            if (strcmp(ev, 'FexpF') | strcmp(ev, 'SexpF')) & ax_i==2
                plot(t-.05, nanmean(all_iter_projs, 1), 'color', cls(ee,:), 'linewidth', 1);
                shade_handle = fill([t-.05, fliplr(t-.05)], [ci_95(1,:), fliplr(ci_95(2,:))],  cls(ee,:), 'FaceAlpha', .2, 'EdgeColor', 'none');
            else
                plot(t, nanmean(all_iter_projs, 1), 'color', cls(ee,:), 'linewidth', 1);
                shade_handle = fill([t, fliplr(t)], [ci_95(1,:), fliplr(ci_95(2,:))],  cls(ee,:), 'FaceAlpha', .2, 'EdgeColor', 'none');
            end
            
        end
        xlim(tlims)
    end

end

% %% 3d plots
% keyboard
% f3 = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .4 .3]);
% 
% for evg_i = 1:size(ev_groups,1)
%     evs   = ev_groups{evg_i,1};
%     cls   = ev_groups{evg_i,2};
%     tlims = ev_groups{evg_i,3};
%     
%     if contains(evs, 'bl')
%         t = t_ax_resps.bl;
%     elseif contains(evs, 'exp') & ~contains(evs, 'FA')
%         t = t_ax_resps.tf;
%     elseif contains(evs, 'exp') & contains(evs, 'FA')
%         t = t_ax_resps.fa;
%     elseif contains(evs, 'Lick')
%         t = t_ax_resps.hit;
%     elseif contains(evs, 'hit')
%         t = t_ax_resps.ch;
%     else
%         keyboard
%     end
% 
% 


end






