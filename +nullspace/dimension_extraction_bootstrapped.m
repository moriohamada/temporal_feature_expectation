function null_space_analysis_wrapper_v3(sessions, trials_all, daq_all, sp_all, neuron_info,  ops)
% 
% Cleaned up version of null_space_analysis_wrapper.m
% 
% This code will: 
% 1) Identify movement-related dimensions combining data across all sessions, for visualization
% 2) Randomly sample trials and units to generate distributions of movement-related dims, as well as
%    fast/slow axes defined by TDR.
% 3) Quantify alignment of F/S dims to movement-related dims
% 4) Project TF pulse responses onto movement-related dims, and quantify selectivity
% 5) Assess rotation of F/S axes
% 6) Assess rotation of premotor axis
% 7) Predict behaviour from projections along F/S & movement-related axes:
%    - reaction times to small changes
%    - early lick probability (do EL psychometric, but depending on activity level before pulse)
%    - time decoding
% 
% --------------------------------------------------------------------------------------------------

%%
%% Load neural activity + motion energy

rois = {'MOs', 'BG' };
areas = area_names_in_roi(rois);
while any(cellfun(@iscell, areas))
    areas = [areas{cellfun(@iscell,areas)} areas(~cellfun(@iscell,areas))];
end

[indexes, avg_resps, t_ax_resps, ~, ~] = load_indexes_avgResps_all(sessions, neuron_info, ops);
% 
% flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');
% subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_007', 'MH_010', 'MH_011','MH_014','MH_015'};

%%
% keep track of roi, multi units, good subjs
in_area = contains(indexes.loc, areas);
multi   = (indexes.cg==0) | avg_resps.FRmu < .1 | avg_resps.FRsd<.1;
% responsive = indexes.prelick_p < .05 | indexes.tf_p < .05;
% good_subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_007', 'MH_010', 'MH_015'};
good_subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_011', 'MH_010', 'MH_015'};
good_subj = ismember(indexes.animal,good_subjects); 
inds = indexes(in_area & good_subj & ~multi, :);
resps   = avg_resps(in_area & good_subj & ~multi, :);
 
%%% may change inclusion criteria... just make sure 'resps', 'indexes', and 'resps' are matching

%% Identify movement-related dims across all sessions, for visualization

%% extract N and M matrices
ops.npxDir = '/mnt/winstor/swc/mrsic_flogel/public/projects/MoHa_20201102_SwitchChangeDetection/npx/';
rois_to_use = {'face', 'whisker pad', 'pupil'};
Ns = {};
Ms = {};
lick_inf = {};

tfis = {};
frstats = {};

motE_dir = fullfile('/media/morio/Data_Fast/switch_task/', 'perilickMotE');
t_ax = [-1.99:.01:1]; % time axis around licks to get FR and motion energy

NM_data_path = '/media/morio/Data_Fast/nullspace_tmp/periLickNM_su_shift_withM.mat';
inc_units = zeros(height(resps),1);
units_conts = zeros(height(resps),1);
if exist(NM_data_path, 'file')
    load(NM_data_path)
else
    for s = 1:length(sessions)
        fprintf('session %d/%d\n', s, length(sessions));
        animal  = sessions(s).animal; 
        session = sessions(s).session;
        cont    = sessions(s).contingency;
        
        sess_units = strcmp(cellstr(resps.animal), animal) &  strcmp(cellstr(resps.session), session);
        if sum(sess_units)<5, continue; end
        if strcmp(session(1), 'h'), continue; end
        
        % 30 was good for just hit!    
        trials = trials_all{s};
        daq    = daq_all{s};
        sp     = sp_all{s};
        if sum(strcmp({trials.trialOutcome}, 'Hit') & ~strcmp({trials.trialType}, 'zero')) < 50, continue; end

        % Also make sure at least 5 for each hit TF, excluding zeros
        hit_tfs = [trials(strcmp({trials.trialOutcome}, 'Hit')).changeTF];
        hit_tfs(hit_tfs==2) = [];
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
        tfis{s,1} = inds(sess_units, {'tf_short', 'tf_short_p', 'tf', 'tf_p', ...
                                         'tfExpF_short', 'tfExpF_short_p', ...
                                         'tfExpS_short','tfExpS_short_p', ...
                                         'tfExpF', 'tfExpF_p', ...
                                         'tfExpS','tfExpS_p' });
        inc_units(sess_units) = 1;
        if strcmp(cont, 'EFLS'), cont = 1; else, cont = -1; end
        units_conts(sess_units) = cont;
    end
    save(NM_data_path, 'Ns', 'Ms', 'lick_inf', 'tfis', 'frstats', 'inc_units', '-v7.3');
end   

combinedOutputs = cellfun(@(n,m,l) nullspace.average_by_lick_type_wrapper(n,m,l,t_ax, 'TFval'), Ns, Ms, lick_inf, 'UniformOutput', false);

%%
% Extract separate Ns and Ms cell arrays
N_avg = cellfun(@(c) c{1}, combinedOutputs, 'UniformOutput', false);
M_avg = cellfun(@(c) c{2}, combinedOutputs, 'UniformOutput', false);
N = vertcat(N_avg{:});  
M = vertcat(M_avg{:});
tf_prefs = vertcat(tfis{:});
% PCA to reduce dimensionality
ops.nDim_N = 2;
ops.nDim_M = 1;
ops.nDim_denoise = 12;
[Mdr,Ndr,coeffN,coeffM] = nullspace.pca_dim_reduction(N, M, t_ax, ops);

% Identify Null/Potent dims
[W_toPot, W_toNull, N_pot, N_null] = nullspace.calculate_movement_dims(Ndr, Mdr, coeffN, coeffM, t_ax, ops);
% [W_toPot, W_toNull, N_pot, N_null] = nullspace.calculate_movement_dims_LD(Ndr, Mdr, coeffN, coeffM, t_ax,  ops);

% Plot
plot_dir = fullfile(ops.saveDir, 'nullSpace');
if ~exist(plot_dir,'dir'), mkdir(plot_dir); end

% close all
ch_clrs   = [flipud(cbrewer2('Blues', 3)); cbrewer2('Reds', 4)];
pot_clrs  = flipud(cbrewer2('Greens', ops.nDim_M+1));
null_clrs = flipud(cbrewer2('Blues', ops.nDim_N+1));
mov_clrs  = flipud(cbrewer2('Greys', ops.nDim_M+1));

% Plot motion energy, movespace dims
f = figure('Units', 'normalized', 'OuterPosition', [.3 .1 .3 .18]);
for ch = 1:6
    subplot(1,6,ch); hold on
    this_ch_inds = [1:300] + (ch-1)*300;
    for ii = 1%:nDim_M
        plot(linspace(-2,1,300),smoothdata(Mdr(ii,this_ch_inds), 'movmean', [3]), 'color', mov_clrs(ii,:), 'linewidth', 1.5);
        plot(linspace(-2,1,300),smoothdata(N_pot(ii,this_ch_inds), 'movmean', [3]), 'color', pot_clrs(ii,:), 'linewidth', 1.5);
    end
    for ii = 1:ops.nDim_N
        plot(linspace(-2,1,300),smoothdata(N_null(ii,this_ch_inds), 'movmean', [3]), 'color', null_clrs(ii,:), 'linewidth', 1.5);
    end
    plot([0 0], [-15 30], 'linewidth', 1, 'color', ch_clrs(ch,:))
    ylim([-15 30]);
    yticks(-15:15:30);
    offsetAxes
    if ch>1
        set(gca, 'Ycolor', 'none')
    end
end

% Plot dim responses
dims = struct();
dims.movement_potent = W_toPot(1,:)';
for ii = 1:ops.nDim_N
    dims.(sprintf('movement_null%d', ii)) = W_toNull(ii,:)';
end
resps_flipped = flip_eslf_baseline(resps, units_conts);
projs = project_resps_onto_ax(resps_flipped(logical(inc_units),:), dims);
[f1d_all, fhd_all] = visualize_nullSpace_projected_activity(projs, t_ax_resps, ...
                                {'movement_null1', 'movement_null2','movement_potent'}, ops, 1);



%% Bootstrap sampling of trials and neurons in single sessions to test significance
% For each iteration: go through all sessions, generate two 'response' tables using training and
% validation splits of trials. Use training responses to calculate movement axes, and validation to
% calculate projections.
clear avg_resps 

% set params
nIter  = 1000; % ops.nIter
pTrain = .5;
change_TF_vals = [0.25, 1, 1.5, 2.5, 3, 3.75];
% calculate lick indexes outside loop
lick_inds_to_use = [1 2 3 4 5 6];
t_starts_to_use  = (lick_inds_to_use-1) * length(t_ax) + 1;
t_ends_to_use    = lick_inds_to_use*300;
t_inds           = arrayfun(@(s, e) s:e, t_starts_to_use, t_ends_to_use, 'UniformOutput', false);
t_inds           = cell2mat(t_inds);
% tf prefs
tf_prefs = vertcat(tfis{:});
fast     = tf_prefs.tf > 0 & tf_prefs.tf_p < .01;
slow     = tf_prefs.tf < 0 & tf_prefs.tf_p < .01;
none     = tf_prefs.tf_p > .05;

projs_iters   = cell(nIter,1);
dims_iters    = cell(nIter,1);

resps_bs = resps_flipped(logical(inc_units),:);
tf_motE_dir = fullfile('/media/morio/Data_Fast/switch_task/', 'periTFMotE');
tmp_savedir = '/media/morio/Data_Fast/nullspace_tmp';
for iter = 1:nIter
    fprintf('\niteration %d/%d\n', iter, nIter);
    if exist(fullfile(tmp_savedir, sprintf('moveSpace_bsunits_iter%d_su_shift.mat', iter)), 'file')
        [projs, dims] = ...
            loadVariables(fullfile(tmp_savedir, ...
            sprintf('moveSpace_bsunits_iter%d_su_shift.mat', iter)), ...
            'projs', 'dims');
        projs_iters{iter} = projs;
        dims_iters{iter}  = dims;
        clear proj dims
    else
        % Iterate through sessions, subsampling trials (licks) and units
        iter_resps = resps_bs([],:);
        iter_tfis  = tf_prefs([],:);
        Ms_train = {}; Ms_valid = {}; Ns_train = {}; Ns_valid = {}; Mtf={};
        for s = 1:length(sessions)
            %fprintf('session %d/%d\n', s, length(sessions));
            if isempty(Ns{s}), continue; end
            animal  = sessions(s).animal;
            session = sessions(s).session;
            cont    = sessions(s).contingency;
            
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
            nF_all = sum(tf_pref{:, 'tf'}>0 & tf_pref{:, 'tf_p'}<.05);
            nS_all = sum(tf_pref{:, 'tf'}<0 & tf_pref{:, 'tf_p'}<.05);
            if min([nF_all, nS_all])<3, continue; end
            nF = 0; nS = 0;
            while nF<2 | nS<2
                iter_units = sort(datasample(1:nN, nN, 'Replace',true))';
                nF = sum(tf_pref{iter_units, 'tf'}>0 & tf_pref{iter_units, 'tf_p'}<.05);
                nS = sum(tf_pref{iter_units, 'tf'}<0 & tf_pref{iter_units, 'tf_p'}<.05);
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
            
            sess_units = find(strcmp(cellstr(resps_bs.animal), animal) &  strcmp(cellstr(resps_bs.session), session));
            iter_resps = vertcat(iter_resps, resps_bs(sess_units(iter_units),:));
            iter_tfis  = vertcat(iter_tfis,  tf_prefs(sess_units(iter_units),:));
            
            % load peri-TF motE - but remove side views!
%             keyboard
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
%         [W_toPot, W_toNull, N_pot, N_null] = nullspace.calculate_movement_dims_LD(Ndr, Mdr, coeffN, coeffM, t_ax, ops);

        % get dims
        dims = struct();
        dims.movement_potent = W_toPot(1,:)';
        for ii = 1:ops.nDim_N
            dims.(sprintf('movement_null%d', ii)) = W_toNull(ii,:)';
        end
        F = iter_tfis{:,'tf'}>.025 & iter_tfis{:,'tf_p'}<0.01;
        S = iter_tfis{:,'tf'}<-.025 & iter_tfis{:,'tf_p'}<0.01;
        N = iter_tfis{:,'tf_p'}>.1 & abs(iter_tfis{:,'tf'})<.05;
        W_tf = normc(double([F, S, N]));
        dims.tf_fast = W_tf(:,1); dims.tf_slow = W_tf(:,2); dims.tf_none = W_tf(:,3);
        
        % also by expectation
        tf_sensitive = (iter_tfis{:,'tfExpF_short_p'}<.05 & iter_tfis{:,'tfExpS_short_p'}<.05);
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
        
        projs = project_resps_onto_ax(iter_resps, dims);
        
%         keyboard
        % get Mdr around tf pulses
        Mtfs = vertcat(Mtf{:});
        
        rmv = all(isnan(Mtfs), [2, 3]);
        Mtfs(rmv,:,:) = [];
%         keyboard
        MdrTF = squeeze(pagemtimes(coeffM(:,1)', Mtfs));%coeffM(:,1)' * Mtfs;
        projs.Mdr.FexpF = MdrTF(1,:);
        projs.Mdr.FexpS = MdrTF(2,:);
        projs.Mdr.SexpF = MdrTF(3,:);
        projs.Mdr.SexpS = MdrTF(4,:);
        for ii = 1:6
            ids = [1:300] + (ii-1)*300;
            projs.Mdr.(sprintf('hitLickE%d',ii)) = Mdr(ids);
        end
        
        dims_iters{iter}  = dims;
        projs_iters{iter} = projs;
%         save 
        save(fullfile(tmp_savedir, sprintf('moveSpace_bsunits_iter%d_su_shift.mat', iter)), ...
             'projs', 'dims', '-v7.3')
        clear dims projs
    end
        
end


%% Visualize activity alongs dims - lick aligned, TF


% Group events into types and plot
ev_groups = {...
             {'bl'}, [.5 .5 .5], [0 10]; ...
             {'tfF', 'tfS'}, [ops.colors.F; ops.colors.S], [-.5 1]; ...
             {'FexpF', 'FexpS', 'SexpF', 'SexpS'}, [ops.colors.F; ops.colors.F*.6; ops.colors.S*.6; ops.colors.S], [-.5 1]; ...
             {'hitE1', 'hitE2', 'hitE3', 'hitE4', 'hitE5', 'hitE6', 'hitE7'}, RedGreyBlue(7), [-.5 1]; ...
             {'hitLickE1', 'hitLickE2', 'hitLickE3', 'hitLickE4', 'hitLickE5', 'hitLickE6', 'hitLickE7'}, RedGreyBlue(7), [-2 1]};           
% dim_names = {'movement_potent', 'movement_null1', 'movement_null2', 'tf_fast', 'tf_slow', 'tf_none'};
dim_names = {'movement_potent', 'movement_null1', 'movement_null2'};
% dim_names = {'tf_fast', 'tf_slow', 'tf_none'};

[projs_iters_aligned, dims_iters_aligned] = align_projection_directions_from_dims(projs_iters, dims_iters);
% add tf F and S
for ii = 1:length(projs_iters_aligned)
    dims = fields(projs_iters_aligned{ii});
    for dd = 1:numel(dims)
        projs_iters_aligned{ii}.(dims{dd}).tfF = (projs_iters_aligned{ii}.(dims{dd}).FexpF + projs_iters_aligned{ii}.(dims{dd}).FexpS)/2;
        projs_iters_aligned{ii}.(dims{dd}).tfS = (projs_iters_aligned{ii}.(dims{dd}).SexpF + projs_iters_aligned{ii}.(dims{dd}).SexpS)/2;
    end
end
f_resps_iters = visualize_xval_movementSpace_activity(projs_iters_aligned, t_ax_resps, ev_groups, dim_names, ops);
f_motE_iters  = nullspace.visualize_xval_motionEnergyDR(projs_iters, ops);

%% Quantify alignment between movement-related and F/S dims
alignments = nullspace.test_xval_alignments(projs_iters_aligned, dims_iters_aligned, ops);
[f_resp, f_dim] = nullspace.visualize_moveSpace_alignment(alignments, ops)

%% Prediction of RTs, FAs

% RT prediction from pre-change projections
[f_rt_pred_quant, f_rt_pred_vis] = nullspace.predict_rt_from_movespace_projections(projs_iters_aligned, t_ax_resps, ops);

% Calculate aerly lick psychometric by projection onto movement null 1, F, S

%% Rotation tests

% test whether F/S axes rotate
f_tfax_rotation = nullspace.test_tf_rotation(dims_iters_aligned, ops);

%%
% test whether movement null 1 rotates
rwr_root = '/media/morio/Data_Fast/switch_task/rwr_fits/rwr50ms_v7nonLin';
rwr_shuffle_root = '/media/morio/Data_Fast/switch_task/rwr_fits/rwr50ms_shuffle_v7';

f_premotor_rotation = nullspace.test_premotor_rotation(rwr_root, rwr_shuffle_root, areas, neuron_info, indexes, ops)

%% visualize projection of fast/slow units along null 1

% f_fs_proj = nullspace.tf_proj_on_movespace(projs_iters_aligned, dims_iters_aligned, t_ax_resps, ops);


%% save figures! 
plot_save_dir = fullfile(ops.saveDir, 'nullSpace_analyses_revamped');
if ~exist(plot_save_dir, 'dir'), mkdir(plot_save_dir); end
formats = {'fig', 'svg', 'png'};

save_figures_multi_format(f1d_all, fullfile(plot_save_dir, 'dim_responses_all'), formats);
save_figures_multi_format(fhd_all, fullfile(plot_save_dir, 'dim_responses_all_hd'), formats);
save_figures_multi_format(f_resps_iters, fullfile(plot_save_dir, 'dimension_responses_iters'), formats)
save_figures_multi_format(f_resp, fullfile(plot_save_dir, 'tf_pref'), formats)
save_figures_multi_format(f_dim, fullfile(plot_save_dir, 'dim_alignments'), formats)
save_figures_multi_format(f_rt_pred_quant, fullfile(plot_save_dir, 'rt_pred_quant'), formats)
save_figures_multi_format(f_rt_pred_vis, fullfile(plot_save_dir, 'rt_pred_vis'), formats)
save_figures_multi_format(f_tfax_rotation, fullfile(plot_save_dir, 'tf_ax_rotation'), formats)
save_figures_multi_format(f_premotor_rotation, fullfile(plot_save_dir, 'premotor_rotation'), formats)

%% TO DO:
% 1) population trajectories
% 2) schematic of pre-change activity

%% check whether random dimensions also map well onto null 1
%% Loading of F/S units onto premotor
% f_fs_loading_premotor = nullspace.visualize_tfunit_loading_on_premotor(projs_iters_aligned, dims_iters_aligned, t_ax_resps, ops)




