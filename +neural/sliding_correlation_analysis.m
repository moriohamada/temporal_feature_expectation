function tf_lick_separation_wrapper_v2(sessions, neuron_info, glm_kernels, ops)
% 
% Show separability of sensory evidence and lick prep ax:
% 1) single unit examples and averages of TF and pre-lick activity - show mixed
% 2) Pre-lick activity for fast vs slow pulses
% 3) Extract population activity for pre-lick and lick; project TF responses, licks
% 
% --------------------------------------------------------------------------------------------------

%% Load indexes and responses

[indexes, avg_resps, t_ax ]  = load_indexes_avgResps(sessions, neuron_info, ops);

% subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_010', 'MH_015'};
subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_010', 'MH_011','MH_015'};

% subjects = {'MH_002'};
good_subj = ismember(neuron_info.animal,subjects);
%%


flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');
animals = unique({sessions.animal});
rois = {{'V1', 'Visual thalamus' }, ...
        {'PPC','Visual cortex' }, ...
        {'MOs', 'BG'}}; 
rois = {{'V1', 'Visual thalamus' }, ...
        {'PPC','Visual cortex' }, ...
        {'MOs', 'STR'}}; 
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
%% 1) Visualize PSTHs of all units around TF outliers, FAs, change onsets - TF sensitive vs not
close all
% select tf sensitive
% tf_sensitive = (indexes.tfExpF_short_p<.01 | indexes.tfExpS_short_p<.01);
% tf_sensitive =  indexes.tf_p<.05 & sign(indexes.tfExpF)==sign(indexes.tfExpS);% & indexes.tf_short_p<.05 ;%&  (indexes.tfExpF_p<sqrt(.05)&indexes.tfExpS_p<sqrt(.05));
% tf_sensitive =  indexes.tfExpF_short_p<.05 & indexes.tfExpS_short_p<.05 & sign(indexes.tfExpF)==sign(indexes.tfExpS);
% tf_sensitive =  indexes.prelick_p<.05;% & indexes.tf_short_p<.05 ;%&  (indexes.tfExpF_p<sqrt(.05)&indexes.tfExpS_p<sqrt(.05));
tf_sensitive = indexes.tf_short_p<.01;

multi = (indexes.cg==0) | avg_resps.FRmu<.1 | avg_resps.FRsd<.1 ;


selection = tf_sensitive & ~multi & good_subj ;%& (~contains(indexes.loc, allen_areas{6}) | time_sensitive);

f_psth_tf = plot_all_units_psths(avg_resps(selection,:), t_ax, indexes(selection, :), allen_areas, 'tf', ops);

% % %
% lick_sensitive = indexes.lick_p<.01 & indexes.lick~=1;
% selection = lick_sensitive & ~multi & good_subj & indexes.cg==2;
f_psth_lick = plot_all_units_psths(avg_resps(selection,:), t_ax, indexes(selection, :), allen_areas, 'tf', ops);

%% 1b) averaged psths by area
close all
fs_avg_psth = plot_all_units_avg_psth(avg_resps, t_ax, indexes, neuron_info, ops);
% 
% for ii = 1:length(fs_avg_psth)
%     f = fs_avg_psth{ii};
%     saveas(f, fullfile(ops.saveDir, 'tfLickSeparation', sprintf('avg_psths_roi%d', ii)))
%     saveas(f, fullfile(ops.saveDir, 'tfLickSeparation', sprintf('avg_psths_roi%d', ii)), 'svg')
%     saveas(f, fullfile(ops.saveDir, 'tfLickSeparation', sprintf('avg_psths_roi%d', ii)), 'png')
% end
%% 2) Show lick-related modulation of fast and slow units, non-responsive units - scatter and histogram
close all
% scatter plot of indexes
% f_index_scatter = plot_tf_lick_index_relationships_singleUnit(avg_resps, t_ax, indexes, allen_areas, neuron_info, ops);
f_scatter = plot_tf_prelick_index_relationships(avg_resps, t_ax, indexes, allen_areas, neuron_info, ops)
roi_titles = {'vis', 'ppc', 'mos'}
for rr = 1:3
    saveas(f_scatter{rr}, fullfile(ops.saveDir, 'tfLickSeparation', sprintf('index_scatters_%s', roi_titles{rr})))
    saveas(f_scatter{rr}, fullfile(ops.saveDir, 'tfLickSeparation', sprintf('index_scatters_%s', roi_titles{rr})), 'svg')
end
saveas(f_scatter{4}, fullfile(ops.saveDir, 'tfLickSeparation', 'tf_pl_index_scatters_all'))
saveas(f_scatter{4}, fullfile(ops.saveDir, 'tfLickSeparation', 'tf_pl_index_scatters_all'), 'svg')
%
% histogram of activity correlation before lick, around lick, for tf resp/non-resp units
[fr, fh] = quantify_prelick_activity_similarity(avg_resps, t_ax, indexes, neuron_info, allen_areas, ops)

% saveas(fr{1}, fullfile(ops.saveDir, 'tfLickSeparation', 'psth_correlations_roiVis'), 'svg');
% saveas(fr{3}, fullfile(ops.saveDir, 'tfLickSeparation', 'psth_correlations_roiMOs'), 'svg');
% saveas(fh{1}, fullfile(ops.saveDir, 'tfLickSeparation', 'psthWin_correlations_roiVis'), 'svg');
% saveas(fh{3}, fullfile(ops.saveDir, 'tfLickSeparation', 'psthWin_correlations_roiMOs'), 'svg');

%% 4) Pre-lick PCA, in tf responsive and non-responsive populations
% select tf sensitive
close all
% tf_sensitive = indexes.tf_short_p<.01;
tf_sensitive = (indexes.tfExpF_short_p<.05 & indexes.tfExpS_short_p<.05);

multi = (indexes.cg==0) | avg_resps.FRmu<.1 | avg_resps.FRsd<.1 ;
in_mos = contains(indexes.loc, allen_areas{5}) | contains(indexes.loc, allen_areas{6});

tf_resp = tf_sensitive & ~multi & good_subj & in_mos & indexes.prelick_p<.05;
lick_resp_nontf = find(indexes.prelick_p<.05 & ~multi & good_subj & indexes.tf_short_p>.1 & in_mos & ...
                       abs(indexes.tf_short) < prctile(abs(indexes.tf_short),50));
% if length(lick_resp_nontf) > sum(tf_resp)
%     lick_resp_nontf = lick_resp_nontf(randperm(length(lick_resp_nontf), sum(tf_resp)));
% end
lick_resp = indexes.prelick_p<.01 & ~multi & good_subj & in_mos;
        
% f_pc_prelick_tf = visualize_prelick_pc_trajectories_3d(avg_resps(tf_resp,:), t_ax, allen_areas,  ops)
% f_pc_prelick_lickNonTF = visualize_prelick_pc_trajectories_3d(avg_resps(lick_resp_nontf,:), t_ax, allen_areas,  ops)
f_pc_prelick_tf = visualize_prelick_pc_trajectories(avg_resps(tf_resp,:), t_ax, allen_areas,  ops)
f_pc_prelick_lickNonTF = visualize_prelick_pc_trajectories(avg_resps(lick_resp_nontf,:), t_ax, allen_areas,  ops)
% f_pc_prelick_lick = visualize_prelick_pc_trajectories(avg_resps(lick_resp,:), t_ax, allen_areas,  ops)
% f_pc_prelick_lick = visualize_prelick_pc_trajectories(avg_resps(lick_resp|tf_resp,:), t_ax, allen_areas,  ops)

% % save figures
% saveas(f_pc_prelick_tf, fullfile(ops.saveDir, 'tfLickSeparation', 'mos_prelick_tf_pcTraj_tf'))
% saveas(f_pc_prelick_tf, fullfile(ops.saveDir, 'tfLickSeparation', 'mos_prelick_tf_pcTraj_tf'), 'svg')
% saveas(f_pc_prelick_lickNonTF, fullfile(ops.saveDir, 'tfLickSeparation', 'mos_prelick_tf_pcTraj_nontf'))
% saveas(f_pc_prelick_lickNonTF, fullfile(ops.saveDir, 'tfLickSeparation', 'mos_prelick_tf_pcTraj_nontf'), 'svg')
% saveas(f_pc_prelick_lick, fullfile(ops.saveDir, 'tfLickSeparation', 'mos_prelick_tf_pcTraj_all'))
% saveas(f_pc_prelick_lick, fullfile(ops.saveDir, 'tfLickSeparation', 'mos_prelick_tf_pcTraj_all'), 'svg')

%%
% in_vis = contains(indexes.loc, allen_areas{1}) | contains(indexes.loc, allen_areas{3});
% 
% tf_resp = tf_sensitive & ~multi & good_subj & in_vis & indexes.prelick_p<.05;
% lick_resp_nontf =indexes.prelick_p<.05 & ~multi & good_subj & indexes.tf_short_p>.1 & in_vis;
% lick_resp = indexes.prelick_p<.05 & ~multi & good_subj & in_vis;
%         
% f_pc_prelick_tf = visualize_prelick_pc_trajectories(avg_resps(tf_resp,:), t_ax, allen_areas,  ops)
% f_pc_prelick_lickNonTF = visualize_prelick_pc_trajectories(avg_resps(lick_resp_nontf,:), t_ax, allen_areas,  ops)
% f_pc_prelick_lick = visualize_prelick_pc_trajectories(avg_resps(lick_resp,:), t_ax, allen_areas,  ops)
% 
% % save figures
% saveas(f_pc_prelick_tf, fullfile(ops.saveDir, 'tfLickSeparation', 'vis_prelick_tf_pcTraj_tf'))
% saveas(f_pc_prelick_tf, fullfile(ops.saveDir, 'tfLickSeparation', 'vis_prelick_tf_pcTraj_tf'), 'png')
% saveas(f_pc_prelick_lickNonTF, fullfile(ops.saveDir, 'tfLickSeparation', 'vis_prelick_tf_pcTraj_nontf'))
% saveas(f_pc_prelick_lickNonTF, fullfile(ops.saveDir, 'tfLickSeparation', 'vis_prelick_tf_pcTraj_nontf'), 'png')

%% 5) TDR-based extraction of TF and pre-lick axes
close all
[f_tdr1,f_tdr2] = visualize_prelick_tf_tdr_proj(sessions, neuron_info, avg_resps, t_ax, indexes, glm_kernels_el, ops)
% close(f_tdr2)
%% aliign axes for 1D plots
set(0, 'currentfigure', f_tdr1);
subplot(3,4,1); ylim([-.4 .25]);
for ii = 2:4, subplot(3,4,ii);ylim([-8 5]); end

subplot(3,4,5); ylim([-.15 .05]);
for ii = 6:8, subplot(3,4,ii);ylim([-3 1]);end
subplot(3,4,9); ylim([-.15 .05]);
for ii = 10:12, subplot(3,4,ii);ylim([-3 1]); end

for ii = 1:12
    subplot(3,4,ii); hold on; 
    title('')
    yl = ylim;
    plot([0 0], yl, 'color', [.5 .5 .5], 'linewidth', 1)
end

% saveas(f_tdr1, fullfile(ops.saveDir, 'tfLickSeparation', 'mos_tdr_1d'))
% saveas(f_tdr1, fullfile(ops.saveDir, 'tfLickSeparation', 'mos_tdr_1d'), 'svg')
% saveas(f_tdr2, fullfile(ops.saveDir, 'tfLickSeparation', 'mos_tdr_2d'))
% saveas(f_tdr2, fullfile(ops.saveDir, 'tfLickSeparation', 'mos_tdr_2d'), 'svg')


end


%%
