function f = plot_tf_lick_index_relationships_singleUnit(avg_resps, t_ax, indexes, allen_areas, neuron_info, ops)
% 
% Scatter plots of indexes
% 
% --------------------------------------------------------------------------------------------------

rois = {{'V1', 'Visual thalamus', 'Visual midbrain'}, ...
        {'PPC','Visual cortex', 'Sensory thalamus'}, ...
        {'MOs', 'BG'}};
%     rois = {{'V1', 'Visual thalamus', 'Visual midbrain','PPC','Visual cortex',  'Sensory thalamus','MOs', 'BG'}}
roi_titles = {'Visual cortex and thalamus', 'PPC', 'MOs/Striatum'};

subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_010', 'MH_015'};
good_subj = ismember(neuron_info.animal,subjects);

allen_areas = {};
for r = 1:length(rois)
    areas = area_names_in_roi(rois{r});
    
    while any(cellfun(@iscell, areas))
        areas = [areas{cellfun(@iscell,areas)} areas(~cellfun(@iscell,areas))];
    end
    allen_areas{r} = areas;
end

multi = (indexes.cg==0) | avg_resps.FRmu<.01 | avg_resps.FRsd<.01 | ~good_subj ;

fast = indexes.tf_short_p<.01 & indexes.tf_short>0  ;
slow = indexes.tf_short_p<.01 & indexes.tf_short<0  ;
% fast = (indexes.tfExpF_short_p<.05 & indexes.tfExpS_short_p<.05) & (indexes.tfExpF_short>0 & indexes.tfExpS_short>0);
% slow = (indexes.tfExpF_short_p<.05 & indexes.tfExpS_short_p<.05)& (indexes.tfExpF_short<0 & indexes.tfExpS_short<0);
% fast = (indexes.tf_short_p<.05) & (indexes.tfExpF_short>0 & indexes.tfExpS_short>0);
% slow = (indexes.tf_short_p<.05) & (indexes.tfExpF_short<0 & indexes.tfExpS_short<0);
nonr = (indexes.prelickExpF_p<.05 | indexes.prelickExpS_p<.05)& ~(fast|slow); 
lickr = (indexes.prelickExpF_p<.01 | indexes.prelickExpS_p<.01);
% nonr =  (indexes.tfExpF_short<0 & indexes.tfExpS_short<0);

plot_nonr = 0;
if plot_nonr
    n_iter = 3;
else
    n_iter = 2;
end



%% Calculate lick modulation by changes and by TF

prelick_twin = [-1.5 -1; -.5 -.1];
inds.prelick_F = (nanmean(avg_resps.hitLickF(:, isbetween(t_ax.hit, prelick_twin(:,2))),2) - ...
                  nanmean(avg_resps.hitLickF(:, isbetween(t_ax.hit, prelick_twin(:,1))),2))./ ...
                 (nanmean(avg_resps.hitLickF(:, isbetween(t_ax.hit, prelick_twin(:,2))),2) + ...
                  nanmean(avg_resps.hitLickF(:, isbetween(t_ax.hit, prelick_twin(:,1))),2));
inds.prelick_S = (nanmean(avg_resps.hitLickS(:, isbetween(t_ax.hit, prelick_twin(:,2))),2) - ...
                  nanmean(avg_resps.hitLickS(:, isbetween(t_ax.hit, prelick_twin(:,1))),2)) ./ ...
                 (nanmean(avg_resps.hitLickS(:, isbetween(t_ax.hit, prelick_twin(:,2))),2) + ...
                  nanmean(avg_resps.hitLickS(:, isbetween(t_ax.hit, prelick_twin(:,1))),2));
% inds.prelick_F = indexes.prelickExpF;
% inds.prelick_S = indexes.prelickExpS;

% inds.hittf = (nanmean(avg_resps.hitLickF(:, isbetween(t_ax.hit, prelick_twin(:,2))),2) - ...
%               nanmean(avg_resps.hitLickS(:, isbetween(t_ax.hit, prelick_twin(:,2))),2))./ ...
%              (nanmean(avg_resps.hitLickF(:, isbetween(t_ax.hit, prelick_twin(:,2))),2) + ...
%               nanmean(avg_resps.hitLickS(:, isbetween(t_ax.hit, prelick_twin(:,2))),2));

% ch_twin = [-.5 0; 0 .5];
% inds.chtf = (nanmean(avg_resps.hitF(:, isbetween(t_ax.ch, ch_twin(:,2))),2) - ...
%              nanmean(avg_resps.hitS(:, isbetween(t_ax.ch, ch_twin(:,2))),2))./ ...
%             (nanmean(avg_resps.hitF(:, isbetween(t_ax.ch, ch_twin(:,2))),2) + ...
%              nanmean(avg_resps.hitS(:, isbetween(t_ax.ch, ch_twin(:,2))),2));
         
inds.tf = indexes.tf_short;
%               
% %% TF pref calculated from ch vs tf
% 
% f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .25 .25]);
% pl_lim = [-.5 .5];
% tf_lim = [-.5 .5];
% 
% for rr = 1:length(rois)
%     in_roi = contains(indexes.loc, allen_areas{rr});
%     
%      for tf_resp_i = n_iter:-1:1 % fast, slow, non resp
%         
%          if tf_resp_i == 1
%              selection = fast & in_roi & ~multi;
%              extra_sel = selection & lickr;
%              clr       = ops.colors.F_pref;
%              sz        = 10;
%          elseif tf_resp_i == 2
%              selection = slow & in_roi & ~multi;
%              extra_sel = selection & lickr;
%              clr       = ops.colors.S_pref;
%              sz        = 10;
%          elseif tf_resp_i == 3
%              selection = nonr & in_roi & ~multi;
%              extra_sel = selection & lickr;
%              if rr == 1, clr = ops.colors.Vis; 
%              elseif rr==2, clr = ops.colors.PPC;
%              elseif rr==3, clr = ops.colors.MOs; end
% %              clr       = [.5 .5 .5];
%              sz        = 10;
%          end
%          
%          % tf vs ch
%          subplot(length(rois), 2, (rr-1)*2+1)
%          hold on;
%          scatter(inds.tf(selection), inds.chtf(selection), sz, ...
%                  'MarkerFaceColor', clr, 'MarkerFaceAlpha', .6, ...
%                  'MarkerEdgeAlpha', 0);
%          scatter(inds.tf(extra_sel), inds.chtf(extra_sel), sz, ...
%                  'MarkerFaceColor', clr, 'MarkerFaceAlpha', .6, ...
%                  'MarkerEdgeAlpha', 1, 'MarkerEdgeColor', 'k');
%          xlim(pl_lim); ylim(pl_lim);
%          
%          % tf vs hit
%          subplot(length(rois), 2, (rr-1)*2+2)
%          hold on;
%          scatter(inds.tf(selection), inds.hittf(selection), sz, ...
%                  'MarkerFaceColor', clr, 'MarkerFaceAlpha', .6, ...
%                  'MarkerEdgeAlpha', 0);
%          scatter(inds.tf(extra_sel), inds.hittf(extra_sel), sz, ...
%                  'MarkerFaceColor', clr, 'MarkerFaceAlpha', .6, ...
%                  'MarkerEdgeAlpha', 1, 'MarkerEdgeColor', 'k');
%          xlim(tf_lim); ylim(pl_lim);
%          
%      end
%        
% end


%% Iterate through rois and make scatter plots
% 1) Prelick - fast vs slow hit
% 2) TF vs pre-lick
% close all

f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .18 .25]);
pl_lim = [-.5 .5];
tf_lim = [-.5 .5];

for rr = 1:length(rois)
    in_roi = contains(indexes.loc, allen_areas{rr});
    
     for tf_resp_i = n_iter:-1:1 % fast, slow, non resp
        
         if tf_resp_i == 1
             selection = fast & in_roi & ~multi;
             extra_sel = selection & lickr;
             clr       = ops.colors.F_pref;
             sz        = 30;
         elseif tf_resp_i == 2
             selection = slow & in_roi & ~multi;
             extra_sel = selection & lickr;
             clr       = ops.colors.S_pref;
             sz        = 30;
         elseif tf_resp_i == 3
             selection = nonr & in_roi & ~multi;
             extra_sel = selection & lickr;
             if rr == 1, clr = ops.colors.Vis; 
             elseif rr==2, clr = ops.colors.PPC;
             elseif rr==3, clr = ops.colors.MOs; end
%              clr       = [.5 .5 .5];
             sz        = 30;
         end
         
         % prelick vs prelick
         subplot(length(rois), 3, (rr-1)*3+1)
         hold on;
         scatter(inds.prelick_F(selection), inds.prelick_S(selection), sz, ...
                 'MarkerFaceColor', clr, 'MarkerFaceAlpha', .5, ...
                 'MarkerEdgeAlpha', 0);
%          scatter(inds.prelick_F(extra_sel), inds.prelick_S(extra_sel), sz, ...
%                  'MarkerFaceColor', clr, 'MarkerFaceAlpha', .4, ...
%                  'MarkerEdgeAlpha', 1, 'MarkerEdgeColor', 'k');
         xlim(pl_lim); ylim(pl_lim);
         ax = gca;
         ax.XAxisLocation = 'origin';
         ax.YAxisLocation = 'origin';
         % tf vs prelick F
         subplot(length(rois), 3, (rr-1)*3+2)
         hold on;
         scatter(inds.tf(selection), inds.prelick_F(selection), sz, ...
                 'MarkerFaceColor', clr, 'MarkerFaceAlpha', .5, ...
                 'MarkerEdgeAlpha', 0);
%          scatter(inds.tf(extra_sel), inds.prelick_F(extra_sel), sz, ...
%                  'MarkerFaceColor', clr, 'MarkerFaceAlpha', .4, ...
%                  'MarkerEdgeAlpha', 1, 'MarkerEdgeColor', 'k');
         xlim(tf_lim); ylim(pl_lim);
         ax = gca;
         ax.XAxisLocation = 'origin';
         ax.YAxisLocation = 'origin';
         
         % tf vs prelick S
         subplot(length(rois), 3, (rr-1)*3+3)
         hold on;
         scatter(inds.tf(selection), inds.prelick_S(selection), sz, ...
                 'MarkerFaceColor', clr, 'MarkerFaceAlpha', .5, ...
                 'MarkerEdgeAlpha', 0);
%          scatter(inds.tf(extra_sel), inds.prelick_S(extra_sel), sz, ...
%                  'MarkerFaceColor', clr, 'MarkerFaceAlpha', .4, ...
%                  'MarkerEdgeAlpha', 1, 'MarkerEdgeColor', 'k');
         xlim(tf_lim); ylim(pl_lim);
         ax = gca;
         ax.XAxisLocation = 'origin';
         ax.YAxisLocation = 'origin';
%          
%          % tf vs prelickF-prelickS
%          subplot(length(rois), 3, (rr-1)*3+3)
%          hold on;
%          scatter(inds.tf(selection), inds.prelick_F(selection)-inds.prelick_S(selection), sz, ...
%                  'MarkerFaceColor', clr, 'MarkerFaceAlpha', .3, ...
%                  'MarkerEdgeAlpha', 0);
%          scatter(inds.tf(extra_sel), inds.prelick_F(extra_sel)-inds.prelick_S(extra_sel), sz, ...
%                  'MarkerFaceColor', clr, 'MarkerFaceAlpha', .3, ...
%                  'MarkerEdgeAlpha', 1, 'MarkerEdgeColor', 'k');
%          xlim(tf_lim); ylim(pl_lim);
%          ax = gca;
%          ax.XAxisLocation = 'origin';
%          ax.YAxisLocation = 'origin';
     end
     
        
end

if ~plot_nonr

    f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .15 .2]);
    pl_lim = [-.5 .5];
    tf_lim = [-.5 .5];

    for rr = 1:length(rois)
        in_roi = contains(indexes.loc, allen_areas{rr});

         for tf_resp_i = 3 % fast, slow, non resp

             selection = nonr & in_roi & ~multi & lickr;
%              extra_sel = selection & lickr;
             if rr == 1, clr = ops.colors.Vis;
             elseif rr==2, clr = ops.colors.PPC;
             elseif rr==3, clr = ops.colors.MOs; end
             %              clr       = [.5 .5 .5];
             sz        = 20;

             % prelick vs prelick
             subplot(length(rois), 3, (rr-1)*3+1)
             hold on;
             scatter(inds.prelick_F(selection), inds.prelick_S(selection), sz, ...
                     'MarkerFaceColor', clr, 'MarkerFaceAlpha', .15, ...
                     'MarkerEdgeAlpha', 0);
%              scatter(inds.prelick_F(extra_sel), inds.prelick_S(extra_sel), sz, ...
%                      'MarkerFaceColor', clr, 'MarkerFaceAlpha', .3, ...
%                      'MarkerEdgeAlpha', 1, 'MarkerEdgeColor', 'k');
             xlim(pl_lim); ylim(pl_lim);
             ax = gca;
             ax.XAxisLocation = 'origin';
             ax.YAxisLocation = 'origin';
             % tf vs prelick F
             subplot(length(rois), 3, (rr-1)*3+2)
             hold on;
             scatter(inds.tf(selection), inds.prelick_F(selection), sz, ...
                     'MarkerFaceColor', clr, 'MarkerFaceAlpha', .15, ...
                     'MarkerEdgeAlpha', 0);
%              scatter(inds.tf(extra_sel), inds.prelick_F(extra_sel), sz, ...
%                      'MarkerFaceColor', clr, 'MarkerFaceAlpha', .3, ...
%                      'MarkerEdgeAlpha', 1, 'MarkerEdgeColor', 'k');
             xlim(tf_lim); ylim(pl_lim);
             ax = gca;
             ax.XAxisLocation = 'origin';
             ax.YAxisLocation = 'origin';

             % tf vs prelick S
             subplot(length(rois), 3, (rr-1)*3+3)
             hold on;
             scatter(inds.tf(selection), inds.prelick_S(selection), sz, ...
                     'MarkerFaceColor', clr, 'MarkerFaceAlpha', .15, ...
                     'MarkerEdgeAlpha', 0);
%              scatter(inds.tf(extra_sel), inds.prelick_S(extra_sel), sz, ...
%                      'MarkerFaceColor', clr, 'MarkerFaceAlpha', .3, ...
%                      'MarkerEdgeAlpha', 1, 'MarkerEdgeColor', 'k');
             xlim(tf_lim); ylim(pl_lim);
             ax = gca;
             ax.XAxisLocation = 'origin';
             ax.YAxisLocation = 'origin';
             
             
%              % tf vs prelickF-prelickS
%              subplot(length(rois), 3, (rr-1)*3+3)
%              hold on;
%              scatter(inds.tf(selection), inds.prelick_F(selection)-inds.prelick_S(selection), sz, ...
%                  'MarkerFaceColor', clr, 'MarkerFaceAlpha', .3, ...
%                  'MarkerEdgeAlpha', 0);
% %              scatter(inds.tf(extra_sel), inds.prelick_F(extra_sel)-inds.prelick_S(extra_sel), sz, ...
% %                  'MarkerFaceColor', clr, 'MarkerFaceAlpha', .3, ...
% %                  'MarkerEdgeAlpha', 1, 'MarkerEdgeColor', 'k');
%              xlim(tf_lim); ylim(pl_lim);
%              ax = gca;
%              ax.XAxisLocation = 'origin';
%              ax.YAxisLocation = 'origin';

         end


    end

end


end