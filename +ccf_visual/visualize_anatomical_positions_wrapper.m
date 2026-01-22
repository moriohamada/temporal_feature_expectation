function visualize_anatomical_positions_wrapper(sessions, sp_all, avg_resps, indexes, ops)
% Wrapper code for visualizing anatomical locations of TF-preferring units


%% Load in unit locations
 
coords = cell(length(sessions),1);

for ss = 1:length(sessions)
    
    fprintf('session %d/%d\n', ss, length(sessions));
    
    animal  = sessions(ss).animal;
    session = sessions(ss).session;
    if strcmp(session(1), 'h'), continue; end
    
    sp  = ccf_visual.load_single_session_sp(animal, session, ops);
    xyz = ccf_visual.get_cluster_CCF_coordinates(sp);
    
    % remove bad units
    rmv = ccf_visual.get_units_to_remove(sp, sp_all{ss});
    xyz(rmv,:) = [];
    
    coords{ss} = xyz;
end
%% Visualize
% load rois
rois = utils.group_rois;

% get units to remove
multi = utils.get_multi(avg_resps, indexes);
void_areas = {'SEZ', 'V3', 'VL', 'bsc', 'ccb', 'ccg', 'ccs', 'ec', 'fa', 'fiber tracts', ...
              'fp', 'frf', 'hbc', 'lot', 'or', 'pc', 'root', 'rust', 'scwm', 'sm', 'void'};
void_ids = utils.get_units_in_area(indexes.loc, void_areas);
good = ~multi & ~void_ids;

neuron_coords = vertcat(coords{:})';
neuron_coords = neuron_coords(:, good);
neuron_coords = ccf_visual.bregma_to_allen(neuron_coords);
neuron_coords = neuron_coords([3 2 1], :); % transform to AP/ML/DV


% specify paths
annotation_volume_path = '/home/morio/Documents/MATLAB/NPX/allenCCF-master/annotation_25.nrrd';
structure_tree_path    = '/home/morio/Documents/MATLAB/NPX/allenCCF-master/structure_tree_safe_2017.csv';
plot_save_dir          = fullfile(ops.saveDir, 'anatomy');
if ~exist(plot_save_dir), mkdir(plot_save_dir); end

[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes(good,:));
% tf_sensitive = (abs(indexes(good,:).tf_z_peakF)>2.58 | abs(indexes(good,:).tf_z_peakS)>2.58) & ...
%                 indexes(good,:).tf_short_p<.05 & ...
%                  sign(indexes(good,:).tf_short)==sign(indexes(good,:).tf_z_peakD);
tf_pref = sign(tf_pref) .* tf_sensitive; 
cmap = create_custom_colormap(ops.colors.S_pref, [.7 .7 .7], ops.colors.F_pref); 

% highlight_regions = {
%     struct('regions', rois{1,2}, 'color', ops.colors.Vis),...  
%     struct('regions', rois{2,2}, 'color', ops.colors.PPC), ...
%     struct('regions', rois{3,2}, 'color', ops.colors.MOs)};
highlight_regions = {
    struct('regions', rois{1,2}, 'color', ops.colors.Vis),...  
    struct('regions', rois{3,2}, 'color', ops.colors.MOs)};

ftf = ccf_visual.visualize_neurons_on_atlas(neuron_coords, highlight_regions, ...
                                            annotation_volume_path, structure_tree_path, ...
                                            tf_pref, cmap);

%% save from different perspectives

saveas(ftf, fullfile(plot_save_dir, 'tf_backL'));
print('-dsvg', '-painters', fullfile(plot_save_dir, 'tf_backL.svg'))

% and from alternate views
view([90 90]);
camorbit(0, 20, 'data', [0 1 0])
camorbit(30, 0, 'data', [1 0 0])
saveas(ftf, fullfile(plot_save_dir, 'tf_frontL'));
print('-dsvg', '-painters', fullfile(plot_save_dir, 'tf_frontL.svg'))

view([90 90]);
saveas(ftf, fullfile(plot_save_dir, 'tf_sideL'));
print('-dsvg', '-painters', fullfile(plot_save_dir, 'tf_sideL.svg'))

end