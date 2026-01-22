function calculate_unit_preferences(sessions, sp_all, ops)
% 
% Calculate TF, time, and lick modulation indexes for every unit
% 
% --------------------------------------------------------------------------------------------------


fprintf('Calculating preference indexes for each unit\n')

flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');
animals = unique({sessions.animal});


for s = 1:length(sessions)
    
    animal  = sessions(s).animal;
    session = sessions(s).session;
    
    fprintf('session %d/%d\n', s, length(sessions))
    if strcmp(session(1), 'h') % not recording session
        continue
    end
    
    sp = sp_all{s};
    cids = sp.cids;
    locs = sp.clu_locs';
    cgs = sp.cgs';

    nN   = length(cids);
    
    % get flip time
    animal_id = strcmp(animals, sessions(s).animal);
    flip_time = flip_times(animal_id);
   
    % get path to event psths
    psth_file = fullfile(ops.eventPSTHdir, sprintf('%s_%s.mat', animal, session));
    
    
    %% TF indexes - full, expf, exps
    
    tf_tax = loadVariable(psth_file, 'tf_tax');
    rel_win = isbetween(tf_tax, [min(ops.respWin.tfContext), max(ops.respWin.tf)]);
    outlier_types = {'FexpF', 'FexpS', 'SexpF', 'SexpS'};
    for ii = 1:length(outlier_types)
        outlier_type = outlier_types{ii};
        eval(sprintf('psth_%s = loadVariable(psth_file, ''psth_%s'');', outlier_type, outlier_type));
        eval(sprintf('psth_%s = psth_%s(:,:,rel_win);', outlier_type, outlier_type));
    end
    
     % take equal numbers of expF and expS
    if size(psth_FexpF,2) > size(psth_FexpS,2)
        longer = size(psth_FexpF,2);
        shorter = size(psth_FexpS,2);
        psth_F = cat(2, psth_FexpF(:,randperm(longer,shorter),:), psth_FexpS);
    else
        longer = size(psth_FexpS,2);
        shorter = size(psth_FexpF,2);
        psth_F = cat(2, psth_FexpF, psth_FexpS(:,randperm(longer,shorter),:));
    end
    
    if size(psth_SexpF,2) > size(psth_SexpS,2)
        longer = size(psth_SexpF,2);
        shorter = size(psth_SexpS,2);
        psth_S  = cat(2, psth_SexpF(:,randperm(longer,shorter),:), psth_SexpS);
    else
        longer = size(psth_SexpS,2);
        shorter = size(psth_SexpF,2);
        psth_S = cat(2, psth_SexpF, psth_SexpS(:,randperm(longer,shorter),:));
    end
    
    resp_t_short = isbetween(tf_tax, ops.respWin.tfShort);
    resp_t       = isbetween(tf_tax, ops.respWin.tf);
    
    % Full
    fast_resp = nanmean(psth_F(:,:,resp_t), 3);
    slow_resp = nanmean(psth_S(:,:,resp_t), 3);
    [index_tf, index_tf_p] = utils.calculate_preference_index(slow_resp, fast_resp, ops.nIter, 'peak');
    
    fast_resp = nanmean(psth_F(:,:,resp_t_short), 3);
    slow_resp = nanmean(psth_S(:,:,resp_t_short), 3);
    [index_tf_short, index_tf_short_p] = utils.calculate_preference_index(slow_resp, fast_resp, ops.nIter, 'peak');
    
    % expF
    fast_resp = nanmean(psth_FexpF(:,:,resp_t), 3);
    slow_resp = nanmean(psth_SexpF(:,:,resp_t), 3);
    [index_tfExpF, index_tfExpF_p] = utils.calculate_preference_index(slow_resp, fast_resp, ops.nIter, 'peak');
    
    fast_resp = nanmean(psth_FexpF(:,:,resp_t_short), 3);
    slow_resp = nanmean(psth_SexpF(:,:,resp_t_short), 3);
    [index_tfExpF_short, index_tfExpF_short_p] = utils.calculate_preference_index(slow_resp, fast_resp, ops.nIter, 'peak');
    
    %% Calculate time index (in two ways: from pre-outlier PSTH and long baseline)]
    
    % from tf pre-outlier period
    psth_expF = cat(2, psth_FexpF, psth_SexpF);
    psth_expS = cat(2, psth_FexpS, psth_SexpS);
    pre_tf = tf_tax < 0;
    
    expF_resp = nanmean(psth_expF(:,:,pre_tf),3);
    expS_resp = nanmean(psth_expS(:,:,pre_tf),3);
    
    [index_time_pretf, index_time_pretf_p] = utils.calculate_preference_index(expF_resp, expS_resp, ops.nIter, 'peak');
    
    clear psth_FexpF psth_SexpF psth_FexpS psth_SexpS expF_resp expS_resp
    
    % long bl
    [psth_bl, bl_tax] = loadVariables(psth_file, 'bl_psth', 'bl_tax');
    
    % from baseline
    windows = [2 flip_time-.5; flip_time+.5 11];
    bl_resp_early = nanmean(psth_bl(:,:,isbetween(bl_tax, windows(1,:))),3);
    bl_resp_late  = nanmean(psth_bl(:,:,isbetween(bl_tax, windows(2,:))),3);
    
    [index_time_bl, index_time_bl_p] = utils.calculate_preference_index(bl_resp_early, bl_resp_late, ops.nIter, 'peak');
    
    if strcmp(sessions(s).contingency, 'ESLF')
        index_time_bl = index_time_bl*-1;
    elseif strcmp(sessions(s).contingency, 'EFLS')
        index_time_bl = index_time_bl;
    else
        keyboard
    end
    
    clear psth_bl
    
    %% Pre-lick index - full, expF, expS
    
    % load fa psth
    [psth_faExpF, psth_faExpS, lick_tax] = ...
        loadVariables(psth_file, 'psth_FAexpF', 'psth_FAexpS', 'lick_tax');
    
    pre_lick = lick_tax<-1;
    lick_t   = isbetween(lick_tax, [-.25 -0]);
    
    % full
    fa_types = {'expF', 'exps'};
    psth_fa = [];
    for ii = 1:length(fa_types)
        fa_type = fa_types{ii};
        eval(['tmp = psth_fa' fa_type ';']);
        if ~isempty(tmp)
            if isempty(psth_fa)
                psth_fa = tmp;
            else
                psth_fa = cat(2, psth_fa, tmp);
            end
        end
    end
    lick_resp = nanmean(psth_fa(:,:,lick_t), 3);
    pre_resp  = nanmean(psth_fa(:,:,pre_lick),3 );
    
    [index_prelick, index_prelick_p] = utils.calculate_preference_index(pre_resp, lick_resp, ops.nIter, 'peak');
    
    % by expectation
    lick_resp = nanmean(psth_faExpF(:,:,lick_t), 3);
    pre_resp  = nanmean(psth_faExpF(:,:,pre_lick),3 );
    [index_prelickExpF, index_prelickExpF_p] = utils.calculate_preference_index(pre_resp, lick_resp, ops.nIter, 'peak');
    
    lick_resp = nanmean(psth_faExpS(:,:,lick_t), 3);
    pre_resp  = nanmean(psth_faExpS(:,:,pre_lick),3 );
    [index_prelickExpS, index_prelickExpS_p] = utils.calculate_preference_index(pre_resp, lick_resp, ops.nIter, 'peak');
    
    %% save
    
     indexes = table(...
                    repelem(animal, nN, 1), repelem(session,nN,1), cids, locs, cgs, ...
                    index_tf, index_tf_p, index_tfExpF, index_tfExpF_p, index_tfExpS, index_tfExpS_p, ...
                    index_tf_short, index_tf_short_p, index_tfExpF_short, index_tfExpF_short_p, index_tfExpS_short, index_tfExpS_short_p, ...
                    index_time_bl, index_time_bl_p, index_time_pretf, index_time_pretf_p, ...
                    index_prelick, index_prelick_p, index_prelickExpF, index_prelickExpF_p, index_prelickExpS, index_prelickExpS_p,...
                    'VariableNames', ...
                    {'animal', 'session', 'cid', 'loc','cg', ...
                     'tf', 'tf_p', 'tfExpF', 'tfExpF_p', 'tfExpS', 'tfExpS_p', ...
                     'tf_short', 'tf_short_p', 'tfExpF_short', 'tfExpF_short_p', 'tfExpS_short', 'tfExpS_short_p', ...
                     'timeBL', 'timeBL_p', 'timePreTF', 'timePreTF_p', ...
                     'prelick', 'prelick_p', 'prelickExpF', 'prelickExpF_p', 'prelickExpS', 'prelickExpS_p'});
                
    
    
    ind_save_file = fullfile(ops.indexesDir, sprintf('%s_%s_peak.mat', animal, session));
    save(ind_save_file, 'indexes')
end