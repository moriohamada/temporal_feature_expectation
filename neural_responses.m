function neural_responses(avg_resps, t_ax, indexes, neuron_info, ops)
% 
% load average responses, preference indexes, glm kernels; visualize responses and TDR projections.
% 
% --------------------------------------------------------------------------------------------------


if ~exist(fullfile(ops.saveDir, 'neural')), mkdir(fullfile(ops.saveDir, 'neural')); end

%% Plot all TF responsive unit heatmaps, and averaged by preference

neural.plot_tf_lick_resps_heatmap(avg_resps, t_ax, indexes, ops);

neural.plot_average_resps_by_tf_pref(avg_resps, t_ax, indexes, ops);
neural.sliding_correlation_analysis(avg_resps, t_ax, indexes, ops);

%% Scatter plot all units selectivity index

neural.scatter_unit_preferences(avg_resps, indexes, ops);

%% TDR

% Load in glm kernels
glm_kernels = glm.load_glm_kernels(neuron_info, ops, 'tdr');

tdr_ax = tdr.extract_axes(indexes, avg_resps, glm_kernels, ops);
tdr.visualize_basic_responses(tdr_ax, avg_resps, t_ax, glm_kernels, ops);



