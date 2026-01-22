function preparatory_analyses(sessions, trials_all, daq_all, sp_all, neuron_info, ops)
% NULL_SPACE_ANALYSIS_WRAPPER_CLEAN: Main analysis pipeline for neural null space
%
% This function performs a complete analysis of neural activity, identifying 
% movement-related dimensions and their relationship to temporal frequency preferences.
%
% Analysis pipeline:
% 1) Load and filter data
% 2) Identify movement-related dimensions across sessions
% 3) Bootstrap sampling for statistical analysis
% 4) Analyze alignments between dimensions
% 5) Predict behavior from neural projections
% 6) Test dimension rotation
% 7) Visualize and save results
%
% Inputs:
%   sessions     - Session information
%   trials_all   - Trial data for all sessions
%   daq_all      - Data acquisition info
%   sp_all       - Spike data
%   neuron_info  - Neuron metadata
%   ops          - Analysis options

%%
ops.nDim_N = 2;
ops.nDim_M = 1;
ops.nDim_denoise = 12;

%% 1. Extract dimensions
[projs_iters, dims_iters] = ...
    nullspace.dimension_extraction_bootstrapped(avg_resps, t_ax, indexes, sessions, trials_all, daq_all, sp_all, ops);

%% 2. Visualize projections & alignment

% Group events into types and plot
ev_groups = { {'FexpF', 'FexpS', 'SexpF', 'SexpS'}, [ops.colors.F; ops.colors.F*.6; ops.colors.S*.6; ops.colors.S], [-.5 1]; ...
             {'hitE1', 'hitE2', 'hitE3', 'hitE4', 'hitE5', 'hitE6', 'hitE7'}, RedGreyBlue(7), [-.5 1]; ...
             {'hitLickE1', 'hitLickE2', 'hitLickE3', 'hitLickE4', 'hitLickE5', 'hitLickE6', 'hitLickE7'}, RedGreyBlue(7), [-2 1]};           
% dim_names = {'movement_potent', 'movement_null1', 'movement_null2', 'tf_fast', 'tf_slow', 'tf_none'};
dim_names = {'movement_potent', 'movement_null1', 'movement_null2'};
% dim_names = {'tf_fast', 'tf_slow', 'tf_none'};

[projs_iters_aligned, dims_iters_aligned] = nullspace.align_projection_directions_from_dims(projs_iters, dims_iters);
% add tf F and S
for ii = 1:length(projs_iters_aligned)
    dims = fields(projs_iters_aligned{ii});
    for dd = 1:numel(dims)
        projs_iters_aligned{ii}.(dims{dd}).tfF = (projs_iters_aligned{ii}.(dims{dd}).FexpF + projs_iters_aligned{ii}.(dims{dd}).FexpS)/2;
        projs_iters_aligned{ii}.(dims{dd}).tfS = (projs_iters_aligned{ii}.(dims{dd}).SexpF + projs_iters_aligned{ii}.(dims{dd}).SexpS)/2;
    end
end

f_resps_iters = nullspace.visualize_xval_movementSpace_activity(projs_iters_aligned, t_ax, ev_groups, dim_names, ops);
f_motE_iters  = nullspace.visualize_xval_motionEnergyDR(projs_iters, ops);


%% 3. Visualize TF preference

alignments = nullspace.test_xval_alignments(projs_iters_aligned, dims_iters_aligned, ops);
[f_resp, f_dim] = nullspace.visualize_moveSpace_alignment(alignments, ops)

%% 4. Visualize pre-change projections
[f_rt_pred_quant, f_rt_pred_vis] = nullspace.predict_rt_from_movespace_projections(projs_iters_aligned, t_ax, ops);

