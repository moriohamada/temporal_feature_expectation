function [projs_iters, dims_iters] = ...
         dimension_extraction_bootstrapped(avg_resps, t_ax, indexes, sessions, trials_all, daq_all, sp_all, ops)
% 
% Performs iterations of extracting movement potent and null dimensions, fast/slow TF dimensions, 
% and projecting  neural activity around events of interest. 

%% define units of interest

multi = utils.get_multi(avg_resps); 
rois = utils.group_rois;
in_roi = utils.get_units_in_area(indexes.loc, rois{3,2}); % MOs/CP only

sel = ~multi & in_roi;
avg_resps = utils.match_FS_sds(avg_resps, indexes);

% flip baseline activity of eslf units
resps = flip_eslf_baseline(avg_resps(sel,:), indexes.conts(sel));
inds  = indexes(sel,:);

resps.FRsd = resps.FRsd*10; % scaling
%% First load N, M lick info for each session 
t_ax = [-1.99:.01:1]; % time axis around licks to get FR and motion energy

inc_units = zeros(height(resps),1);
motE_dir = fullfile('/media/morio/Data_Fast/switch_task/', 'perilickMotE'); 
tfis = {};

NM_data_path = '/media/morio/Data_Fast/switch_task_paper/nullspace_tmp/periLickNM2.mat';
% NM_data_path = '/media/morio/Data_Fast/nullspace_tmp/periLickNM_su_shift_withM.mat';

if exist(NM_data_path, 'file')
    load(NM_data_path);
else
    for s = 1:length(sessions)
        
        fprintf('session %d/%d\n', s, length(sessions));
        animal  = sessions(s).animal; 
        session = sessions(s).session;
        cont    = sessions(s).contingency;
        
        sess_units = strcmp(cellstr(resps.animal), animal) &  strcmp(cellstr(resps.session), session);
        
        if sum(sess_units)<5, continue; end % fewer than 5 units in roi recorded
        if strcmp(session(1), 'h'), continue; end % not recording sessions
        
        trials = trials_all{s};
        daq    = daq_all{s};
        sp     = sp_all{s};
        
        if sum(strcmp({trials.trialOutcome}, 'Hit') & ~strcmp({trials.trialType}, 'zero')) < 50 % min 50 hits
            continue; 
        end
        
        % Also make sure at least 5 for each hit TF, excluding zeros
        hit_tfs = [trials(strcmp({trials.trialOutcome}, 'Hit')).changeTF];
        hit_tfs(hit_tfs==2) = []; % ignore zero change
        [uniqueValues, ~, idx] = unique(hit_tfs);
        counts = histc(idx, 1:numel(uniqueValues));
        if any(counts<5), continue; end
        
        
        processed_dir = fullfile(ops.npxDir, animal, 'Processed data');
        sess_dirs     = dir2(processed_dir);
        sess_dir      = sess_dirs{contains(sess_dirs, session)};
        if isempty(sess_dir), continue; end
        
        lick_data_path = fullfile(motE_dir, sprintf('%s_%s.mat', animal, session));
        if ~exist(lick_data_path, 'file'), continue; end
        
        % Load N, M, licks
        [Ns{s,1}, Ms{s,1}, lick_inf{s,1}, frstats{s,1}, frstats{s,2}] = ...
                nullspace.load_session_data(trials, daq, sp, resps, sess_units, t_ax, lick_data_path, ops);
            
        % also store TF preferences
        tfis{s,1} = inds(sess_units, {'tf_short', 'tf_short_p', ...
                                      'tfExpF_short', 'tfExpF_short_p', ...
                                      'tfExpS_short','tfExpS_short_p', ...
                                      'tf_z_peakD'});
        inc_units(sess_units) = 1;
        if strcmp(cont, 'EFLS'), cont = 1; else, cont = -1; end
        units_conts(sess_units) = cont;
        
    end
    save(NM_data_path, 'Ns', 'Ms', 'lick_inf', 'tfis', 'frstats', 'inc_units', '-v7.3');
end

%% Run resampling iterations through trials and neurons 
nIter =  ops.nIter;
projs_iters   = cell(nIter,1);
dims_iters    = cell(nIter,1);
tmp_savedir = '/media/morio/Data_Fast/switch_task_paper/nullspace_tmp';
% tmp_savedir = '/media/morio/Data_Fast/nullspace_tmp';

% v2 - good for paper
% v3 - trying shuffled movement dims to control tf preferene
for iter = 1:nIter
    fprintf('Iteration %d/%d\n', iter, nIter)
    if exist(fullfile(tmp_savedir, sprintf('moveSpace_bsunits_iter%d_v3.mat', iter)), 'file')
        [projs, dims] = ...
            loadVariables(fullfile(tmp_savedir, ...
            sprintf('moveSpace_bsunits_iter%d_v3.mat', iter)), ...
            'projs', 'dims');
        projs_iters{iter} = projs;
        dims_iters{iter}  = dims;
        clear projs dims
    else
        [projs, dims] = ...
            nullspace.resampling_dim_extraction(Ns, Ms, tfis, lick_inf,  resps, inc_units, sessions, trials_all, daq_all, ops);
        
        save(fullfile(tmp_savedir, sprintf('moveSpace_bsunits_iter%d_v3.mat', iter)), ...
            'projs', 'dims', '-v7.3')
        projs_iters{iter} = projs;
        dims_iters{iter}  = dims;
    end
end


end





function resps = flip_eslf_baseline(resps, conts)

resps.bl(conts==-1,:) = -1*(resps.bl(conts==-1,:));

end