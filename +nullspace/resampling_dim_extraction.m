function [projs, dims] =  resampling_dim_extraction(Ns, Ms, tfis, lick_inf, resps, inc_units, sessions, trials_all, daq_all, ops)
% 
% Randomly sample half trials and bootstrap sample neurons by session
% 
% ---------------------------------------------------------------------------------------------------

%%
pTrain = 0.5;
tf_motE_dir = fullfile('/media/morio/Data_Fast/switch_task/', 'periTFMotE');
tmp_savedir = '/media/morio/Data_Fast/switch_task_paper/nullspace_tmp';
change_TF_vals = [0.25, 1, 1.5, 2.5, 3, 3.75];
 
resps = resps(logical(inc_units),:);
iter_resps = resps([],:);
tf_prefs = vertcat(tfis{:});
iter_tfis  = tf_prefs([],:);
Ms_train = {}; Ms_valid = {}; Ns_train = {}; Ns_valid = {}; Mtf={};

t_ax = [-1.99:.01:1]; % time axis around licks to get FR and motion energy

for s = 1:length(sessions)
    if isempty(Ns{s}), continue; end
    animal  = sessions(s).animal;
    session = sessions(s).session;

    N = Ns{s}; M = Ms{s}; licks = struct2table(lick_inf{s}); tf_pref = tfis{s};
    
    trials = trials_all{s};
    daq = daq_all{s};
    nTr = length(trials);
    nTrain = ceil(nTr * pTrain);
    
    % make sure all tf changes are included in training set
    all_changes_inc = 0;
    reshuffles = 0;
    while ~all_changes_inc
        ids = randperm(nTr);
        train_trs = ids(1:nTrain);
        valid_trs = ids(nTrain+1:end);
        
        trials_train = trials(train_trs);
        hits = strcmp({trials_train.trialOutcome}, 'Hit') & ...
            ~contains({trials_train.trialType}, 'U')   & ...
            [trials_train.changeTF] ~= 2;
        hitTFs = [trials_train(hits).changeTF];
        hitTF_counts_train = histc(hitTFs, change_TF_vals);
        
        trials_valid = trials(valid_trs);
        hits = strcmp({trials_valid.trialOutcome}, 'Hit') & ...
                       ~contains({trials_valid.trialType}, 'U')   & ...
                       [trials_valid.changeTF] ~= 2;
        hitTFs = [trials_valid(hits).changeTF];
        hitTF_counts_valid = histc(hitTFs, change_TF_vals);
        
        if all(hitTF_counts_train >= 1) && all(hitTF_counts_valid >= 1)
            all_changes_inc = true; break
        end
        reshuffles = reshuffles + 1;
        if reshuffles > 100
            keyboard
        end
    end
    % bootstrap sample units
    nN = size(N,1);
    nF_all = sum(tf_pref{:, 'tf_short'}>0 & tf_pref{:, 'tf_short_p'}<.05 & tf_pref{:,'tf_z_peakD'}>0);
    nS_all = sum(tf_pref{:, 'tf_short'}<0 & tf_pref{:, 'tf_short_p'}<.05 & tf_pref{:,'tf_z_peakD'}<-0);
    if min([nF_all, nS_all])<3, continue; end
    nF = 0; nS = 0;
    while nF<2 | nS<2
        iter_units = sort(datasample(1:nN, nN, 'Replace',true))';
        nF = sum(tf_pref{iter_units, 'tf_short'}>0 & tf_pref{iter_units, 'tf_short_p'}<.05 & tf_pref{iter_units,'tf_z_peakD'}>0);
        nS = sum(tf_pref{iter_units, 'tf_short'}<0 & tf_pref{iter_units, 'tf_short_p'}<.05 & tf_pref{iter_units,'tf_z_peakD'}<-0);
    end
    
    % get new N and M for training and validation sets
    train_lick_ids = ismember(licks.trial, train_trs);
    valid_lick_ids = ismember(licks.trial, valid_trs);
    if any(isnan(N(:))), continue;  end
    Ns_train{s} = N(iter_units, train_lick_ids, :);
    Ns_valid{s} = N(iter_units, valid_lick_ids, :);
    Ms_train{s} = M(:, train_lick_ids, :);
    Ms_valid{s} = M(:, valid_lick_ids, :);
    licks_train{s} = licks(train_lick_ids, :);
    licks_valid{s} = licks(valid_lick_ids, :);
    
    sess_units = find(strcmp(cellstr(resps.animal), animal) &  strcmp(cellstr(resps.session), session)); 
    
    iter_resps = vertcat(iter_resps, resps(sess_units(iter_units),:));
    iter_tfis  = vertcat(iter_tfis,  tf_prefs(sess_units(iter_units),:));
    
    % load peri-TF motE - but remove side views!
    [periTF_motE, exp, tf_dir] = loadVariables(fullfile(tf_motE_dir, sprintf('%s_%s.mat', animal, session)), 'M', 'exp', 'tf_dir');
    periTF_motE(2,:,:) = periTF_motE(2,:,:) * 0;
    periTF_motE(3,:,:) = periTF_motE(3,:,:) * 0;
    % pick random half
    inc_pulses = randperm(size(periTF_motE,2), round(size(periTF_motE,2)/2));
    periTF_motE = periTF_motE(:,inc_pulses,:);
    exp = exp(inc_pulses);
    tf_dir = tf_dir(inc_pulses);
    % get tf types (fexpf, fexps etc)
    M_fexpf = nanmean(periTF_motE(:, exp== 1 & tf_dir== 1, :),2);
    M_fexps = nanmean(periTF_motE(:, exp==-1 & tf_dir== 1, :),2);
    M_sexpf = nanmean(periTF_motE(:, exp== 1 & tf_dir==-1, :),2);
    M_sexps = nanmean(periTF_motE(:, exp==-1 & tf_dir==-1, :),2);
    Mtf{s} = cat(2, M_fexpf, M_fexps, M_sexpf, M_sexps);
end


% calulate movement dims & tf dims 
combinedOutputs = cellfun(@(n,m,l) nullspace.average_by_lick_type_wrapper(n,m,l,t_ax,'TFval'), ...
    Ns_train, Ms_train, licks_train, 'UniformOutput', false);
% % Extract separate Ns and Ms cell arrays
N_avg = cellfun(@(c) c{1}, combinedOutputs, 'UniformOutput', false);
M_avg = cellfun(@(c) c{2}, combinedOutputs, 'UniformOutput', false);
N = vertcat(N_avg{:});
M = vertcat(M_avg{:});
[Mdr,Ndr,coeffN,coeffM] = nullspace.pca_dim_reduction(N, M, t_ax, ops);
% Identify Null/Potent dims
[W_toPot, W_toNull, N_pot, N_null] = nullspace.calculate_movement_dims(Ndr, Mdr, coeffN, coeffM, t_ax, ops);

dims = struct();
dims.movement_potent = W_toPot(1,:)';
for ii = 1:ops.nDim_N
    dims.(sprintf('movement_null%d', ii)) = W_toNull(ii,:)';
end
F = iter_tfis{:,'tf_short'}>0 & iter_tfis{:,'tf_short_p'}<0.05 & iter_tfis{:,'tf_z_peakD'}>0;
S = iter_tfis{:,'tf_short'}<0 & iter_tfis{:,'tf_short_p'}<0.05 & iter_tfis{:,'tf_z_peakD'}<-0;
N = iter_tfis{:,'tf_short_p'}>.1 & abs(iter_tfis{:,'tf_short'})<.05;
W_tf = normc(double([F, S, N]));
dims.tf_fast = W_tf(:,1); dims.tf_slow = W_tf(:,2); dims.tf_none = W_tf(:,3);

% also by expectation, to test rotations
tf_sensitive = (iter_tfis{:,'tfExpF_short_p'}<.05 & iter_tfis{:,'tfExpS_short_p'}<.05 & abs(iter_tfis{:,'tf_z_peakD'})>0);
F_expF = iter_tfis{:,'tfExpF_short'}>0 & tf_sensitive;
F_expS = iter_tfis{:,'tfExpS_short'}>0 & tf_sensitive;
S_expF = iter_tfis{:,'tfExpF_short'}<0 & tf_sensitive;
S_expS = iter_tfis{:,'tfExpS_short'}<0 & tf_sensitive;
W_tf_exp = normc(double([F_expF, F_expS, S_expF, S_expS]));
dims.tf_FexpF = W_tf_exp(:,1);
dims.tf_FexpS = W_tf_exp(:,2);
dims.tf_SexpF = W_tf_exp(:,3);
dims.tf_SexpS = W_tf_exp(:,4);

% also store F/S dims projected onto movement pot and null
dims.F_proj_null1 = dims.tf_fast .* dims.movement_null1; dims.F_proj_null1 = dims.F_proj_null1/norm(dims.F_proj_null1);
dims.S_proj_null1 = dims.tf_slow .* dims.movement_null1; dims.S_proj_null1 = dims.S_proj_null1/norm(dims.S_proj_null1);

% also store control dimensions for potent and null
dims.movement_potent_shuffled = dims.movement_potent(randperm(length(dims.movement_potent)));
dims.movement_null1_shuffled = dims.movement_null1(randperm(length(dims.movement_null1)));
dims.movement_null2_shuffled = dims.movement_null2(randperm(length(dims.movement_null2)));

% project
projs = nullspace.project_resps_onto_ax(iter_resps, dims);
% get Mdr around tf pulses
Mtfs = vertcat(Mtf{:});
rmv = all(isnan(Mtfs), [2, 3]);
Mtfs(rmv,:,:) = [];
 MdrTF = squeeze(pagemtimes(coeffM(:,1)', Mtfs));% 
projs.Mdr.FexpF = MdrTF(1,:);
projs.Mdr.FexpS = MdrTF(2,:);
projs.Mdr.SexpF = MdrTF(3,:);
projs.Mdr.SexpS = MdrTF(4,:);
for ii = 1:6 % each change
    ids = [1:300] + (ii-1)*300;
    projs.Mdr.(sprintf('hitLickE%d',ii)) = Mdr(ids);
end 

end



