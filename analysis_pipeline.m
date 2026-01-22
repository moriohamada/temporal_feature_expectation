%% Main wrapper code for running behaviour and ephys analyses
% 
% Code for generating main paper figures, and saving source data as csvs
% 
% --------------------------------------------------------------------------------------------------
%%
clear; clc; close all
%%
addpath(genpath('/home/morio/Documents/MATLAB/General'));
addpath(genpath('/home/morio/Documents/MATLAB/switch-task/final_pipeline'));
addpath(genpath('/home/morio/Documents/MATLAB/NPX/spikes-master/'));

graphics_small;

%% Specify data and options

[db, ops] = switch_task_analysis_params();

ops.saveFigs = 0; % whether to save figures

%% Load in data for every mouse and session

dataset_file = fullfile(ops.dataDir, 'full_dataset.mat');
if ~isfile(dataset_file)
    [sessions, trials_all, daq_all, sp_all] = utils.load_all_ephys_data(db, ops);
    % sp_all = utils.remove_nonROI_units(sp_all); % now done in loading phase
    % Add mouth opening to daq
    daq_all = utils.add_mouth_opening_to_daq(sessions, daq_all, ops);
    % add re-extracted frame times
    daq_all = utils.add_corrected_frame_times(sessions, trials_all, daq_all);
    save(dataset_file, 'db', 'ops', 'sessions', 'trials_all', 'daq_all', 'sp_all', '-v7.3');
else
    [sessions, trials_all, daq_all, sp_all] = ...
        loadVariables(dataset_file, 'sessions', 'trials_all', 'daq_all', 'sp_all');
end

% some trials structs have extra field ('sesions'): remove, and remove bad sessions
for ii = 1:length(trials_all)
    if isfield(trials_all{ii}, 'session')
        trials_all{ii} = rmfield(trials_all{ii}, 'session');
    end
    trials_all{ii} = utils.apply_tr_removal(trials_all{ii}, ops);
end

% remove any sessions with too few hits or valid trails
[sessions, trials_all, daq_all, sp_all] = ...
    utils.remove_bad_sessions(sessions, trials_all, daq_all, sp_all, ops);

% store unit session, cid, roi label, and cg into single struct
neuron_info = utils.collate_all_unit_info(sessions, sp_all);

% remove non-db sessions
[sessions, trials_all, daq_all, sp_all] = ...
    utils.remove_sessions_not_in_db(sessions, trials_all, daq_all, sp_all, db);
 

%% Behavioural analyses (Figures 1 & 2)

behavioural_analyses(sessions, trials_all, ops);

% 
%% Preprocess neural responses: extract average activity and preference indexes
%  Note: this takes a long time to run! do overnight, or significantly decrease ops.nIter

% keyboard; % pause in case of accidental run
% last run: tf outlier at 1sd
ops.tfOutlier = 1;
neural.calculate_unit_responses(sessions, trials_all, daq_all, sp_all, ops)

% % also make 25ms version - faster index calc
ops.spBinWidth = 25;
ops.avgPSTHdir =  '/media/morio/Data_Fast/switch_task_revisions/avg_resps_25ms/';
ops.eventPSTHdir = '/media/morio/Data_Fast/switch_task_revisions/event_resps_25ms/';
neural.calculate_unit_responses(sessions, trials_all, daq_all, sp_all, ops);

% free up ram if needed; will need to reload these 
for s = 1:length(sp_all)
    if isempty(sp_all{s}), continue; end
    sp_all{s}.st = [];
    sp_all{s}.clu = [];
end
clear daq_all trials_all
 
neural.calculate_unit_preferences(sessions, sp_all, ops)
% neural.calculate_adaptive_tf_index(sessions, sp_all, ops) % to do: integrate into main preference calc



%% Load averaged responses and indexes

if exist(fullfile(ops.respsIndsDir, 'indexes_resps.mat'), 'file')
    [indexes, avg_resps, t_ax] = loadVariables(fullfile(ops.respsIndsDir, 'indexes_resps.mat'), ...
                                               'indexes', 'avg_resps', 't_ax');
else
    [indexes, avg_resps, t_ax] = neural.load_indexes_resps(sessions, ops);
    indexes = neural.calculate_tf_preference_zscored_with_stats(t_ax, indexes, ops);
    avg_resps = utils.match_FS_sds(avg_resps, indexes);
    save(fullfile(ops.respsIndsDir, 'indexes_resps.mat'), 'indexes', 'avg_resps', 't_ax', '-v7.3')
end

% indexes = neural.calculate_tf_preference_zscored(avg_resps, t_ax, indexes, ops);

%% Visualize anatomical positions

ccf_visual.visualize_anatomical_positions_wrapper(sessions, sp_all, avg_resps, indexes, ops)

%% Single unit PSTHS

single_unit_responses_basic_wrapper(sessions, trials_all, daq_all, sp_all, ops)

%% Neural responses (Figure 3)

neural_responses(avg_resps, t_ax, indexes, neuron_info, ops)

%% Time-TF interactions (Figure 4)

expectation_analyses(avg_resps, t_ax, indexes, ops)

%% Movement dimension analyses (Figure 5)

preparatory_analyses(avg_resps, t_ax, indexes, sessions, trials_all, daq_all, sp_all, neuron_info, ops)

%% Neurometric model (Figure 6)

neurometric_analyses()