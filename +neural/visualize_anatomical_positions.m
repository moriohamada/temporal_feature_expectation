%% Pipieline for visualizing recordings in CCF
% 
% Load in cluster coordinates, and allow colouring by TF/Time/Lick preference
% 
% --------------------------------------------------------------------------------------------------

% clear; clc; close all
%%
addpath(genpath('/home/morio/Documents/MATLAB/General'));
addpath(genpath('/home/morio/Documents/MATLAB/switch-task/Analysis_pipeline'));
addpath(genpath('/home/morio/Documents/MATLAB/NPX/spikes-master/'));

graphics_small;

%% Specify data and options

[db, ops] = switch_task_analysis_params();

%% Load in unit locations

chan_coords = nan(3,0); % x/y/z Allen CCF coordinates

coords = cell(length(sessions),1);

parfor ss = 1:length(sessions)
    
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

%% Load indexes & resps
% indexes = table;
% % load in indexes
% for s = 1:length(sessions)
%     animal  = sessions(s).animal;
%     session = sessions(s).session;
%     if strcmp(session(1), 'h') % not recording session
%         continue
%     end
%     inds = loadVariable(fullfile(ops.indexesDir, sprintf('%s_%s.mat', animal, session)), 'indexes');
%     indexes = vertcat(indexes, inds);
% end
[indexes, avg_resps, t_ax, ~, ~]  = load_indexes_avgResps(sessions, neuron_info, ops);

%% Roi specificaiton
rois = {{'V1', 'Visual thalamus', 'Visual midbrain'}, ...
        {'PPC','Visual cortex',  'Sensory thalamus'}, ...
        {'MOs', 'BG', 'mPFC'}};  
    
allen_areas = {};

for r = 1:length(rois)
    areas = area_names_in_roi(rois{r});
    
    while any(cellfun(@iscell, areas))
        areas = [areas{cellfun(@iscell,areas)} areas(~cellfun(@iscell,areas))];
    end
    allen_areas{r} = areas;
end

%% Remove bad units
good_units = logical(ones(height(indexes),1));
for r = 1:length(rois)
    this_roi_areas = allen_areas{r};
    in_area = contains(avg_resps.loc, this_roi_areas);
    disp(sum(in_area))
    good_units(in_area) = 1;
end
void_areas = area_names_in_roi({'misc'});
void_units = contains(avg_resps.loc, void_areas{:});
good_units(void_units) = 0;
subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_007', 'MH_010', 'MH_011','MH_014', 'MH_015'};
good_subj = ismember(indexes.animal,subjects);
multi = (indexes.cg==0) | avg_resps.FRmu < .1 | avg_resps.FRsd<.1 | ~good_subj;
good_units(multi) = 0;

%%
indexes_good = indexes(good_units,:);


%% Visualize all units
% get coordinates
neuron_coords = vertcat(coords{:})';
neuron_coords = neuron_coords(:, good_units);

neuron_coords = ccf_visual.bregma_to_allen(neuron_coords);
% neuron_coords(1,:) = -abs(neuron_coords(1,:));
neuron_coords = neuron_coords([3 2 1], :);
% specify locations


rois = {{'V1', 'Visual thalamus'}, ...
        {'PPC', 'Visual cortex'}, ...
        {'MOs', 'BG'}};  
allen_areas = {};

for r = 1:length(rois)
    areas = area_names_in_roi(rois{r});
    
    while any(cellfun(@iscell, areas))
        areas = [areas{cellfun(@iscell,areas)} areas(~cellfun(@iscell,areas))];
    end
    allen_areas{r} = areas;
end
allen_areas{3} = {'MOs', 'CP', 'ACB', 'STR'};
highlight_regions = {
    struct('regions', allen_areas{1}, 'color', ops.colors.Vis),...  
    struct('regions', allen_areas{2}, 'color', ops.colors.PPC), ...
    struct('regions', allen_areas{3}, 'color', ops.colors.MOs)};
% highlight_regions = {
%     struct('regions', {'MOs'}, 'color', [1, 0, 0]), ...
%     struct('regions', {'SSp'}, 'color', [0, 1, 0])};

% specify paths
annotation_volume_path = '/home/morio/Documents/MATLAB/NPX/allenCCF-master/annotation_25.nrrd';
structure_tree_path    = '/home/morio/Documents/MATLAB/NPX/allenCCF-master/structure_tree_safe_2017.csv';
plot_save_dir          = fullfile(ops.saveDir, 'anatomy');
if ~exist(plot_save_dir), mkdir(plot_save_dir); end

%% First plot just axes


f = ccf_visual.visualize_neurons_on_atlas(neuron_coords, highlight_regions, ...
                                          annotation_volume_path, structure_tree_path, [], []);
                                      
cla;
hold on 
quiver3([0 0 0], [0 0 0], [0 0 0], [-2e3 0 0], [0 -2e3 0], [0 0 2e3], '-k', 'LineWidth', 1.5)
print('-dsvg', '-painters', fullfile(plot_save_dir, 'ax_backL.svg'))
view([90 90]);
camorbit(0, 20, 'data', [0 1 0])
camorbit(30, 0, 'data', [1 0 0])
print('-dsvg', '-painters', fullfile(plot_save_dir, 'ax_frontL.svg'))
view([90 90]);
print('-dsvg', '-painters', fullfile(plot_save_dir, 'ax_sideL.svg'))

%% TF preference
pref = [indexes_good.tf_short];
% sig  = [indexes_good.tf_short_p];
tf_sig  = indexes_good.tf_short_p<.01;% & sign(indexes_good.tfExpF_short)==sign(indexes_good.tfExpS_short);
pref(isnan(pref)) = 0;
pref(~tf_sig) = 0;
pref = sign(pref);
% colormap
cmap = create_custom_colormap(ops.colors.S_pref, [.8 .8 .8], ops.colors.F_pref); 

ftf = ccf_visual.visualize_neurons_on_atlas(neuron_coords, highlight_regions, ...
                                            annotation_volume_path, structure_tree_path, ...
                                            pref, cmap);
saveas(ftf, fullfile(plot_save_dir, 'tf_backL'));
% saveas(ftf, fullfile(plot_save_dir, 'tf_backL'), 'svg');
print('-dsvg', '-painters', fullfile(plot_save_dir, 'tf_backL.svg'))
% exportgraphics(ftf, fullfile(plot_save_dir, 'tf_backL.svg'), 'ContentType', 'vector');
% and from alternate views
view([90 90]);
camorbit(0, 20, 'data', [0 1 0])
camorbit(30, 0, 'data', [1 0 0])
saveas(ftf, fullfile(plot_save_dir, 'tf_frontL'));
% saveas(ftf, fullfile(plot_save_dir, 'tf_frontL'), 'svg');
print('-dsvg', '-painters', fullfile(plot_save_dir, 'tf_frontL.svg'))
% exportgraphics(ftf, fullfile(plot_save_dir, 'tf_frontL.svg'), 'ContentType', 'vector');

view([90 90]);
saveas(ftf, fullfile(plot_save_dir, 'tf_sideL'));
% saveas(ftf, fullfile(plot_save_dir, 'tf_sideL'), 'svg');
print('-dsvg', '-painters', fullfile(plot_save_dir, 'tf_sideL.svg'))
% exportgraphics(ftf, fullfile(plot_save_dir, 'tf_sideL.svg'), 'ContentType', 'vector');

%% TF and time alignment

tf_pref = [indexes_good.tf_short];
tf_sig  = indexes_good.tf_short_p<.01 & sign(indexes_good.tfExpF_short)==sign(indexes_good.tfExpS_short);
tf_pref(~tf_sig) = 0;
% tf_pref = sign(tf_pref);

time_pref = [indexes_good.timePreTF];
time_sig  = indexes_good.timePreTF_p<.01 & sign([indexes_good.timePreTF])==sign([indexes_good.timeBL]);
time_pref(~time_sig) = 0;
% time_pref = sign(time_pref);

time_tf_alignment = tf_pref .* time_pref;

% time_tf_alignment(time_tf_alignment>.05)=1; 
% time_tf_alignment(time_tf_alignment<-.05)=-1; 

cmap = create_custom_colormap(ops.colors.S, [1 1 1], ops.colors.F); %slanCM('bwr');

f_tftime = ccf_visual.visualize_neurons_on_atlas(neuron_coords, highlight_regions, ...
                                                 annotation_volume_path, structure_tree_path, ...
                                                 -time_tf_alignment, cmap);
caxis([-.025 .025])
colorbar

% and from alternate views
% view([90 90]);
% camorbit(0, 20, 'data', [0 1 0])
% camorbit(30, 0, 'data', [1 0 0])

%% Time pref
pref = [indexes_good.timePreTF] .* [indexes_good.conts];
time_sig  = [indexes_good.timePreTF_p] < .01 & sign([indexes_good.timePreTF])==sign([indexes_good.timeBL]);
pref(isnan(pref)) = 0;
pref(~time_sig) = 0;
% pref = sign(pref);
% colormap
cmap = create_custom_colormap(ops.colors.L, [0 0 0], ops.colors.E); 

f_time = ccf_visual.visualize_neurons_on_atlas(neuron_coords, highlight_regions, ...
                                               annotation_volume_path, structure_tree_path, ...
                                               pref, cmap);
                                           
saveas(f_time, fullfile(plot_save_dir, 'time_backL'));
print('-dsvg', '-painters', fullfile(plot_save_dir, 'time_backL.svg'))
                                           
% and from alternate views
view([90 90]);
camorbit(0, 20, 'data', [0 1 0])
camorbit(30, 0, 'data', [1 0 0])
saveas(f_time, fullfile(plot_save_dir, 'time_frontL'));
% saveas(f_time, fullfile(plot_save_dir, 'time_frontL'), 'pdf');
print('-dsvg', '-painters', fullfile(plot_save_dir, 'time_frontL.svg'))

view([90 90]);
saveas(f_time, fullfile(plot_save_dir, 'time_sideL'));
% saveas(f_time, fullfile(plot_save_dir, 'time_sidetL'), 'pdf');
print('-dsvg', '-painters', fullfile(plot_save_dir, 'time_sideL.svg'))

%% Lick mod

pref = [indexes_good.prelick];
lick_sig = [indexes_good.prelick_p] <.01;
pref(isnan(pref)) = 0;
pref(~lick_sig) = 0;
pref = sign(pref);

% colormap
cmap = create_custom_colormap(ops.colors.S_light, [.7 .7 .7], ops.colors.F_light); 

f_lick = ccf_visual.visualize_neurons_on_atlas(neuron_coords, highlight_regions, ...
                                               annotation_volume_path, structure_tree_path, ...
                                               pref, cmap);








