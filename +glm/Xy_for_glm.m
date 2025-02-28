function Xy_for_glm(sessions, trials_all, daq_all, sp_all, neuron_info, ops)
% Prepare design matrices per session, and extract spike times per
% unit for efficiently running GLM
% 

target_dir  = '/mnt/ceph/public/projects/MoHa_20260120_SwitchChangeDetect_spForGLM/';
if ~exist(target_dir, 'dir')
    mkdir(target_dir);
end
animals = unique({sessions.animal});
glm_ops = glm.set_glm_ops;

for s = 1:length(sessions)

    fprintf('Session (%d/%d)\n', s, length(sessions));
    if isempty(sp_all{s}), continue; end
   
    animal  = sessions(s).animal;
    a_idx   = strcmp(animals,animal);
    session = sessions(s).session;
    cont    = sessions(s).contingency;
    trials  = trials_all{s};
    sp      = sp_all{s};
    daq     = daq_all{s};

    % Load motion energy
    processed_dir = fullfile(ops.npxDir, animal, 'Processed data');
    sess_dirs     = dir2(processed_dir);
    sess_dir      = sess_dirs{contains(sess_dirs, session)};

    motE_dir      = fullfile(processed_dir, sess_dir, 'Cameras');
    motE_files    = dir2(motE_dir);
    if ~isempty(motE_files)
        motE_file     = motE_files{contains(motE_files, 'face_motion_energy.mat')};
        motE          = loadVariable(fullfile(motE_dir, motE_file), 'avg_energy');
        % and motE time axis
        sess_folders = dir2(processed_dir);
        sess_token   = sess_folders{find(contains(sess_folders, session))};
        daq_tmp = load(fullfile(processed_dir,sess_dir,'Nidaq', sprintf('%s_NIdaq_events.mat',sess_token)));
        daq.Front_cam = daq_tmp.NIdaq_events.Front_cam;
    else
        motE = [];
    end
    
    clear daq_tmp;

    %% extract features according to glm_ops

    [features, trStarts] = glm.extract_features(trials, daq, motE, glm_ops);

    % also save trial outcomes, start
    if ~glm_ops.splitELtf && ~glm_ops.splitFStf
        dirName = 'featuresFull10ms';
    elseif ~glm_ops.splitELtf && glm_ops.splitFStf
        dirName = 'featuresFSsplit10ms';
    elseif glm_ops.splitELtf && ~glm_ops.splitFStf
        dirName = 'featuresELsplit10ms';
    else
         dirName = 'featuresFSELsplit10ms';
    end
    if ~exist(fullfile(target_dir, dirName))
        mkdir(fullfile(target_dir, dirName));
    end
    save(fullfile(target_dir, dirName, sprintf('%s_%s.mat',animal,session)), 'features', 'trStarts', 'glm_ops');
    

    %% get spike times
    if ~exist(fullfile(target_dir, 'spikeTimes'), 'dir')
        mkdir(fullfile(target_dir, 'spikeTimes'));
    end
    parfor n = 1:length(sp.cids)
        % add st to features
        cid = sp.cids(n);
        st  = sp.st(sp.clu==cid);
        fr_mu = numel(st)/range(sp.st);
        if fr_mu<.1, continue; end

        save_name = fullfile(target_dir, 'spikeTimes', sprintf('%s_%s_%d.mat', animal, session, cid));
        parfor_save(save_name, st)
    end


end

end

function parfor_save(save_name, st)
save(save_name, 'st')
end