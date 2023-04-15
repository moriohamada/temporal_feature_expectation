function fit_full_glm_hpc(n)
% 
% Fit full glm on hpc. For this function, features should already have been extracted using
% prep_Xdm_yfr_by_unit_for_glm.m.
% 
% --------------------------------------------------------------------------------------------------
%%
[~, name] = system('hostname');
name = name(1:5);
if strcmp(name, 'earth')
addpath(genpath('/home/morio/Documents/MATLAB/General'));
addpath(genpath('/home/morio/Documents/MATLAB/switch-task/Analysis_pipeline'));
else
addpath(genpath('/nfs/nhome/live/morioh/Documents/MATLAB/General'));
addpath(genpath('/nfs/nhome/live/morioh/Documents/MATLAB/switch-task/Analysis_pipeline'));
end
%%
if strcmp(name, 'earth')
paths.dataDir = '/mnt/ceph/public/projects/MoHa_20240218_SwitchChangeDetect_spForGLM/';
paths.saveDir = '/mnt/ceph/public/projects/MoHa_20240218_SwitchChangeDetect_spForGLM/';
else
paths.dataDir = '/ceph/mrsic_flogel/public/projects/MoHa_20240218_SwitchChangeDetect_spForGLM/';
paths.saveDir = '/ceph/mrsic_flogel/public/projects/MoHa_20240218_SwitchChangeDetect_spForGLM/ridge';
end


%% Load in data

spFiles = dir2(fullfile(paths.dataDir,'spikeTimes'));
spFile  = spFiles{n};
clear spFiles

% load spike times
st = loadVariable(fullfile(paths.dataDir, 'spikeTimes', spFile), 'st');
if length(st)/range(st) < .25
    fprintf('\nFR too low for GLM fitting - skipping unit!')
    if strcmp(name, 'earth')
        return
    else
        exit
    end
end
% load DM
animal  = spFile(1:6);
session = spFile(8:9);
cid     = spFile(11:15);
fprintf('Fitting glm for %s %s %s\n', animal, session, cid);
[features, trStarts, ops] = loadVariables(fullfile(paths.dataDir, 'features', sprintf('%s_%s.mat', animal, session)), ...
                                          'features', 'trStarts','ops');

%% Further ops for fitting
ops.nlambdas   = 10;
ops.kFold      = 10;
ops.maxIter    = 1000;
ops.tol        = .01;
ops.nlambdas   = 100;
ops.smoothPred = 5;

%% Create DM and y vector
params.animal  = animal;
params.session = session;
params.cid     = cid;
features_n = add_st_to_glm_features_v2(features, trStarts, st, ops);
[expt, dspec] = get_expt_dspec_for_glm(features_n, params, ops);

%%

% % get cross val inds
xval_inds = crossvalind('Kfold',length(features_n),ops.kFold);

corrs = nan(ops.kFold, ops.nlambdas);
rmses = nan(ops.kFold, ops.nlambdas);
xval_ws = zeros(ops.kFold, dspec.edim+1, ops.nlambdas);

% set glmnet options
clear options
options.alpha = 0;
options.nlambda = ops.nlambdas;
options.standardize = false;
options.nfolds = ops.kFold;
options = glmnetSet(options);


%%
fprintf('Building design matrix...\t')

[dm, trialIDs] = buildGLM.compileSparseDesignMatrixWithTrialInd(dspec, 1:length(features_n));
dm = buildGLM.addBiasColumn(dm);
y = buildGLM.getBinnedSpikeTrain(expt, 'SpTrain', dm.trialIndices);

%%
% set motE and treadmill around licks to 0
regressors = {dspec.covar.label};
edims = [dspec.covar.edim];
dim_ids = [0,  cumsum(edims)] + 1; % add one for offset
lick_dims =  find(contains(regressors, 'Lick'));
lick_regressor_IDs = [];
for ii = 1:length(lick_dims)
    lick_regressor_IDs = [lick_regressor_IDs, dim_ids(lick_dims(ii))+1:(dim_ids(lick_dims(ii)+1))];
end
lick_active = sum(dm.X(:,lick_regressor_IDs),2)>0;

move_dims =  find(strcmp(regressors, 'motionEnergy') | strcmp(regressors, 'runSpeed'));
move_regressor_IDs = [];
for ii = 1:length(move_dims)
    move_regressor_IDs = [move_regressor_IDs, dim_ids(move_dims(ii))+1:(dim_ids(move_dims(ii)+1))];
end
dm.X(lick_active,move_regressor_IDs) = 0;
%%
% get fold IDs
foldIDs = zeros(size(trialIDs));
trialNums = 1:length(features_n);
for tr = trialNums
    this_tr_fold = xval_inds(tr);
    this_tr_rows = trialIDs == tr;
    foldIDs(this_tr_rows) = this_tr_fold;
end
fprintf('done.\n')

%% Find best lambda
fprintf('Fitting models...\t')
tic
CVinfo = cvglmnet(dm.X, y,'poisson', options, 'deviance',ops.kFold, foldIDs, true);
fprintf('done.\n')
toc

%% Predict from best lambda
fprintf('Predicting on cross-validated data...\t')
best_lambda = CVinfo.lambda_min;
best_lambda_idx = find(CVinfo.lambda==best_lambda);
w = CVinfo.glmnet_fit.beta(:,best_lambda_idx);
xval_corrs = zeros(1,ops.kFold);
for k = 1:ops.kFold
    this_fold_x = dm.X(foldIDs==k,:);
    this_fold_y = y(foldIDs==k);

    y_pred = glmnetPredict(CVinfo.glmnet_fit, this_fold_x, best_lambda, 'response');
    xval_corrs(k) = corr(smoothdata(this_fold_y,'movmean',ops.smoothPred),...
                         smoothdata(y_pred,'movmean',ops.smoothPred));
end
fprintf('done.\n')

%% Find indexes corresponding to regressors

% Find indexes for each regressor
regressors = {dspec.covar.label};

edims = [dspec.covar.edim];
dim_ids = [0,  cumsum(edims)] + 1; % add one for offset
clear regressor_dims;
for r = 1:length(regressors)
    regressor_dims{r} = dim_ids(r)+1:dim_ids(r+1);
end

% Get some correlated regressors 
% baseline TF
tf_dims = find(contains(regressors, 'TFbl') | contains(regressors, 'Phase'));
regressors{end+1} = 'TFbl_all';
lick_regressor_IDs = [];
for ii = 1:length(tf_dims)
    lick_regressor_IDs = [lick_regressor_IDs, dim_ids(tf_dims(ii))+1:(dim_ids(tf_dims(ii)+1))];
end
regressor_dims{end+1} = lick_regressor_IDs;

% Phases
phase_dims = find(contains(regressors, 'Phase'));
regressors{end+1} = 'Phases_all';
lick_regressor_IDs = [];
for ii = 1:length(phase_dims)
    lick_regressor_IDs = [lick_regressor_IDs, dim_ids(tf_dims(ii))+1:(dim_ids(tf_dims(ii)+1))];
end
regressor_dims{end+1} = lick_regressor_IDs;

% Pre lick
lick_dims =  find(contains(regressors, 'PreLick') & ~contains(regressors, '_all'));
               
regressors{end+1} = 'Premotor';
lick_regressor_IDs = [];
for ii = 1:length(lick_dims)
    lick_regressor_IDs = [lick_regressor_IDs, dim_ids(lick_dims(ii))+1:(dim_ids(lick_dims(ii)+1))];
end
regressor_dims{end+1} = lick_regressor_IDs;


% All movement
move_dims =  find((contains(regressors, 'Lick') | ...
                   strcmp(regressors, 'motionEnergy') | strcmp(regressors, 'runSpeed')) ...
                   & ~contains(regressors, '_all'));
               
regressors{end+1} = 'Movement';
lick_regressor_IDs = [];
for ii = 1:length(move_dims)
    lick_regressor_IDs = [lick_regressor_IDs, dim_ids(move_dims(ii))+1:(dim_ids(move_dims(ii)+1))];
end
regressor_dims{end+1} = lick_regressor_IDs;

% All
regressors{end+1} = 'All';
regressor_dims{end+1} = 2:dim_ids(end);

%% Lesion regressors in sequence to test significance
fprintf('Fitting lesioned models...\n')
tic
corrs_lesioned = nan(length(regressors), ops.kFold); % full data correlation after lesioning
corrs_active = nan(length(regressors), ops.kFold); % correlation when regressor is active
corrs_active_lesioned = nan(length(regressors), ops.kFold); % correlation when regressor active, lesioned

for r = 1:length(regressors)
    regressor = regressors{r};
    fprintf('\tregressor %d/%d: %s\n', r, length(regressors), regressor);
    if contains(regressor,'Phase') & ~strcmp(regressor, 'Phase_all')
        continue
    end
        
    fit_lesioned = CVinfo.glmnet_fit;
    
    % set this regressor weights to zero
    w_lesioned = w;
    dims = regressor_dims{r};
    w_lesioned(dims)=0;
    
    fit_lesioned.beta(:,best_lambda_idx) = w_lesioned;
    
    parfor k = 1:ops.kFold
        this_fold_x = dm.X(foldIDs==k,:);
        this_fold_y = y(foldIDs==k);
        y_pred = glmnetPredict(fit_lesioned, this_fold_x, best_lambda, 'response');
        corrs_lesioned(r,k) = corr(smoothdata(this_fold_y,'movmean',ops.smoothPred), ...
                                   smoothdata(y_pred,'movmean',ops.smoothPred));
                               
        % find regressor-active periods
        active_times = sum(this_fold_x(:,dims),2)~=0;
        if sum(active_times)==0
            continue
        end
        y_pred_active = glmnetPredict(CVinfo.glmnet_fit, this_fold_x(active_times,:), best_lambda, 'response');
        y_pred_active_lesioned = glmnetPredict(fit_lesioned, this_fold_x(active_times,:), best_lambda, 'response');
        corrs_active(r,k) = corr(smoothdata(this_fold_y(active_times), 'movmean', ops.smoothPred), ...
                                 smoothdata(y_pred_active, 'movmean', ops.smoothPred));
        corrs_active_lesioned(r,k) = corr(smoothdata(this_fold_y(active_times), 'movmean', ops.smoothPred), ...
                                          smoothdata(y_pred_active_lesioned, 'movmean', ops.smoothPred));               
    end
    
end
toc
fprintf('done.\n')

%% Calculate significance and visualize kernels
p_corr = ones(length(regressors),1);
p_corr_active = ones(length(regressors),1);

for r = 1:length(regressors)
    regressor = regressors{r};
    [~,p_corr(r)] = ttest(xval_corrs - corrs_lesioned(r,:));
    [~,p_corr_active(r)] = ttest(corrs_active(r,:) - corrs_active_lesioned(r,:));
end

p_plot = p_corr_active;

f_kernels= figure('Units', 'normalized', 'OuterPosition', [.1 .1 .15 .45],'visible','on');
hold on
nCovar = length(regressors)-5;
n_phase = sum(contains(regressors,'Phase'));
% plot all except phases
ii = 0;
for kCov = 1:nCovar
    label = regressors{kCov};
    if contains(label, 'Phase')
        continue;
    else
        ii=ii+1;
    end
    
    subplot(ceil((nCovar-n_phase)/2)+1, 2, ii)
    hold on
    
    this_covar_dims = regressor_dims{kCov};
    if length(this_covar_dims)==1
        scatter(0, w(this_covar_dims), 50, 'x');
        %ylim(ws(this_covar_dims)*[.99 1.01])
        yticks(ws(this_covar_dims));
        set(gca, 'Xcolor', 'none')
    else
        plot(dspec.covar(kCov).basis.centers * ops.tBin, smoothdata(w(this_covar_dims), 'movmedian', 3));
    end
    title(sprintf('%s, p = %.3f',label, p_plot(kCov)), 'FontSize', 8, 'FontWeight', 'normal');
end
ii=ii+1;
subplot(ceil((nCovar-n_phase)/2)+1, 2, ii)
title(sprintf('TF=%.3f, preL=%.3f', p_plot(nCovar+1), p_plot(nCovar+3)), 'FontSize', 8, 'FontWeight', 'normal');

%% Save data

save_folder = fullfile(paths.saveDir,'ridge', animal, session);
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
end
if ~exist(fullfile(save_folder, 'kernel_plots'), 'dir')
    mkdir(fullfile(save_folder, 'kernel_plots'));
end

% save data

save(fullfile(save_folder, sprintf('cid%s.mat',cid)), ...
     'ops', 'options', ...
     'w', 'regressors', 'regressor_dims', ...
     'xval_corrs', 'corrs_active', 'corrs_lesioned' ,'corrs_active_lesioned', ...
     'p_corr', 'p_corr_active')
 
saveas(f_kernels, fullfile(save_folder, 'kernel_plots', cid), 'png')

fprintf('\nGLM successfully fit!\n')
toc
if ~strcmp(name, 'earth')
exit
end


end







