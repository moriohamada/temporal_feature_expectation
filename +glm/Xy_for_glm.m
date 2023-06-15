%% Make and save design matrices and spiking, for every unit
% 
% --------------------------------------------------------------------------------------------------
%%
% [db, ops] = switch_task_analysis_params();

ops.rmvStart         = 1;            % remove first n trials from each session
ops.performanceBin   = 30;           % calculate running hit/miss/fa etc rates from this many trials
ops.missThresh       = 1;            % remove periods where miss rate higher than this
ops.falseAlarmThresh = 1;            % remove periods where false alarm rate higher than this
ops.abortThresh      = 1;            % remove periods where abort rate higher than this
ops.combinedAbortFA  = 1;            % remove periods where combined false alarm/abort rate higher than this

ops.minFR     = .25; % Hz; minimum average firing rate
ops.minFRDrop = 0; % minimum that firing rate can drop to, as proportion of overall mean
ops.suOnly    = 1;  % logical; whether to use only neurons identified as single units (1) or include MUA (0)

ops.minTrialDur  = 2;
ops.tBin         = .01; % seconds; time to discretize GLM
ops.switchPeriod = 0;     % seconds; how long it takes to switch from fast/slow, around flip time 
ops.longBLStart  = 2;     % time to start long baseline regressor
ops.includeTrialOutcome = 0;
ops.includeDirection    = 0;
ops.includePhase        = 0;
ops.phaseSplit          = 30; % size of each phase bin 
ops.splitELtf           = 0;
ops.splitELlick         = 0;
ops.splitFStf           = 0;
ops.includeMotionEnergy = 1;
ops.includeRunSpeed     = 0;
ops.kFold               = 10;
ops.nLambdas            = 100;
ops.lambdas             = 0;%[0, logspace(-10, 0, 11)];
ops.maxTrials           = 1500;
ops.alpha               = 1e-6; % 0 is ridge; 1 is lasso
ops.tol                 = .05;
ops.maxFR               = 250; % max firing rate, in hz
ops.maxIter             = 800;

ops.rndSeed = 10;

%% Load in data for every mouse and session

dataset_file = fullfile(ops.dataDir, 'full_dataset.mat');
if ~isfile(dataset_file)
    [sessions, trials_all, daq_all, sp_all] = load_all_ephys_data(db, ops);
    save(dataset_file, 'db', 'ops', 'sessions', 'trials_all', 'daq_all', 'sp_all', '-v7.3');
else
    [sessions, trials_all, daq_all, sp_all] = loadVariables(dataset_file, 'sessions', 'trials_all', 'daq_all', 'sp_all');
end

% some trials structs have extra field ('sesions'): remove
for ii = 1:length(trials_all)
    if isfield(trials_all{ii}, 'session')
        trials_all{ii} = rmfield(trials_all{ii}, 'session');
    end
end

% store unit session, cid, roi label, and cg into single struct
neuron_info = collate_all_unit_info(sessions, sp_all);

% Remove sessions not in db
% [sessions, trials_all, daq_all, sp_all] = select_sessions_in_db(sessions, trials_all, daq_all, sp_all, db);
[sessions, trials_all, daq_all, sp_all] = utils.remove_bad_sessions(sessions, trials_all, daq_all, sp_all, ops);

% Add mouth opening to daq
daq_all = add_mouth_opening_to_daq(sessions, daq_all, ops);

%% Iterate through sessions, generate DM, Y vectors
target_dir  = '/mnt/ceph/public/projects/MoHa_20240218_SwitchChangeDetect_spForGLM/';
% ops.dataDir = '/mnt/winstor/swc/mrsic_flogel/public/projects/MoHa_20201102_SwitchChangeDetection/npx/';
% ops.alfDir  = '/mnt/winstor/swc/mrsic_flogel/public/projects/MoHa_20201102_SwitchChangeDetection/npx/';
ops.dataDir = '/mnt/ceph/public/projects/MoHa_20201102_SwitchChangeDetection/npx/';
ops.alfDir  = '/mnt/ceph/public/projects/MoHa_20201102_SwitchChangeDetection/npx/';
% ops.saveDir = '/mnt/winstor/swc/mrsic_flogel/public/projects/MoHa_20201102_SwitchChangeDetection/analysis_outputs/test'
% flip_times  = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');

animals = unique({sessions.animal});

for s = 1:length(sessions)
    fprintf('Session (%d/%d)\n', s, length(sessions));
    if isempty(sp_all{s}), continue; end
   
    % try
    animal  = sessions(s).animal;
    a_idx   = strcmp(animals,animal);
    session = sessions(s).session;
    cont    = sessions(s).contingency;
    trials  = trials_all{s};
    sp      = sp_all{s};
    daq     = daq_all{s};
 
    
    % load motion energy
    processed_dir = fullfile(ops.dataDir, animal, 'Processed data');
    sess_dirs     = dir2(processed_dir);
    sess_dir      = sess_dirs{contains(sess_dirs, session)};
    
    motE_dir      = fullfile(processed_dir, sess_dir, 'Cameras');
    motE_files    = dir2(motE_dir);
    if isempty(motE_files), continue; end
    motE_file     = motE_files{contains(motE_files, 'face_motion_energy.mat')};
    motE          = loadVariable(fullfile(motE_dir, motE_file), 'avg_energy');
    
    % and motE time axis
    sess_folders = dir2(processed_dir);
    sess_token   = sess_folders{find(contains(sess_folders, session))};

    daq_tmp = load(fullfile(processed_dir,sess_dir,'Nidaq', sprintf('%s_NIdaq_events.mat',sess_token)));
    daq.Front_cam = daq_tmp.NIdaq_events.Front_cam;
    clear daq_tmp;
    
    [features, trStarts] = extract_glm_features_final(trials, daq, motE, flip_times(a_idx), ops);
    
    % also save trial outcomes, start
    if ~ops.splitELtf
        dirName = 'featuresFull10ms';
    else
        dirName = 'featuresELsplit10ms';
    end
    if ~exist(fullfile(target_dir, dirName))
        mkdir(fullfile(target_dir, dirName));
    end
    save(fullfile(target_dir, dirName, sprintf('%s_%s.mat',animal,session)), 'features', 'trStarts', 'ops');
    
    
    parfor n = 1:length(sp.cids)
        % add st to features
        cid = sp.cids(n);
        st  = sp.st(sp.clu==cid);
        fr_mu = numel(st)/range(sp.st);
        if fr_mu<.1, continue; end
%         tic
%         features_n = add_spike_times_to_glm_features(features, trials, daq, st, ops);

%         [expt, dspec] = get_expt_dspec_for_glm(features_n, params, ops);
%         toc
        % save
        save_name = fullfile(target_dir, 'spikeTimes', sprintf('%s_%s_%d.mat', animal, session, cid));
        parfor_save(save_name, st)
%         keyboard
    end
    % catch me
    %     keyboard
    % end
%     keyboard
end

%%
function parfor_save(save_name, st)
save(save_name, 'st')
end
% function parfor_save(save_name, features_n, expt, dspec, ops)
% save(save_name, 'features_n', 'expt', 'dspec', 'ops')
% end