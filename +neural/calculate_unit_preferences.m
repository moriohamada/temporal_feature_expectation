function calculate_unit_preferences(sessions, sp_all, ops)
% 
% Calculate TF, time, and lick modulation indexes for every unit
% 
% --------------------------------------------------------------------------------------------------


fprintf('Calculating preference indexes for each unit\n')

flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');
animals = unique({sessions.animal});

mkdir(ops.indexesDir)

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
    
    %keyboard % just make sure you actually want to run! this is slow
    
    %% TF indexes - short window, full, expf, exps
    
    tf_tax = loadVariable(psth_file, 'tf_tax');
    outlier_types = {'FexpF', 'FexpS', 'SexpF', 'SexpS'};
    for ii = 1:length(outlier_types)
        outlier_type = outlier_types{ii};
        eval(sprintf('psth_%s = loadVariable(psth_file, ''psth_%s'');', outlier_type, outlier_type));
    end
    
    psth_F  = cat(2, psth_FexpF, psth_FexpS);
    psth_S  = cat(2, psth_SexpF, psth_SexpS);
     
    resp_t_short = isbetween(tf_tax, ops.respWin.tfShort);
    pre_t        = isbetween(tf_tax, ops.respWin.tfContext);
    
    % Full 
    fast_resp = nanmean(psth_F(:,:,resp_t_short),3);
    slow_resp = nanmean(psth_S(:,:,resp_t_short),3);
    
    [index_tf_short, index_tf_short_p] = utils.calculate_preference_index(slow_resp, fast_resp, ops.nIter);
    
    % expF 
    fast_resp = nanmean(psth_FexpF(:,:,resp_t_short), 3);
    slow_resp = nanmean(psth_SexpF(:,:,resp_t_short), 3);
    [index_tfExpF_short, index_tfExpF_short_p] = utils.calculate_preference_index(slow_resp, fast_resp, ops.nIter);
    
    % expS 
    fast_resp = nanmean(psth_FexpS(:,:,resp_t_short), 3);
    slow_resp = nanmean(psth_SexpS(:,:,resp_t_short), 3);
    [index_tfExpS_short, index_tfExpS_short_p] = utils.calculate_preference_index(slow_resp, fast_resp, ops.nIter);
    
    clear fast_resp slow_resp

    %% TF indexes - long window, full, expf, exps
    tf_tax = loadVariable(psth_file, 'tf_tax');
    outlier_types = {'FexpF', 'FexpS', 'SexpF', 'SexpS'};
    for ii = 1:length(outlier_types)
        outlier_type = outlier_types{ii};
        eval(sprintf('psth_%s = loadVariable(psth_file, ''psth_%s'');', outlier_type, outlier_type));
    end
    
    psth_F  = cat(2, psth_FexpF, psth_FexpS);
    psth_S  = cat(2, psth_SexpF, psth_SexpS);
     
    resp_t = isbetween(tf_tax, ops.respWin.tf);
    pre_t  = isbetween(tf_tax, ops.respWin.tfContext);
    
    % Full 
    fast_resp = nanmean(psth_F(:,:,resp_t),3);
    slow_resp = nanmean(psth_S(:,:,resp_t),3);
    
    [index_tf, index_tf_p] = utils.calculate_preference_index(slow_resp, fast_resp, ops.nIter);
    
    % expF 
    fast_resp = nanmean(psth_FexpF(:,:,resp_t), 3);
    slow_resp = nanmean(psth_SexpF(:,:,resp_t), 3);
    [index_tfExpF, index_tfExpF_p] = utils.calculate_preference_index(slow_resp, fast_resp, ops.nIter);
    
    % expS 
    fast_resp = nanmean(psth_FexpS(:,:,resp_t), 3);
    slow_resp = nanmean(psth_SexpS(:,:,resp_t), 3);
    [index_tfExpS, index_tfExpS_p] = utils.calculate_preference_index(slow_resp, fast_resp, ops.nIter);
    
    clear fast_resp slow_resp
    %% Calculate time index (in two ways: from pre-outlier PSTH and long baseline)]
    
    % from tf pre-outlier period
    psth_expF = cat(2, psth_FexpF, psth_SexpF);
    psth_expS = cat(2, psth_FexpS, psth_SexpS);
    pre_tf = isbetween(tf_tax, ops.respWin.tfContext);
    
    expF_resp = nanmean(psth_expF(:,:,pre_tf),3);
    expS_resp = nanmean(psth_expS(:,:,pre_tf),3);
    
    [index_time_pretf, index_time_pretf_p] = utils.calculate_preference_index(expF_resp, expS_resp, ops.nIter);
    
    clear psth_FexpF psth_SexpF psth_FexpS psth_SexpS expF_resp expS_resp
    
    % long bl
    [psth_bl, bl_tax] = loadVariables(psth_file, 'bl_psth', 'bl_tax');
    
    % from baseline
    windows = [2 flip_time-.5; flip_time 11];
    bl_resp_early = nanmean(psth_bl(:,:,isbetween(bl_tax, windows(1,:))),3);
    bl_resp_late  = nanmean(psth_bl(:,:,isbetween(bl_tax, windows(2,:))),3);
    
    [index_time_bl, index_time_bl_p] = utils.calculate_preference_index(bl_resp_early, bl_resp_late, ops.nIter);
    
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
    lick_t   = isbetween(lick_tax, [-.2 -0]);
    
    % full
    fa_types = {'ExpF', 'ExpS'};
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
    
    [index_prelick, index_prelick_p] = utils.calculate_preference_index(pre_resp, lick_resp, ops.nIter);
    
    % by expectation
    lick_resp = nanmean(psth_faExpF(:,:,lick_t), 3);
    pre_resp  = nanmean(psth_faExpF(:,:,pre_lick),3 );
    [index_prelickExpF, index_prelickExpF_p] = utils.calculate_preference_index(pre_resp, lick_resp, ops.nIter);
    
    lick_resp = nanmean(psth_faExpS(:,:,lick_t), 3);
    pre_resp  = nanmean(psth_faExpS(:,:,pre_lick),3 );
    [index_prelickExpS, index_prelickExpS_p] = utils.calculate_preference_index(pre_resp, lick_resp, ops.nIter);
    
    clear psth_faExpF psth_faExpS
    
    %% save
    
    indexes = table(...
    repelem(animal, nN, 1), repelem(session,nN,1), cids, locs, cgs, ...
    index_tf_short, index_tf_short_p, index_tfExpF_short, index_tfExpF_short_p, index_tfExpS_short, index_tfExpS_short_p, ... 
    index_tf, index_tf_p, index_tfExpF, index_tfExpF_p, index_tfExpS, index_tfExpS_p, ...
    index_time_bl, index_time_bl_p, index_time_pretf, index_time_pretf_p, ...
    index_prelick, index_prelick_p, index_prelickExpF, index_prelickExpF_p, index_prelickExpS, index_prelickExpS_p,...
    'VariableNames', ...
    {'animal', 'session', 'cid', 'loc','cg', ...
     'tf_short', 'tf_short_p', 'tfExpF_short', 'tfExpF_short_p', 'tfExpS_short', 'tfExpS_short_p', ...
     'tf', 'tf_p', 'tfExpF', 'tfExpF_p', 'tfExpS', 'tfExpS_p', ...
     'timeBL', 'timeBL_p', 'timePreTF', 'timePreTF_p', ...
     'prelick', 'prelick_p', 'prelickExpF', 'prelickExpF_p', 'prelickExpS', 'prelickExpS_p'});
    
    
    ind_save_file = fullfile(ops.indexesDir, sprintf('%s_%s.mat', animal, session));
    save(ind_save_file, 'indexes')
    
    clear indexes
end