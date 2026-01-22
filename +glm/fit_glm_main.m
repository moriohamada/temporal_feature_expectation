function fit_glm_main(n)
% Main function to fit glms to a single unit.
% 
% The whole GLM pipeline consists of:
% 1) prepare design matrices (X)
% 2) extract spike times (y)
% 3) run fits 
% 
% Steps 1 and 2 are be done elsewhere (see prep Xy_for_glm.m). 
% 
% INPUT:
%   n - int - unit number to fit (across all recordings)

%%


[~, name] = system('hostname');
name = name(1:5);
if strcmp(name, 'earth')
addpath(genpath('/home/morio/Documents/MATLAB/General'));
addpath(genpath('/home/morio/Documents/MATLAB/switch-task/final_pipeline'));
else
addpath(genpath('/nfs/nhome/live/morioh/Documents/MATLAB/General'));
addpath(genpath('/nfs/nhome/live/morioh/Documents/MATLAB/switch-task/final_pipeline'));
end

if strcmp(name, 'earth')
paths.dataDir = '/mnt/ceph/public/projects/MoHa_20260120_SwitchChangeDetect_spForGLM/';
paths.saveDir = '/mnt/ceph/public/projects/MoHa_20260120_SwitchChangeDetect_spForGLM/';
else
paths.dataDir = '/ceph/mrsic_flogel/public/projects/MoHa_20260120_SwitchChangeDetect_spForGLM/';
paths.saveDir = '/ceph/mrsic_flogel/public/projects/MoHa_20260120_SwitchChangeDetect_spForGLM/results';
end



%% Load DM and spike data

glm_ops = glm.set_glm_ops();

spFiles = dir2(fullfile(paths.dataDir,'spikeTimes'));
spFile  = spFiles{n};
clear spFiles

% load spike times
st = loadVariable(fullfile(paths.dataDir, 'spikeTimes', spFile), 'st');
if length(st)/range(st) < .25
    fprintf('\nFR too low for GLM fitting - skipping unit!')
    return
end
% load DM
animal  = spFile(1:6);
session = spFile(8:9);
cid     = spFile(11:15);
fprintf('Fitting glm for %s %s %s\n', animal, session, cid);

% also save trial outcomes, start
if ~glm_ops.splitELtf && ~glm_ops.splitFStf
    features_name = 'featuresFull10ms';
elseif ~glm_ops.splitELtf && glm_ops.splitFStf
    features_name = 'featuresFSsplit10ms';
elseif glm_ops.splitELtf && ~glm_ops.splitFStf
    features_name = 'featuresELsplit10ms';
else
    features_name = 'featuresFSELsplit10ms';
end

[features, trStarts] = loadVariables(fullfile(paths.dataDir, features_name, sprintf('%s_%s.mat', animal, session)), ...
                                          'features', 'trStarts');


%%
% Further options for fitting
glm_ops.nlambdas    = 10;
glm_ops.kFold       = 10;
glm_ops.maxit       = 1e4;
glm_ops.thresh      = 1e-4;
glm_ops.nlambdas    = 10;
glm_ops.smoothPred  = 5;
glm_ops.addBias     = true;

%% Create DM and y vector
params.animal  = animal;
params.session = session;
params.cid     = cid;
features = glm.one_hot_changes(features); 
features = glm.one_hot_outcomes(features);
features_n = glm.add_st_to_glm_features(features, trStarts, st, glm_ops);

[expt, dspec] = glm.get_expt_dspec_for_glm(features_n, params, glm_ops);

[dm, trialIDs] = buildGLM.compileSparseDesignMatrixWithTrialInd(dspec, 1:length(features_n));

if glm_ops.addBias
    dm = buildGLM.addBiasColumn(dm);
end
y = buildGLM.getBinnedSpikeTrain(expt, 'SpTrain', dm.trialIndices);


%%
% set motE and treadmill around licks to 0
regressors = {dspec.covar.label};
edims = [dspec.covar.edim];
dim_ids = [0,  cumsum(edims)] + glm_ops.addBias; % add one for offset
lick_dims =  find(contains(regressors, 'Lick'));
regressor_IDs = [];
for ii = 1:length(lick_dims)
    regressor_IDs = [regressor_IDs, dim_ids(lick_dims(ii))+1:(dim_ids(lick_dims(ii)+1))];
end
lick_active = sum(dm.X(:,regressor_IDs),2)>0;

move_dims =  find(strcmp(regressors, 'motionEnergy') | strcmp(regressors, 'runSpeed'));
move_regressor_IDs = [];
for ii = 1:length(move_dims)
    move_regressor_IDs = [move_regressor_IDs, dim_ids(move_dims(ii))+1:(dim_ids(move_dims(ii)+1))];
end
dm.X(lick_active,move_regressor_IDs) = 0;

%% 

% % get cross val inds
xval_inds = crossvalind('Kfold',length(features_n),glm_ops.kFold);

corrs = nan(glm_ops.kFold, glm_ops.nlambdas);
rmses = nan(glm_ops.kFold, glm_ops.nlambdas);
xval_ws = zeros(glm_ops.kFold, dspec.edim+1, glm_ops.nlambdas);

% get fold IDs
foldIDs = zeros(size(trialIDs));
trialNums = 1:length(features_n);
for tr = trialNums
    this_tr_fold = xval_inds(tr);
    this_tr_rows = trialIDs == tr;
    foldIDs(this_tr_rows) = this_tr_fold;
end
 
%% Find best lambda
clear options
options.alpha = 1;
options.nlambda = glm_ops.nlambdas;
options.standardize = false;
options.nfolds = glm_ops.kFold;
options.maxit = glm_ops.maxit;
options.thresh = glm_ops.thresh;
options.lambda = logspace(-4, 0, 9);
options.intr=false;
options = glmnetSet(options);


fprintf('Fitting models...\t')
tic
CVinfo = cvglmnet(dm.X, y, 'poisson', options, 'deviance',glm_ops.kFold, foldIDs, true);
fprintf('done.\n')
toc

%% Predict from best lambda
fprintf('Predicting on cross-validated data...\n')
best_lambda = CVinfo.lambda_min;
fprintf('Best lambda: %.4f\n', best_lambda)
best_lambda_idx = find(CVinfo.lambda==best_lambda);
xval_corrs = zeros(1,glm_ops.kFold);
for k = 1:glm_ops.kFold
    this_fold_x = dm.X(foldIDs==k,:);
    this_fold_y = y(foldIDs==k);

    y_pred = glmnetPredict(CVinfo.glmnet_fit, this_fold_x, best_lambda, 'response');
    xval_corrs(k) = corr(smoothdata(this_fold_y,'movmean',glm_ops.smoothPred),...
                         smoothdata(y_pred,'movmean',glm_ops.smoothPred));
end
fprintf('done.\n')

fprintf('\nMean xval correlations: %.3f\n', mean(xval_corrs))
% if mean(xval_corrs) < .01
%     fprintf('GLM fit too poor! skipping unit...\n')
%     return
% end

%% Find indexes corresponding to regressors

% Find indexes for each regressor
regressors = {dspec.covar.label};

edims = [dspec.covar.edim];
dim_ids = [0,  cumsum(edims)] + glm_ops.addBias; % add one for offset
clear regressor_dims;
for r = 1:length(regressors)
    regressor_dims{r} = dim_ids(r)+1:dim_ids(r+1);
end

%% Lesion (circshift) regressors and refit with fixed lambda
% Get full model coefficients
beta_full = cvglmnetCoef(CVinfo, 'lambda_min'); 
best_lambda = CVinfo.lambda_min;

lesion_groups = {
    'TFbl',      find(contains(regressors, 'TFbl'));
    'TFch',      find(contains(regressors, 'TFch'));
    'PreLick',   find(contains(regressors, 'PreLick'));
    'Lick',      find(strcmp(regressors, 'Lick'));
    'baseline',  find(strcmp(regressors, 'baseline'));
    'all',       find(contains(regressors, 'Lick')|contains(regressors, 'TF'));
};

n_folds = max(foldIDs);
n_groups = size(lesion_groups, 1);
n_perms = 20;
lesion_results = struct();

options_fixed = options;
options_fixed.lambda = best_lambda;

for g = 1:n_groups
    group_name = lesion_groups{g, 1};
    group_regs = lesion_groups{g, 2};
    
    cols_to_shuffle = [];
    for r = group_regs
        cols_to_shuffle = [cols_to_shuffle, regressor_dims{r}];
    end
    
    % Find rows where any of these columns are non-zero
    active_rows = any(dm.X(:, cols_to_shuffle) ~= 0, 2);
    
    fprintf('Testing %s:...\n', group_name);
    
    corr_full_folds = zeros(n_folds, 1);
    corr_shifted_folds = zeros(n_folds, n_perms);
    
    for f = 1:n_folds
        test_idx = foldIDs == f;
        test_idx_active = test_idx & active_rows;  % Only active periods in this fold
        
        y_test = y(test_idx_active);
        X_test = dm.X(test_idx_active, :);
        
        % Predict on UNSHIFTED test data
        y_pred_full = glmnetPredict(CVinfo.glmnet_fit, X_test, best_lambda, 'response');
        
        % Smooth predictions and actual for correlation
        y_test_smooth = smoothdata(y_test, 'movmean', glm_ops.smoothPred);
        y_pred_full_smooth = smoothdata(y_pred_full, 'movmean', glm_ops.smoothPred);
        corr_full_folds(f) = corr(y_test_smooth, y_pred_full_smooth);
        
        % Test with circular shifts
        parfor p = 1:n_perms
            X_test_shifted = X_test;
            min_shift_bins = round(1 / glm_ops.tBin);  % 1 second minimum
            shift = randi([min_shift_bins, size(X_test, 1) - min_shift_bins]);
            X_test_shifted(:, cols_to_shuffle) = circshift(X_test(:, cols_to_shuffle), shift, 1);
            
            % Predict on SHIFTED test data
            y_pred_shifted = glmnetPredict(CVinfo.glmnet_fit, X_test_shifted, best_lambda, 'response');
            y_pred_shifted_smooth = smoothdata(y_pred_shifted, 'movmean', glm_ops.smoothPred);
            corr_shifted_folds(f, p) = corr(y_test_smooth, y_pred_shifted_smooth);
        end
    end
    
    % Average correlation across permutations
    mean_corr_shifted_per_fold = mean(corr_shifted_folds, 2);
    
    % Paired t-test: is full correlation greater than shifted?
    [~, p_value, ~, stats] = ttest(corr_full_folds, mean_corr_shifted_per_fold, 'Tail', 'right');
    
    % Store results
    lesion_results.(group_name).corr_full_mean = mean(corr_full_folds);
    lesion_results.(group_name).corr_shifted_mean = mean(mean_corr_shifted_per_fold);
    lesion_results.(group_name).delta_corr = mean(corr_full_folds - mean_corr_shifted_per_fold);
    lesion_results.(group_name).p = p_value;
    lesion_results.(group_name).t_stat = stats.tstat;
    lesion_results.(group_name).n_active = sum(full(active_rows));
    
    fprintf('\tcorr_full = %.4f, corr_shifted = %.4f, delta = %.4f, p = %.4f (n=%d)\n', ...
        lesion_results.(group_name).corr_full_mean, ...
        lesion_results.(group_name).corr_shifted_mean, ...
        lesion_results.(group_name).delta_corr, p_value, ...
        lesion_results.(group_name).n_active);
end
%%
f_kernels = glm.plot_glm_kernels(beta_full, regressors, regressor_dims, dspec, glm_ops, ...
                                 sprintf('%s %s, cid: %s', animal, session, cid));

%% save results and figure
save_folder = fullfile(paths.saveDir,'splitFS', animal, session);
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
end
if ~exist(fullfile(save_folder, 'kernel_plots'), 'dir')
    mkdir(fullfile(save_folder, 'kernel_plots'));
end



save(fullfile(save_folder, sprintf('cid%s.mat',cid)), ...
     'glm_ops', 'options', ...
     'beta_full', 'regressors', 'regressor_dims', ...
     'xval_corrs', 'CVinfo', ...
     'lesion_results', 'dspec')
 
saveas(f_kernels, fullfile(save_folder, 'kernel_plots', cid), 'png')

fprintf('\n ---GLM fit and successfully saved! ---\n')

close(f_kernels)
end


function dev = poisson_deviance(y, mu)
    % Poisson deviance
    mu = max(mu, 1e-10);
    dev = 2 * sum(y .* log((y + 1e-10) ./ mu) - (y - mu));
end