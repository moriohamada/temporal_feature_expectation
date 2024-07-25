function null_space_analysis_wrapper(sessions, trials_all, daq_all, sp_all, neuron_info, ops)
% 
% Visualize population activity in output-potent and output-null space.
% 1) load motion energy and neural activity aligned to licks
% 2) run PCA to reduce dimensionality
% 3) find output potent and null space
% 4) visualize activity projected onto pot and null space
% 5) compare relative contribution of TF responsive units to output potent and null subspaces/dims
% 
% Generate matrices N and M:
%   N: nN x (t x 2) array containing concatenanted average activity around fast and slow licks
%   M: (nRoi x nSessiosn) x (t x 2) array containing motion energy in different rois. 
% 
% --------------------------------------------------------------------------------------------------

%% Load neural activity
rois = {'MOs', 'BG', 'mPFC'};
areas = area_names_in_roi(rois);
while any(cellfun(@iscell, areas))
    areas = [areas{cellfun(@iscell,areas)} areas(~cellfun(@iscell,areas))];
end

[indexes, avg_resps, t_ax_resps, ~, ~] = load_indexes_avgResps_all(sessions, neuron_info, ops);

%%

% keep track of roi, multi units, good subjs
in_area = contains(indexes.loc, areas);
multi   = (indexes.cg==0) | avg_resps.FRmu < .1 | avg_resps.FRsd<1 | (indexes.lick_p>.05 & indexes.prelick_p>.05 & indexes.tf_p > .05); 
good_subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_007', 'MH_010', 'MH_011','MH_014','MH_015'};
good_subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006','MH_015'};

good_subj = ismember(indexes.animal,good_subjects); 
% Load in motE and neural activity for each session

ops.npxDir = '/mnt/winstor/swc/mrsic_flogel/public/projects/MoHa_20201102_SwitchChangeDetection/npx/';
rois_to_use = {'face', 'whisker pad', 'pupil'};
flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');
subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_007', 'MH_010', 'MH_011','MH_014','MH_015'};


% sess_count = 0;

Ns = {};
Ms = {};
lick_inf = {};

tfis = {};
frstats = {};
inc_units = zeros(height(avg_resps),1);

motE_saveDir = fullfile('/media/morio/Data_Fast/switch_task/', 'perilickMotE');

t_ax = [-1.99:.01:1]; % time axis around licks to get FR and motion energy

for s = 1:length(sessions)
    
    fprintf('session %d/%d\n', s, length(sessions));
%     try
    animal  = sessions(s).animal; 
    session = sessions(s).session;
    cont    = sessions(s).contingency;
    if strcmp(session(1), 'h'), continue; end
    
    % 30 was good for just hit!    
    trials = trials_all{s};
    if sum(strcmp({trials.trialOutcome}, 'Hit') & ~strcmp({trials.trialType}, 'zero')) < 30, continue; end
    
    % Also make sure at least 5 for each hit TF, excluding zeros
    hit_tfs = [trials(strcmp({trials.trialOutcome}, 'Hit')).changeTF];
    hit_tfs(hit_tfs==2) = [];
    [uniqueValues, ~, idx] = unique(hit_tfs);
    counts = histc(idx, 1:numel(uniqueValues));
    if any(counts<3), continue; end
    
    
    processed_dir = fullfile(ops.npxDir, animal, 'Processed data');
    sess_dirs     = dir2(processed_dir);
    sess_dir      = sess_dirs{contains(sess_dirs, session)};
    if isempty(sess_dir), continue; end
    
%     sess_count = sess_count+1;
    % load daq  if need video frame times
%     daq = loadVariable(fullfile(processed_dir,sess_dir,'Nidaq', sprintf('%s_NIdaq_events.mat',sess_dir)), ...
%                        'NIdaq_events');
                   
    daq = daq_all{s};
    
    % get times of all licks and 'type' (F/S), and motion energy
    lick_data_path = fullfile(motE_saveDir, sprintf('%s_%s.mat', animal, session));
    if ~exist(lick_data_path, 'file'), continue; end
    load(lick_data_path);
    
    % load activity around licks
    sp = sp_all{s};
    
    [fr, tax_fr] = spike_times_to_fr(sp, 10);
    
    % keep only good units in ROI
    sess_unit_ids = strcmp(cellstr(neuron_info.animal), animal) & strcmp(cellstr(neuron_info.session), session);
    sess_in_roi = in_area(sess_unit_ids) & ~multi(sess_unit_ids) & good_subj(sess_unit_ids);
    if sum(sess_in_roi)>1
        
        lick_inf{s,1} = licks;
        
        inc_units(sess_unit_ids) = sess_in_roi;
        
        fr = fr(sess_in_roi,:);
        
        [fr_tmp,~] = remove_out_of_trial_fr(fr, tax_fr, daq);
%         [fr_tmp,~] = remove_non_baseline_fr(fr, tax_fr, daq, ops);
        fr_tmp = smoothdata(fr_tmp, 2, 'movmean', 3);
        mu = nanmean(fr_tmp,2); 
        sd = nanstd(fr_tmp,[],2);
        clear fr_tmp;
%         mu = nanmean(fr,2); 
%         sd = nanstd(fr,[],2);
        
        fr = (fr - mu)./sd;
        
        fr = smoothdata(fr, 2, 'movmean', 3);
        
        frstats{s,1} = mu; 
        frstats{s,2} = sd;  
        
        
        [tax_N, N] = get_response_to_event_from_FR_matrix(fr, tax_fr, licks.times', [t_ax(1)-.02 t_ax(end)+.02]);
        
        % resample to t_ax
        N = interp1(tax_N, permute(N, [3 1 2]), t_ax);
        N = permute(N, [2 3 1]);
        
        Ns{s,1} = N;% N_cond;
    
        clear fr N N_cond
        
        % also store TF preferences
        tmp = indexes(sess_unit_ids, {'tf_short', 'tf_short_p', 'tf', 'tf_p', 'prelick', 'prelick_p'});
        tfis{s,1} = tmp(sess_in_roi,:);
        
        
        Ms{s,1} = M; %M_cond;
        clear M
    else
        clear M licks
    end
end

if ~iscolumn(Ns)
    Ns = Ns';
    Ms = Ms';
end

%%

%% First do average across all sessions, for visualization

% Generate matrices N and M:
%   N: nN x (t x 2) array containing concatenanted average activity around fast and slow licks
%   M: (nRoi x nSessiosn) x (t x 2) array containing motion energy in different rois. 
combinedOutputs = cellfun(@(n,m,l) average_by_lick_type_wrapper(n,m,l,t_ax), Ns, Ms, lick_inf, 'UniformOutput', false);

% % Extract separate Ns and Ms cell arrays
N_avg = cellfun(@(c) c{1}, combinedOutputs, 'UniformOutput', false);
M_avg = cellfun(@(c) c{2}, combinedOutputs, 'UniformOutput', false);

% reduce dims per session
% N_avg = cellfun(@(n) dim_reduce_fr(n, 80), N_avg, 'UniformOutput', false);

N = vertcat(N_avg{:});
M = vertcat(M_avg{:});
% N = (N-vertcat(frstats{:,1}))./vertcat(frstats{:,2});

% remove all nan rows
% N(~any(~isnan(N), 2),:)=[];
% M(~any(~isnan(M), 2),:)=[];

lick_inds_to_use = [1:6];
t_starts_to_use  = (lick_inds_to_use-1) * length(t_ax) + 1;
t_ends_to_use    = lick_inds_to_use*300;
t_inds           = arrayfun(@(s, e) s:e, t_starts_to_use, t_ends_to_use, 'UniformOutput', false);
t_inds           = cell2mat(t_inds);

N = N(:, t_inds);
M = M(:, t_inds);

% Normalize fast and slow unit activity levels
tf_prefs = vertcat(tfis{:});
fast     = tf_prefs.tf > 0 & tf_prefs.tf_p < .05;
slow     = tf_prefs.tf < 0 & tf_prefs.tf_p < .05;
% none     = ~fast & ~slow;
normF = nannorm(N(fast,:),2);
normS = nannorm(N(slow,:),2);
fsRatio = normS/normF
N(fast,:) = N(fast,:) * fsRatio;


% subtract average activity between -2 and -1.5 s
nrep = size(N,2)/length(t_ax);
tax_repeated = repmat(t_ax, 1, nrep);
t_bl = tax_repeated > -1.99 & tax_repeated < -1.5;
% for rep = 1:nrep
%     rel_ids = 1:300 + (rep-1)*300;
%     bl_ids  = 50:100 + (rep-1)*300;
%     N(:, rel_ids) = N(:, rel_ids) - nanmean(N(:,bl_ids),2);
%     M(:, rel_ids) = M(:, rel_ids) - nanmean(M(:,bl_ids),2); 
% end
N = (N - nanmean(N(:,t_bl),2));
M = (M - nanmean(M(:,t_bl),2));
%  

%  
%% PCA to reduce dimensionality
nDim_denoise = 20;
nDim_M = 2;
nDim_N = 2;

t_rel = isbetween(tax_repeated, [-1 .5]);
[coeffN, scoreN, ~, ~, expN] = pca(N(:,t_rel)');
[coeffM, scoreM, ~, ~, expM] = pca(M(:,t_rel)');
fprintf('\n%.2f%s movement energy variance explained\n', sum(expM(1:nDim_M)), '%')
fprintf('%.2f%s neural activity variance explained\n', sum(expN(1:nDim_denoise)), '%')
% disp(expN(1:5))

Ndr = coeffN(:,1:nDim_denoise)' * N;
Mdr = coeffM(:,1:nDim_M)' * M;

% subtract average activity between -2 and -1.5 s
nrep = size(Ndr,2)/length(t_ax);
tax_repeated = repmat(t_ax, 1, nrep);
t_bl = tax_repeated > -1.99 & tax_repeated < -1.5;

Ndr = Ndr - nanmean(Ndr(:,t_bl),2);
Mdr = Mdr - nanmean(Mdr(:,t_bl),2);

% select only lick time
t_lick = isbetween(tax_repeated, [-.5 .25]);

% Calculate the pseudo-inverse of N
N_pinv = pinv(Ndr(:,t_lick));

% Compute W using the pseudo-inverse of N
W = Mdr(:,t_lick) * N_pinv;
W_null = null(W)';

% rotate Wnull to explain pre-lick variance
t_pre = tax_repeated > -1 & tax_repeated < 0;
% t_pre(1800:end)=0; % dont include false alarms
N_null = W_null * Ndr;

[coeffNull, scoreNull, ~, ~, expNull] = pca(N_null(:,t_pre)');
W_null = coeffNull(:,1:nDim_N)' * W_null;
N_null = W_null * Ndr;
if sum(N_null(1,:))<0, W_null(1,:) = -1 * W_null(1,:); end
fprintf('%.2f%s null space variance captured\n', sum(expNull(1:nDim_N)), '%')

% get full mappings from single units to movement potent and null space
W_toPot = W * coeffN(:,1:nDim_denoise)';
W_toNull = W_null * coeffN(:,1:nDim_denoise)';

%% Split W and W_null into tf responsive and non-responsive

tf_prefs = vertcat(tfis{:});
fast     = tf_prefs.tf > 0 & tf_prefs.tf_p < .05;
slow     = tf_prefs.tf < 0 & tf_prefs.tf_p < .05;
none     = tf_prefs.tf_p > .05;

N_f = N; N_f(~fast,:) = 0;
N_s = N; N_s(~slow,:) = 0;
N_n = N; N_n(~none,:) = 0;

N   = N/nannorm(N,2);
N_f = N_f/nannorm(N_f,2);
N_s = N_s/nannorm(N_s,2);
N_n = N_n/nannorm(N_n,2);

N(:,301:300:end) = nan;
N_f(:,301:300:end) = nan;
N_s(:,301:300:end) = nan;
N_n(:,301:300:end) = nan;

% get split projections
N_pot    = W_toPot * N;  
N_pot_f  = W_toPot * N_f;
N_pot_s  = W_toPot * N_s;
N_pot_n  = W_toPot * N_n;

N_null   = W_toNull * N;
N_null_f = W_toNull * N_f;
N_null_s = W_toNull * N_s;
N_null_n = W_toNull * N_n; 

%% Plot all session averages

close all
ch_clrs   = [flipud(cbrewer2('Blues', 3)); cbrewer2('Reds', 4)];
pot_clrs  = flipud(cbrewer2('Greens', nDim_M+1));
null_clrs = flipud(cbrewer2('Blues', nDim_N+1));
mov_clrs  = flipud(cbrewer2('Greys', nDim_M+1));

% Project movement potent, null dims onto space spanned by F,S,L axes

W_potnull = vertcat(W_toPot(1,:), W_toNull);
W_potnull = normr(W_potnull);
W_tf      = double([fast'; slow'; none']);
W_tf      = normr(W_tf);
W_projTF  = W_tf * (W_potnull)';
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .2 .16]);
proj_clrs = [pot_clrs(1,:); null_clrs];
hold on;
for ii = 1:3
    quiver3(0, 0, 0, W_projTF(1,ii), W_projTF(2,ii), W_projTF(3,ii), 'color', proj_clrs(ii,:), 'linewidth', 2);
end
axis equal;
grid on;
xlabel('Fast');
ylabel('Slow');
zlabel('None');
title('Projection of movement dims onto subspace defined by TF');
view(3)
axis equal
grid on 
view([-378, 15])

% Project F,S,N onto movement dims
W_projMov = W_potnull * W_tf';
f = figure('Units', 'normalized', 'OuterPosition', [.3 .1 .2 .16]);
proj_clrs = [ops.colors.F; ops.colors.S; [.5 .5 .5]];
hold on;
for ii = 1:3
    quiver3(0, 0, 0, W_projMov(2,ii), W_projMov(3,ii), W_projMov(1,ii), 'color', proj_clrs(ii,:), 'linewidth', 2);
end
axis equal;
grid on;
xlabel('Movment null 1');
ylabel('Movment null 2');
zlabel('Movement potent');
title('Projection of movement dims onto subspace defined by TF');
view(3)
axis equal
grid on

% Visualize 'psths' along each movement dimension
inc_units   = logical(inc_units);
roi_indexes = indexes(inc_units, :);
roi_resps   = avg_resps(inc_units, :);
conts = roi_indexes.conts;
roi_resps{conts==-1,'bl'} = fliplr(roi_resps{conts==-1,'bl'}); 
% project responses onto dims
dims = struct();
dims.movement_potent = W_toPot(1,:)';
for ii = 1:nDim_N
    dims.(sprintf('movement_null%d', ii)) = W_toNull(ii,:)';
end
dims.tf_fast         = W_tf(1,:)';
dims.tf_slow         = W_tf(2,:)';
dims.tf_none         = W_tf(3,:)';

projs = project_resps_onto_ax(roi_resps, dims);


[f1d, fhd] = visualize_nullSpace_projected_activity(projs, t_ax_resps, {'movement_null1', 'movement_null2','movement_potent'}, ops);
% [f1d, fhd] = visualize_nullSpace_projected_activity(projs, t_ax_resps, {'movement_null1', 'movement_null2','movement_null3'}, ops);

%%

%% Boostrap sampling of trials - single session
% 
% For each iteration randomly select half to find null/potent axes, and other to get responses.
% clear avg_resps 
% clearvars -except sessions trials_all sp_all daq_all ops s clusters flip_times animals time_axes ...
%                   neuron_info glm_kernels neuron_info indexes glm_kernels_el Ns Ms ...
%                   lick_inf tfis frstats t_ax in_area multi good_subj t_ax_resps
nIter  = 10;% ops.nIter
pTrain = .5;
pVal   = .5; % 

change_TF_vals = [0.25, 1, 1.5, 2.5, 3, 3.75];

% inc_units   = logical(inc_units);
% roi_indexes = indexes(inc_units, :);
% roi_resps   = avg_resps(inc_units, :);

% if exist('/media/morio/Data_Fast/tmp/moveSpace_all_projs_aligned.mat', 'file')
%     load('/media/morio/Data_Fast/tmp/moveSpace_all_projs_aligned.mat');
% else
    all_projs   = {};

    for s = 1:length(sessions)

        fprintf('session %d/%d\n', s, length(sessions));
%         try
        if isempty(Ns{s}), continue; end
        
        % make sure enough (min 3) hits for each change
        trials = trials_all{s};
        hits   = strcmp({trials.trialOutcome}, 'Hit') & ...
                ~contains({trials.trialType}, 'U')   & ...
                [trials.changeTF] ~= 2;
        hitTFs = [trials(hits).changeTF];
        hitTF_counts = histc(hitTFs, change_TF_vals);
        if any(hitTF_counts<3)
            continue
        end
        
        licks = struct2table(lick_inf{s});
        N = Ns{s};
        M = Ms{s};
        
        tf_prefs = tfis{s};
        fast = tf_prefs.tf > 0 & tf_prefs.tf_p < .05;
        slow = tf_prefs.tf < 0 & tf_prefs.tf_p < .05;
        if sum(fast) < 3 | sum(slow) < 3
            continue
        end
        none = tf_prefs.tf_p > .05;

        nEv    = numel(licks.times);
        nTrain = round(pTrain*nEv);

        % load session responses
        animal  = sessions(s).animal; 
        session = sessions(s).session;
        cont    = sessions(s).contingency;
        event_psth_path = fullfile(ops.eventPSTHdir, sprintf('%s_%s.mat', animal, session));
        resps = load(event_psth_path);

        % remove bad/out of roi units
        sess_unit_ids = strcmp(cellstr(neuron_info.animal), animal) & strcmp(cellstr(neuron_info.session), session);
        sess_in_roi = in_area(sess_unit_ids) & ~multi(sess_unit_ids) & good_subj(sess_unit_ids);
        nN = length(sess_in_roi);
        resp_fields = fields(resps);

        % get fr
        [fr, tax_fr] = spike_times_to_fr(sp_all{s}, 10);
        fr = fr(sess_in_roi,:);
        [fr_tmp,~] = remove_out_of_trial_fr(fr, tax_fr, daq_all{s});
        fr_tmp = smoothdata(fr_tmp, 2, 'movmean', 3);
        mu = nanmean(fr_tmp,2);
        sd = nanstd(fr_tmp,[],2);
        clear fr_tmp;
        fr = (fr - mu)./sd;

        fr = smoothdata(fr, 2, 'movmean', 3);

        for r = 1:length(resp_fields)
            resp_field = resp_fields{r};
            if size(resps.(resp_field),1)==nN
                resps.(resp_field) = resps.(resp_field)(sess_in_roi,:,:);
            end
            if strcmp(resp_field(end-1),'U') 
                resps = rmfield(resps,resp_field);
            end
            if contains(resp_field, 'tax')
                resp_tax.(strrep(resp_field, '_tax','')) = resps.(resp_field);
            end
            if ~contains(resp_field, 'psth')
                resps = rmfield(resps,resp_field);
            end
        end
        
        %normalize resps
        resp_fields = fields(resps);
        for r = 1:length(resp_fields)
            resps.(resp_fields{r}) = (resps.(resp_fields{r}) - mu/(ops.spBinWidth/1000)) ./ (sd/(ops.spBinWidth/1000));
            resps.(resp_fields{r}) = smoothdata(resps.(resp_fields{r}),2,'movmean', [5 0]);
        end
%         keyboard
        %
        % first get dimensions using all trials - this is just to flip extracted dimensions to match
        N = smoothdata(N, 3, 'movmean',5);
        [N_avg, M_avg] = average_by_lick_type(N, M, licks, t_ax);
        
        normF = nannorm(N_avg(fast,:),2);
        normS = nannorm(N_avg(slow,:),2);
        fsRatio = normS/normF
        N_avg(fast,:) = N_avg(fast,:) * fsRatio;
        [W_pot_ref, W_null_ref, ~, expN, expM] = calculate_movement_potent_null_transforms(N_avg(:,1:1800), M_avg(:,1:1800), t_ax);
        
        % make sure all dims go up around fast lick
        respF = squeeze(nanmean(cat(3,N_avg(:,901:1200), N_avg(:,1201:1500), N_avg(:,1501:1800)),3));
        
        potF = W_pot_ref*respF;
        bl   = 50:100;
        pre  = 150:200;
        lick = 200:250;
        if mean(potF(lick)) - mean(potF(pre)) < 0
            W_pot_ref = W_pot_ref * -1;
        end
        
        null1F = W_null_ref(1,:)*respF;
        if mean(null1F(pre)) - mean(null1F(bl)) < 0
            W_null_ref(1,:) = W_null_ref(1,:) * -1;
        end
        
        null2F = W_null_ref(2,:)*respF;
        if mean(null2F(pre)) - mean(null2F(bl)) < 0
            W_null_ref(2,:) = W_null_ref(2,:) * -1;
        end
        
        
        for iter = 1:nIter
            fprintf('\titeration %d/%d\n', iter, nIter);

            all_licks_inc = 0;

            while ~all_licks_inc
                ids = randperm(nEv);
                train_id = ids(1:nTrain);
                val_id   = ids(nTrain+1:end);

                % make sure each hit type is in train set at least once
                unique_train_types = unique(licks(train_id, {'type', 'dir'}));
                unique_train_types = unique_train_types(strcmp(unique_train_types{:,'type'}, 'Hit') & unique_train_types{:,'dir'}~=0,:);
                unique_val_types = unique(licks(val_id, {'type', 'dir'}));
                unique_val_types = unique_val_types(strcmp(unique_val_types{:,'type'}, 'Hit') & unique_val_types{:,'dir'}~=0,:);

                if height(unique_train_types)==6 & height(unique_val_types)==6
                    all_licks_inc = 1;
                end
            end

            % collate average by event type
            [N_avg_train, M_avg_train] = average_by_lick_type(N(:,train_id,:), M(:,train_id,:), licks(train_id,:), t_ax);
            [N_avg_val,   M_avg_val  ] = average_by_lick_type(N(:,val_id,:),   M(:,val_id,:),   licks(val_id,:), t_ax);

            % calculate movement potent and null dims
            [W_toPot, W_toNull, coeffM] = calculate_movement_potent_null_transforms(N_avg_train, M_avg_train, t_ax);

            % project validation set activity onto potent and null dims
            moveSpace_proj = project_to_movement_subspaces(W_toPot, W_toNull, coeffM, N_avg_val, M_avg_val, tf_prefs, t_ax);

            M_avg_val(:,301:300:end) = nan;
            Mdr = coeffM' * M_avg_val;

            % Get validation set responses
            train_trials = licks{train_id, 'trial'}; % trials to exclude when getting resps for changes/hit licks
            val_resps = get_session_average_responses(trials_all{s}, daq_all{s}, fr, tax_fr, resps, train_trials, ops);

            % project responses onto dims
            if corr(W_toPot(1,:)', W_pot_ref(1,:)')<0, W_toPot(1,:) = W_toPot(1,:)*-1; end
            if corr(W_toNull(1,:)', W_null_ref(1,:)')<0, W_toNull(1,:) = W_toNull(1,:)*-1; end
            if corr(W_toNull(2,:)', W_null_ref(2,:)')<0, W_toNull(2,:) = W_toNull(2,:)*-1; end

            dims = struct;
            dims.movement_potent = W_toPot(1,:)';
            dims.movement_null1  = W_toNull(1,:)';
            dims.movement_null2  = W_toNull(2,:)';
            dims.tf_fast         = double(fast);
            dims.tf_slow         = double(slow);
            dims.tf_none         = double(none);

            % add mus and sds
            val_resps = struct2table(val_resps);
            val_resps = addvars(val_resps, mu, sd, 'NewVariableNames', {'FRmu', 'FRsd'});
            proj_iter = project_resps_onto_ax(val_resps, dims);
            dim_fields = fields(dims);
            resp_fields = fields(proj_iter.movement_potent);
            for dd = 1:length(dim_fields)
                for rf = 1:length(resp_fields)
                    dim_field = dim_fields{dd};
                    resp_field = resp_fields{rf};
                    projs(iter).(sprintf('%s_%s', dim_field, strrep(resp_field, 'psth_',''))) = ...
                        proj_iter.(dim_field).(resp_field);
                end
            end

        end
        clear resps fr tax_fr
        all_projs{s,1} = projs;
        
        % save projs 
        save(sprintf('/media/morio/Data_Fast/tmp/moveSpace_projs_%s_%s.mat', animal, session), 'projs', '-v7.3')
%         end
    end

    % save all projs temporarily
    save('/media/morio/Data_Fast/tmp/moveSpace_all_projs_aligned.mat', 'all_projs', '-v7.3')

% end

%% significance testing

%% visualization 
dim_names = {'movement_potent', 'movement_null1', 'movement_null2', 'tf_fast', 'tf_slow', 'tf_none'};

event_names = fields(all_projs{32});

% create nIter struct 
projs = struct;
for iter = 1:nIter
    
    for e = 1:numel(event_names)
        ev = event_names{e};
        projs(iter).(ev) = [];
        for s = 1:length(sessions)
            if s > length(all_projs), continue; end
            if isempty(all_projs{s}), continue; end
            tmp = all_projs{s}(iter).(ev);
            if mod(length(tmp),10)==9
                tmp = [tmp, nan];
            elseif mod(length(tmp),10)==1
                tmp = tmp(1:end-1);
            end
            
            if isempty(projs(iter).(ev))
                projs(iter).(ev) =  tmp;
            else
                projs(iter).(ev) = vertcat(projs(iter).(ev), tmp);
            end
        end
    end
end

% Group events into types and plot
ev_groups = {...
             {'bl_psth'}, [.5 .5 .5]; ...
             {'FexpF', 'FexpS', 'SexpF', 'SexpS'}, [ops.colors.F; ops.colors.F*.6; ops.colors.S*.6; ops.colors.S]; ...
             {'chHE1', 'chHE2', 'chHE3', 'chHE4', 'chHE5', 'chHE6', 'chHE7'}, RedGreyBlue(7); ...
             {'chHEshortRT2', 'chHEmedRT2', 'chHElongRT2', 'chHElongRT5', 'chHEmedRT5', 'chHEshortRT5'}, RedGreyBlue(6); ...
             {'hitE1', 'hitE2', 'hitE3', 'hitE4', 'hitE5', 'hitE6', 'hitE7'}, RedGreyBlue(7)  };

visualize_movementSpace_actvity_signf(projs, t_ax_resps, ev_groups, dim_names, ops);

%% significance testing



%%

%%

end

%%

function N = dim_reduce_fr(N, var_thresh)

if isempty(N), return; end
% keyboard
[coeffN, scoreN, ~, ~, expN] = pca(N(:,1:1800)');
cum_exp = cumsum(expN);
n_components = min(find(cum_exp > var_thresh));

N = coeffN(:,1:n_components)' * N;

end

function combinedOutput = average_by_lick_type_wrapper(n, m, l, t_ax)
    
    [N_avgs, M_avgs] = average_by_lick_type(n,m,l,t_ax);
    combinedOutput = {N_avgs, M_avgs};

end

function [N_avg, M_avg] = average_by_lick_type(n, m, l, t_ax)
    if isempty(n)
        N_avg = [];
        M_avg = [];
        return
    end
    
    n = smoothdata(n, 3, 'movmean', [5 5]);
%     m = smoothdata(m, 3, 'movmean', 5);
    
%     % By TF value
    N_avg  = cat(2, squeeze(nanmean(n(:,l.dir==-1.75 & strcmp(l.type, 'Hit'),:),2)), ...
                    squeeze(nanmean(n(:,l.dir==-1 & strcmp(l.type, 'Hit'),:),2)), ...
                    squeeze(nanmean(n(:,l.dir==-.5 & strcmp(l.type, 'Hit'),:),2)), ...
                    squeeze(nanmean(n(:,l.dir==.5 & strcmp(l.type, 'Hit'),:),2)), ...
                    squeeze(nanmean(n(:,l.dir==1 & strcmp(l.type, 'Hit'),:),2)), ...
                    squeeze(nanmean(n(:,l.dir==1.75 & strcmp(l.type, 'Hit'),:),2)), ...
                    squeeze(nanmean(n(:,l.dir==1 & strcmp(l.type, 'FA'),:),2)), ...
                    squeeze(nanmean(n(:,l.dir==-1 & strcmp(l.type, 'FA'),:),2)));

    M_avg  = cat(2, squeeze(nanmean(m(:,l.dir==-1.75 & strcmp(l.type, 'Hit'),:),2)), ...
                    squeeze(nanmean(m(:,l.dir==-1 & strcmp(l.type, 'Hit'),:),2)), ...
                    squeeze(nanmean(m(:,l.dir==-.5 & strcmp(l.type, 'Hit'),:),2)), ...
                    squeeze(nanmean(m(:,l.dir==.5 & strcmp(l.type, 'Hit'),:),2)), ...
                    squeeze(nanmean(m(:,l.dir==1 & strcmp(l.type, 'Hit'),:),2)), ...
                    squeeze(nanmean(m(:,l.dir==1.75 & strcmp(l.type, 'Hit'),:),2)), ...
                    squeeze(nanmean(m(:,l.dir==1 & strcmp(l.type, 'FA'),:),2)), ...
                    squeeze(nanmean(m(:,l.dir==-1 & strcmp(l.type, 'FA'),:),2)));
                
    % By direction only
%     N_avg  = cat(2, squeeze(nanmean(n(:,l.dir<0 & strcmp(l.type, 'Hit'),:),2)), ...
%                     squeeze(nanmean(n(:,l.dir>0 & strcmp(l.type, 'Hit'),:),2)), ...
%                     squeeze(nanmean(n(:,          strcmp(l.type, 'FA'),:),2)));
% 
%     M_avg  = cat(2, squeeze(nanmean(m(:,l.dir<0 & strcmp(l.type, 'Hit'),:),2)), ...
%                     squeeze(nanmean(m(:,l.dir>0 & strcmp(l.type, 'Hit'),:),2)), ...
%                     squeeze(nanmean(m(:,          strcmp(l.type, 'FA'),:),2)));
                
    % remove all nan rows
    N_avg(~any(~isnan(N_avg), 2),:) = [];
    M_avg(~any(~isnan(M_avg), 2),:) = [];
    
    % subtract average activity between -2 and -1.5 s
    nrep = size(N_avg,2)/length(t_ax);
    tax_repeated = repmat(t_ax, 1, nrep);
    t_bl = tax_repeated > -1.99 & tax_repeated < -1.5;
    
    N_avg = (N_avg - nanmean(N_avg(:,t_bl),2));
    M_avg = (M_avg - nanmean(M_avg(:,t_bl),2));
    
end

function [W_toPot, W_toNull, coeffM, expN, expM] = calculate_movement_potent_null_transforms(N, M, t_ax)

    lick_inds_to_use = [1:6];
    t_starts_to_use  = (lick_inds_to_use-1) * length(t_ax) + 1;
    t_ends_to_use    = lick_inds_to_use*300;
    t_inds           =  arrayfun(@(s, e) s:e, t_starts_to_use, t_ends_to_use, 'UniformOutput', false);
    t_inds           = cell2mat(t_inds);

    N = N(:, t_inds);
    M = M(:, t_inds);
    
    nDim_denoise = 20;
    nDim_M = 1;
    nDim_N = 2;
    
    % subtract average activity between -2 and -1.5 s
    nrep = size(N,2)/length(t_ax);
    tax_repeated = repmat(t_ax, 1, nrep);
    t_rel = isbetween(tax_repeated, [-1 .5]);
    
    [coeffN, scoreN, ~, ~, expN] = pca(N(:,t_rel)');
    [coeffM, scoreM, ~, ~, expM] = pca(M(:,t_rel)');

    Ndr = coeffN(:,1:nDim_denoise)' * N;
    Mdr = coeffM(:,1:nDim_M)' * M;
    
    % subtract average activity between -2 and -1.5 s
    t_bl = tax_repeated > -1.99 & tax_repeated < -1.5;
    
    Ndr = Ndr - nanmean(Ndr(:,t_bl),2);
    Mdr = Mdr - nanmean(Mdr(:,t_bl),2);
    
    % select only lick time
    t_lick = isbetween(tax_repeated, [-.5 .5]);
    
    % Calculate the pseudo-inverse of N
%     try
    N_pinv = pinv(Ndr(:,t_lick));
%     catch
%         keyboard
%     end
    
    % Compute W using the pseudo-inverse of N
    W = Mdr(:,t_lick) * N_pinv;
    W_null = null(W)';
    
    
    % rotate Wnull to explain pre-lick variance
    t_pre = tax_repeated > -.5 & tax_repeated < 0;

    N_null = W_null * Ndr;
    [coeffNull, scoreNull, ~, ~, expNull] = pca(N_null(:,t_pre)');
    W_null = coeffNull(:,1:nDim_N)' * W_null;
    N_null = W_null * Ndr;
%     if sum(N_null(1,:))<0, W_null(1,:) = -1 * W_null(1,:); end
%     disp(expNull(1:5))
    
    W_toPot = W * coeffN(:,1:nDim_denoise)';
    W_toNull = W_null * coeffN(:,1:nDim_denoise)';
    coeffM = coeffM(:, 1:nDim_M);

end

function [moveSpaceProj] = project_to_movement_subspaces(W_toPot, W_toNull, coeffM, N, M, tf_prefs, t_ax)

    fast = tf_prefs.tf > 0 & tf_prefs.tf_p < .05;
    slow = tf_prefs.tf < 0 & tf_prefs.tf_p < .05;
    none = tf_prefs.tf_p > .05;

    % subtract average activity between -2 and -1.5 s
    nrep = size(N,2)/length(t_ax);
    tax_repeated = repmat(t_ax, 1, nrep);
    
    N_f = N;
    N_f(~fast,:) = 0;
    N_s = N;
    N_s(~slow,:) = 0;
    N_n = N;
    N_n(~none,:) = 0;
    
    N(:,301:300:end) = nan;
    N_f(:,301:300:end) = nan;
    N_s(:,301:300:end) = nan;
    N_n(:,301:300:end) = nan;
    
    % get split projections
    moveSpaceProj.N_pot    = W_toPot * N;  
    moveSpaceProj.N_pot_f  = W_toPot * N_f;
    moveSpaceProj.N_pot_s  = W_toPot * N_s;
    moveSpaceProj.N_pot_n  = W_toPot * N_n;
    
    moveSpaceProj.N_null   = W_toNull * N;
    moveSpaceProj.N_null_f = W_toNull * N_f;
    moveSpaceProj.N_null_s = W_toNull * N_s;
    moveSpaceProj.N_null_n = W_toNull * N_n;
    
end

function avg_val_resps = get_session_average_responses(trials, daq, fr, tax_fr, resps, train_trials, ops)
% 
% Get averaged responses to task events, but for hit/change responses, remove trials used for
% calculating movement potent/null space

resp_fields = fields(resps);
% keyboard
for r = 1:numel(resp_fields)
   resp_field = resp_fields{r};
   
   if ~contains(resp_field, 'ch') & ~contains(resp_field, 'hit')
       avg_val_resps.(resp_field) = squeeze(nanmean(resps.(resp_field),2));
   end
   
end

% calculate changes, hits
[t, tr_t, info] = get_times_of_events(trials, daq, ops, 'change');
ch_tfs = info(:,1);
hit    = info(:,2);
exp    = info(:,3);
rts    = info(:,4);
tr_nr  = info(:,5);
inc_tr = ~ismember(tr_nr, train_trials);
ch_vals = [.25 1 1.5 2 2.5 3 3.75]-2;


for ii = 1:length(ch_vals)
    ch_tf = ch_vals(ii);
    
    % hit, expected
    [ch_tax, psth] = get_response_to_event_from_FR_matrix(fr, tax_fr, t(ch_tfs==ch_tf&hit&exp&inc_tr), [-1 2]);
    psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);

    avg_val_resps.(sprintf('psth_chHE%d', ii)) = squeeze(nanmean(psth, 2));
    clear psth
    
    % hit, expected, short RT
    mid_rt_range= prctile(rts(ch_tfs==ch_tf&hit&exp&inc_tr), [33 67]);
    fast_rt = rts<mid_rt_range(1);
    [ch_tax, psth] = get_response_to_event_from_FR_matrix(fr, tax_fr, t(ch_tfs==ch_tf&hit&exp&fast_rt&inc_tr), [-1 2]);
    psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
    avg_val_resps.(sprintf('psth_chHEshortRT%d', ii)) = squeeze(nanmean(psth, 2));
    clear psth
    
    % hit, expected, medium RT
    med_rt = isbetween(rts, mid_rt_range);
    [ch_tax, psth] = get_response_to_event_from_FR_matrix(fr, tax_fr, t(ch_tfs==ch_tf&hit&exp&med_rt&inc_tr), [-1 2]);
    psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
    avg_val_resps.(sprintf('psth_chHEmedRT%d', ii)) = squeeze(nanmean(psth, 2));
    clear psth
    
    % hit, expected, long RT
    long_rt = rts>mid_rt_range(2);
    [ch_tax, psth] = get_response_to_event_from_FR_matrix(fr, tax_fr, t(ch_tfs==ch_tf&hit&exp&long_rt&inc_tr), [-1 2]);
    psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
    avg_val_resps.(sprintf('psth_chHElongRT%d', ii)) = squeeze(nanmean(psth, 2));
    
    clear psth
end

% Hit licks by magnitude
[t, tr_t, info] = get_times_of_events(trials, daq, ops, 'hit');
ch_tfs = info(:,1);
exp    = info(:,2);
tr_nr  = info(:,4);
inc_tr = ~ismember(tr_nr, train_trials);
ch_vals = [.25 1 1.5 2 2.5 3 3.75]-2;

for ii = 1:length(ch_vals)
    ch_tf = ch_vals(ii);
    [hit_tax, psth] = get_response_to_event_from_FR_matrix(fr, tax_fr, t(ch_tfs==ch_tf&exp&inc_tr), [-2 1]);
    psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
    avg_val_resps.(sprintf('psth_hitE%d', ii)) = squeeze(nanmean(psth,2));
    clear psth
end


end



% 
%%
% 
% %% Select specific lick types to use
% % 1-6: changes (-1.75 to +1.75); 7,8: early licks (expF, expS)
% 
% lick_inds_to_use = [1:6];
% t_starts_to_use  = (lick_inds_to_use-1) * length(t_ax) + 1;
% t_ends_to_use    = lick_inds_to_use*300;
% t_inds           =  arrayfun(@(s, e) s:e, t_starts_to_use, t_ends_to_use, 'UniformOutput', false);
% t_inds           = cell2mat(t_inds);
% 
% Ns_select = cell(size(Ns));
% Ms_select = cell(size(Ms));
% for s = 1:length(sessions)
%     if ~isempty(Ns{s})
%         Ns_select{s} = Ns{s}(:,t_inds);
%     end
%     if ~isempty(Ms{s})
%         Ms_select{s} = Ms{s}(:,t_inds);
%     end
%     
% end
% 
% % Generate matrices N and M:
% %   N: nN x (t x 2) array containing concatenanted average activity around fast and slow licks
% %   M: (nRoi x nSessiosn) x (t x 2) array containing motion energy in different rois. 
% 
% N = vertcat(Ns_select{:});
% M = vertcat(Ms_select{:});
% 
% % remove all nan rows
% N(~any(~isnan(N), 2),:)=[];
% M(~any(~isnan(M), 2),:)=[];
% 
% % N = (N - nanmean(N,2))./nanstd(N,[],2);
% % 
% % N(isnan(N))=0;
% % M(isnan(M))=0;
% 
% % subtract average activity between -2 and -1.5 s
% nrep = size(N,2)/length(t_ax);
% tax_repeated = repmat(t_ax, 1, nrep);
% t_bl = tax_repeated > -1.99 & tax_repeated < -1.5;
% 
% N = (N - nanmean(N(:,t_bl),2));
% M = (M - nanmean(M(:,t_bl),2));
% % N = (N - nanmean(N(:,t_bl),2))./nanstd(N(:,t_bl),[],2);
% % M = (M - nanmean(M(:,t_bl),2))./nanstd(M(:,t_bl),[],2);
% 
% % N = smoothdata(N,2,'movmean',5);
% 
% %% PCA to reduce dimensionality
% nDim_denoise = 20;
% nDim_M = 2;
% nDim_N = 2;
% 
% t_rel = isbetween(tax_repeated, [-1 .5]);
% [coeffN, scoreN, ~, ~, expN] = pca(N(:,t_rel)');
% [coeffM, scoreM, ~, ~, expM] = pca(M(:,t_rel)');
% 
% Ndr = coeffN(:,1:nDim_denoise)' * N;
% Mdr = coeffM(:,1:nDim_M)' * M;
% 
% % Regression - find output potent dims
% 
% % subtract average activity between -2 and -1.5 s
% nrep = size(Ndr,2)/length(t_ax);
% tax_repeated = repmat(t_ax, 1, nrep);
% t_bl = tax_repeated > -1.99 & tax_repeated < -1.5;
% 
% Ndr = Ndr - nanmean(Ndr(:,t_bl),2);
% Mdr = Mdr - nanmean(Mdr(:,t_bl),2);
% 
% % time shift movement by 30ms
% % Ndr = Ndr(:,1:end-3);
% % Mdr = Mdr(:,4:end);
% 
% % select only lick time
% t_lick = isbetween(tax_repeated, [0 .5]);
% 
% % Calculate the pseudo-inverse of N
% N_pinv = pinv(Ndr(:,t_lick));
% 
% % Compute W using the pseudo-inverse of N
% W = Mdr(:,t_lick) * N_pinv;
% W_null = null(W)';
% 
% % rotate Wnull to explain pre-lick variance
% t_pre = tax_repeated > -.5 & tax_repeated < 0;
% % t_pre(1800:end)=0; % dont include false alarms
% N_null = W_null * Ndr;
% [coeffNull, scoreNull, ~, ~, expNull] = pca(N_null(:,t_pre)');
% W_null = coeffNull(:,1:nDim_N)' * W_null;
% N_null = W_null * Ndr;
% if sum(N_null(1,:))<0, W_null(1,:) = -1 * W_null(1,:); end
% disp(expNull(1:5))
% % close all
% % figure; plot(Mdr(1,:)','k'); hold on; plot((W(1:2,:)*Ndr)','r'); plot((W_null(1:2,:)*Ndr)','b')
% % N_null = W_null * Ndr;
% % figure; plot((W_null(1:3,:)*Ndr)' )
% % figure; 
% % plot([t_ax, t_ax+3, t_ax+6, t_ax+9],Mdr','k'); 
% % hold on; 
% % plot([t_ax, t_ax+3, t_ax+6, t_ax+9],(W*Ndr)','r'); 
% % plot([t_ax, t_ax+3, t_ax+6, t_ax+9],(W_null*Ndr)','b')
% % figure; 
% % plot([t_ax, t_ax+3, t_ax+6, t_ax+9],(W_null*Ndr)'); legend
% 
% %% Split W and W_null into tf responsive and non-responsive
% 
% % get full mappings from single units to movement potent and null space
% W_toPot = W * coeffN(:,1:nDim_denoise)';
% W_toNull = W_null * coeffN(:,1:nDim_denoise)';
% 
% tf_prefs = vertcat(tfis{:});
% % fast = tf_prefs.tf > 0 & tf_prefs.tf_p < .05;
% % slow = tf_prefs.tf < 0 & tf_prefs.tf_p < .05;
% % % none = abs(tf_prefs.tf)<.005 & tf_prefs.tf_p > .05;
% % none =  tf_prefs.tf_p > .05;
% 
% 
% fast = tf_prefs.tf > 0 & tf_prefs.tf_p < .05;
% slow = tf_prefs.tf < 0 & tf_prefs.tf_p < .05;
% % none =  tf_prefs.tf_p > .5;
% none = tf_prefs.tf_p > .05;
% 
% 
% N = vertcat(Ns{:});
% N = N(:,1:1800);
% 
% % N = (N-nanmean(N,2))./nanstd(N,[],2);
% % N = smoothdata(N,2,'movmean', 5);
% N(~any(~isnan(N), 2),:)=[];
% N_f = N; 
% N_f(~fast,:) = 0;
% N_s = N;
% N_s(~slow,:) = 0;
% N_n = N;
% N_n(~none,:) = 0;
% % % 
% % N   = N/norm(N,2);
% % N_f = N_f/norm(N_f,2);
% % N_s = N_s/norm(N_s,2);
% % N_n = N_n/norm(N_n,2);
% 
% N(:,301:300:end) = nan;
% N_f(:,301:300:end) = nan;
% N_s(:,301:300:end) = nan;
% N_n(:,301:300:end) = nan;
% 
% % get split projections
% N_pot    = W_toPot * N;  
% N_pot_f  = W_toPot * N_f;
% N_pot_s  = W_toPot * N_s;
% N_pot_n  = W_toPot * N_n;
% 
% % N_pot_f  = N_pot_f/norm(N_pot_f);
% % N_pot_s  = N_pot_s/norm(N_pot_s);
% % N_pot_n  = N_pot_n/norm(N_pot_n);
% 
% N_null   = W_toNull * N;
% N_null_f = W_toNull * N_f;
% N_null_s = W_toNull * N_s;
% N_null_n = W_toNull * N_n;
% 
% % N_null_f  = N_null_f/norm(N_null_f);
% % N_null_s  = N_null_s/norm(N_null_s);
% % N_null_n  = N_null_n/norm(N_null_n);
% 
% M = vertcat(Ms{:});
% M(:,301:300:end) = nan;
% M(~any(~isnan(M), 2),:)=[];
% Mdr = coeffM(:,1:nDim_M)' * M;
% 
% %% Generate plots of movement potent and null proj, split and not split, to TFs, changes, hits
% plot_dir = fullfile(ops.saveDir, 'nullSpaceAnalyses');
% 
% if ~exist(plot_dir,'dir'); mkdir(plot_dir); end
% close all
% % clrs = (RedGreyBlue(6));
% % for ii = [1:6]
% % ids = [100:200] + (ii-1)*300;
% % plot(N_pot(2,ids), N_null(1,ids), 'color',clrs(ii,:));
% % end
% % figure; hold on
% % clrs = RedGreyBlue(2);
% % for ii = 1:2
% % ids = [1:200] + (ii+6-1)*300;
% % plot(N_pot(1,ids), N_null(2,ids), 'color',clrs(ii,:));
% % end
% ch_clrs   = [flipud(cbrewer2('Blues', 3)); cbrewer2('Reds', 4)];
% pot_clrs  = flipud(cbrewer2('Greens', nDim_M+1));
% null_clrs = flipud(cbrewer2('Blues', nDim_N+1));
% mov_clrs  = flipud(cbrewer2('Greys', nDim_M+1));
% f = figure('Units', 'normalized', 'OuterPosition', [.3 .1 .24 .24]);
% hold on
% for ii = 1%:nDim_M
%     plot(Mdr(ii,1:1800), 'color', mov_clrs(ii,:));
%     plot(N_pot(ii,1:1800), 'color', pot_clrs(ii,:));
% end
% for ii = 1:nDim_N
%     plot(N_null(ii,1:1800), 'color', null_clrs(ii,:));
% end
% % add lick times
% yl = ylim;
% for ii = 1:6
%     pos = 200 + 300*(ii-1);
%     plot([pos pos], yl, 'color',ch_clrs(ii,:), 'linewidth', .5)
% end
% legend({'motion', 'movement potent 1', 'movement null 1', 'movment null 2' }, 'box', 'off', 'location', 'northoutside')
% saveas(f, fullfile(plot_dir, 'all_dims'))
% saveas(f, fullfile(plot_dir, 'all_dims'), 'png')
% 
% % by fast/slow/non-resp contributions
% subtypes = {'f', 's', 'n'};
% st_clrs  = [ops.colors.F_pref; ops.colors.S_pref; [.5 .5 .5]];
% f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .24 .36]);
% dim_cmps = {'N_pot', 1; 'N_null', 1; 'N_null', 2};
% for d = 1:size(dim_cmps,1)
%     dim = dim_cmps(d,:);
%     subplot(3,1,d); hold on
%     hold on
%     for sti = 1:numel(subtypes)
%         st = subtypes{sti};
%         evalin('caller', sprintf('plot(%s_%s(%d, 1:1800), ''color'', st_clrs(sti,:))', dim{1}, st, dim{2}))
%     end
%     % add lick times
%     yl = ylim;
%     for ii = 1:6
%         pos = 200 + 300*(ii-1);
%         plot([pos pos], yl, 'color',ch_clrs(ii,:), 'linewidth', .5)
%     end
%     ylabel(sprintf('%s %d', strrep(dim{1},'N_', 'movement '), dim{2}))
% end
% 
% saveas(f, fullfile(plot_dir, 'dims_by_tfPref'))
% saveas(f, fullfile(plot_dir, 'dims_by_tfPref'), 'png')
% 
% % compare fast/slow/non-resp contributions to movement pot, null 
% f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .24 .36]);
% dim_cmps = {'N_pot', 1; 'N_null', 1; 'N_null', 2};
% dim_clrs = [pot_clrs(1,:); null_clrs];
% for d = 1:size(dim_cmps,1)
%     dim = dim_cmps(d,:);
%     for sti = 1:numel(subtypes)
%         st = subtypes{sti};
%         subplot(3,1,sti); hold on
%         evalin('caller', sprintf('plot(%s_%s(%d, 1:1800), ''color'', dim_clrs(%d,:))', dim{1}, st, dim{2}, d));
%         if d==size(dim_cmps,1)
%             ylabel(sprintf('tf pref: %s', st))
%         end
%     end
% end
% % add lick times
% for sp = 1:3
%     subplot(3,1,sp); hold on;
%     % add lick times
%     yl = ylim;
%     for ii = 1:6
%         pos = 200 + 300*(ii-1);
%         plot([pos pos], yl, 'color',ch_clrs(ii,:), 'linewidth', .5)
%     end
% end
% 
% % saveas(f, fullfile(plot_dir, 'dim_comparison_by_tfPref'))
% % saveas(f, fullfile(plot_dir, 'dim_comparison_by_tfPref'), 'png')
% 
% %% Project movement potent, null dims onto space spanned by F,S,L axes
% 
% W_potnull = vertcat(W_toPot(1,:), W_toNull);
% W_potnull = normr(W_potnull);
% W_tf      = double([fast'; slow'; none']);
% W_tf      = normr(W_tf);
% % P_tf      = W_tf' * W_tf; % projection matrix
% W_projTF  = W_tf * (W_potnull)';
% f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .2 .16]);
% proj_clrs = [pot_clrs(1,:); null_clrs];
% hold on;
% for ii = 1:3
%     quiver3(0, 0, 0, W_projTF(1,ii), W_projTF(2,ii), W_projTF(3,ii), 'color', proj_clrs(ii,:), 'linewidth', 2);
% end
% axis equal;
% grid on;
% xlabel('Fast');
% ylabel('Slow');
% zlabel('None');
% title('Projection of movement dims onto subspace defined by TF');
% view(3)
% axis equal
% grid on

% % view([-396, 20])
% 
% view([-378, 15])
% % xlim([-.2 .2]); ylim([-.2 .2]); zlim([-.02 .2]);
% % saveas(f, fullfile(plot_dir, 'movement_dims_in_TF_space'))
% % saveas(f, fullfile(plot_dir, 'movement_dims_in_TF_space'), 'png')
% 
% %% Project F,S,N onto movement dims
% W_projMov = W_potnull * W_tf';
% f = figure('Units', 'normalized', 'OuterPosition', [.3 .1 .2 .16]);
% proj_clrs = [ops.colors.F; ops.colors.S; [.5 .5 .5]];
% hold on;
% for ii = 1:3
%     quiver3(0, 0, 0, W_projMov(2,ii), W_projMov(3,ii), W_projMov(1,ii), 'color', proj_clrs(ii,:), 'linewidth', 2);
% end
% axis equal;
% grid on;
% xlabel('Movment null 1');
% ylabel('Movment null 2');
% zlabel('Movement potent');
% title('Projection of movement dims onto subspace defined by TF');
% view(3)
% axis equal
% grid on
% view([-396, 31])
% 
% % saveas(f, fullfile(plot_dir, 'TF_dims_in_movement_space'))
% % saveas(f, fullfile(plot_dir, 'TF_dims_in_movement_space'), 'png')
% 
% %% Visualize 'psths' along each movement dimension
% inc_units   = logical(inc_units);
% roi_indexes = indexes(inc_units, :);
% roi_resps   = avg_resps(inc_units, :);
% conts = roi_indexes.conts;
% roi_resps{conts==-1,'bl'} = fliplr(roi_resps{conts==-1,'bl'});
% % frmus = vertcat(frstats{:,1});
% % frsds = vertcat(frstats{:,2});
% % roi_resps.FRmu = frmus*100;
% % roi_resps.FRsd = frsds*100;
% 
% % project responses onto dims
% dims.movement_potent = W_toPot(1,:)';
% dims.movement_null1  = W_toNull(1,:)';
% dims.movement_null2  = W_toNull(2,:)';  
% dims.tf_fast         = W_tf(1,:)';
% dims.tf_slow         = W_tf(2,:)';
% dims.tf_none         = W_tf(3,:)';
% 
% projs = project_resps_onto_ax(roi_resps, dims);
% 
% 
% [f1d, fhd] = visualize_nullSpace_projected_activity(projs, t_ax_resps, {'movement_null1', 'movement_null2','movement_potent'}, ops);
% 
% % saveas(f1d, fullfile(plot_dir, 'move_dim_traj1D'))
% % saveas(f1d, fullfile(plot_dir, 'move_dim_traj1D'), 'png')
% % saveas(fhd, fullfile(plot_dir, 'move_dim_traj3D'))
% % saveas(fhd, fullfile(plot_dir, 'move_dim_traj3D'), 'png')

%%





