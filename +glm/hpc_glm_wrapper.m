function fit_rwr_hpc(nCat)
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
paths.dataDir = '/mnt/ceph/public/projects/MoHa_20240218_SwitchChangeDetect_spForRWR/';
paths.saveDir = '/mnt/ceph/public/projects/MoHa_20240218_SwitchChangeDetect_spForRWR/';
else
paths.dataDir = '/ceph/mrsic_flogel/public/projects/MoHa_20240218_SwitchChangeDetect_spForRWR/';
paths.saveDir = '/ceph/mrsic_flogel/public/projects/MoHa_20240218_SwitchChangeDetect_spForRWR/';
end
% 13555

%%

ns = nCat*10 + [1:10];
%12910
for n = ns
    fprintf('\n\nn=%d\n',n);

    try
        clearvars -except ns n nCat paths name
        
        %% Load in data
        
        spFiles = dir2(fullfile(paths.dataDir,'spikeTimes'));
        spFile  = spFiles{n};
        % clear spFiles
        
        % load spike times
        st = loadVariable(fullfile(paths.dataDir, 'spikeTimes', spFile), 'st');
        if length(st)/range(st) < .5
            fprintf('\nFR too low for GLM fitting - skipping unit!')
            continue
        end
        % load DM
        animal  = spFile(1:6);
        session = spFile(8:9);
        cid     = spFile(11:15);
        fprintf('Fitting glm for %s %s %s\n', animal, session, cid);
        
        % save_folder = fullfile(paths.saveDir,'rwr50ms', animal, session);
%         if exist(fullfile(save_folder, sprintf('cid%s.mat',cid)),'file')
%             fprintf('RWR already fit!\n')
%             continue
%         end
        
        [features, trStarts, ops] = loadVariables(fullfile(paths.dataDir, 'featuresFull50ms', sprintf('%s_%s.mat', animal, session)), ...
            'features', 'trStarts','ops');
        
        
        %% Further ops for fitting
        ops.nlambdas   = 10;
        ops.kFold      = 10;
        ops.maxIter    = 1000;
        ops.tol        = .01;
        ops.nlambdas   = 100;
        ops.smoothPred = 5;
        
        ops.includePhase = 0;
        ops.includeRunSpeed = 0;
        ops.splitFStf = 0;
        
        ops.nIter = 100;
        
        %% Create DM and y vector
        params.animal  = animal;
        params.session = session;
        params.cid     = cid;
        
        features_n = add_st_to_glm_features_v2(features, trStarts, st, ops);
        
        % remove trials with <1 few spike
        no_spx = cellfun(@isempty, {features_n.SpTrain});
        features_n(no_spx) = [];
        
        if length(features_n)<100
            continue
        end
        
        [expt, dspec] = get_expt_dspec_for_glm(features_n, params, ops);
        
%         % add non-linear (log-transformed) change tf
%         logTransform = @(x) nansum([(x==0)*0, (x~=0) .* (sign(x) .* sqrt(abs(x)))],2);
%         logTFch = arrayfun(@(s) logTransform(s.TFch), features_n, 'UniformOutput', false);
%         [features_n.logTFch] = logTFch{:};
%         
%         [expt, dspec] = get_expt_dspec_for_glm_nonlinear_tf(features_n, params, ops);
        %%
        fprintf('Building design matrix...\t')
        
        [dm, trialIDs] = buildGLM.compileSparseDesignMatrixWithTrialInd(dspec, 1:length(features_n));
        dm = buildGLM.addBiasColumn(dm);
        y = buildGLM.getBinnedSpikeTrain(expt, 'SpTrain', dm.trialIndices);
        fprintf('done.\n')
        
        %%
        fprintf('Fitting models on subsampled trials...\n')
        
        all_prep_mdls = cell(ops.nIter,1);
        all_mot_mdls  = cell(ops.nIter,1);
        rmses = nan(ops.nIter,2);
        tic
        warning('off', 'stats:LinearModel:RankDefDesignMat');
        
        for iter = 1:ops.nIter
            if mod(iter,10)==0
            fprintf('\tIteration %d/%d\n', iter, ops.nIter)
            end
            warning('off', 'stats:LinearModel:RankDefDesignMat');
            
            % get IDs of rows in training trials
            xval_inds = crossvalind('HoldOut',length(features_n), .5);
            
            train_tr = zeros(size(trialIDs));
            trialNums = 1:length(features_n);
            for tr = trialNums
                this_tr_fold = xval_inds(tr);
                this_tr_rows = trialIDs == tr;
                train_tr(this_tr_rows) = this_tr_fold;
            end
            train_tr = logical(train_tr);
            %% Create predictor matrices
            
            %change_on = sum(dm.X(:, end-20:end-1),2)~=0;
            % X = dm.X(change_on & train_tr ,:);
            % % spx = full(y(change_on));
            % spx =  smoothdata(full(y(change_on & train_tr)), 'gaussian', 5*(.05/ops.tBin));

            % using full trial
            X = dm.X(train_tr,:);
            spx = smoothdata(full(y(train_tr)), 'gaussian', 5*(.05/ops.tBin));
            
            covars  = {'offset', dspec.covar.label};
            edims   = horzcat(1, [dspec.covar.edim]);
            cumdims = cumsum(edims);
            
            % get indexes corresponding to each regressor
            bl_pos  = find(strcmp(covars, 'baseline'));
            bl_inds = cumdims(bl_pos-1)+1:cumdims(bl_pos);
            X_bl    = full(X(:, bl_inds));
            
            mot_pos  = find(strcmp(covars, 'motionEnergy'));
            mot_inds = cumdims(mot_pos-1)+1:cumdims(mot_pos);
            X_mot    = full(X(:,mot_inds));

            tf_pos  = find(strcmp(covars, 'TFbl'));
            tf_inds  = cumdims(tf_pos-1)+1:cumdims(tf_pos);
            X_tf     = full(X(:,tf_inds));

            ch_pos   = find(strcmp(covars, 'TFch'));
            ch_inds  = cumdims(ch_pos-1)+1:cumdims(ch_pos);
            X_ch     = full(X(:,ch_inds));
            
            prepE_pos  = find(strcmp(covars, 'PreLick_e'));
            prepE_inds = cumdims(prepE_pos-1)+1:cumdims(prepE_pos);
            X_prepE    = full(X(:, prepE_inds));
            prepL_pos  = find(strcmp(covars, 'PreLick_l'));
            prepL_inds = cumdims(prepL_pos-1)+1:cumdims(prepL_pos);
            X_prepL    = full(X(:, prepL_inds));
            
            %% fit model with just motion energy, time 
            X_comb = [X_bl, X_mot];
            %     X_comb(:,~any(X_comb,1)) = [];
            mdl_mot = fitglm(X_comb, spx, 'Distribution', 'normal', 'Intercept', true);

            %% find residuals
            
            y_hat_mot  = predict(mdl_mot, X_comb);
            resid      = spx - y_hat_mot;
            
            %% add tf
            mdl_tf = fitglm([X_tf, X_ch, X_nl], resid, 'Distribution','normal','Intercept',true);
            
            % predict on test set
            test_tr = ~train_tr;
            X_test = dm.X(test_tr ,:);
            y_test = smoothdata(full(y(test_tr)), 'gaussian', 5*(.05/ops.tBin));

            X_bl_test    = full(X_test(:, bl_inds));
            X_mot_test   = full(X_test(:,mot_inds));
            X_ch_test    = full(X_test(:,ch_inds));
            X_tf_test    = full(X_test(:,tf_inds));

            y_hat_motor = predict(mdl_mot, [X_bl_test, X_mot_test]);
            y_hat_tf  =  y_hat_motor + predict(mdl_tf, [X_tf_test, X_ch_test]);
            
            rmse_motor = sqrt(mean((y_test - y_hat_motor).^2));
            rmse_tf    = sqrt(mean((y_test - y_hat_tf).^2));

            %% refit with all variables, get residua, add motor prep
            X_comb = [X_bl, X_mot, X_tf, X_ch];

            mdl_comb = fitglm(X_comb, spx, 'Distribution', 'normal', 'Intercept', true);

            % find residuals
            y_hat_mot  = predict(mdl_comb, X_comb);
            resid      = spx - y_hat_mot;

            
            mdl_prep   = fitglm([X_prepE, X_prepL], resid, 'Distribution', 'normal', 'Intercept', true);
        

            %% Predict on test set with full model vs pre-lick
            test_tr = ~train_tr;
            X_test = dm.X(test_tr ,:);
            y_test = smoothdata(full(y(test_tr)), 'gaussian', 5*(.05/ops.tBin));

            X_bl    = full(X_test(:, bl_inds));
            X_mot   = full(X_test(:,mot_inds));
            X_tf    = full(X_test(:,tf_inds));
            X_ch    = full(X_test(:,ch_inds));
            X_prepE = full(X_test(:, prepE_inds));
            X_prepL = full(X_test(:, prepL_inds));
            
            
            y_hat_comb = predict(mdl_comb, [X_bl, X_mot, X_tf, X_ch]);
            y_hat_prep  =  y_hat_comb + predict(mdl_prep, [X_prepE X_prepL]);
            
            rmse_comb = sqrt(mean((y_test - y_hat_comb).^2));
            rmse_prep  = sqrt(mean((y_test - y_hat_prep).^2));
            
            %% store models and predictions
            all_mot_mdls{iter} = mdl_comb;
            all_prep_mdls{iter} = mdl_prep;
            rmses(iter,1) = rmse_motor;
            rmses(iter,2) = rmse_tf;
            rmses(iter,3) = rmse_comb;
            rmses(iter,4) = rmse_prep;
            
        end
        fprintf('done.\n')
        
        toc
        
        %%
        f=figure; hold on;
        nT = 1000/(ops.tBin*1000)';
        prelick_kernels = nan(ops.nIter, 2, nT);
        tf_kernels  = nan(ops.nIter, 20);
        ch_kernels = nan(ops.nIter, 20);
        ch_kern_nl = nan(ops.nIter, 20);
        for iter = 1:ops.nIter
            tf_kern   = all_mot_mdls{iter}.Coefficients.Estimate(end-39:end-20);
            ch_kern   = all_mot_mdls{iter}.Coefficients.Estimate(end-19:end);
            prelick_E = all_prep_mdls{iter}.Coefficients.Estimate(2:nT+1);
            prelick_L = all_prep_mdls{iter}.Coefficients.Estimate(nT+2:nT*2+1);
            plot(prelick_E, 'color', ops.colors.E);
            plot(prelick_L, 'color', ops.colors.L);
            prelick_kernels(iter, 1, :) = prelick_E;
            prelick_kernels(iter, 2, :) = prelick_L;
            tf_kernels(iter, :) = tf_kern;
            ch_kernels(iter, :) = ch_kern;
        end
        
        %% Get significance
        
            
        %% save
        
        save_folder = fullfile(paths.saveDir,'rwr50ms_v7nonLin', animal, session);
        if ~exist(save_folder, 'dir')
            mkdir(save_folder);
        end
        
        if ~exist(fullfile(save_folder, 'kernel_plots'), 'dir')
            mkdir(fullfile(save_folder, 'kernel_plots'));
        end
        
        
        save(fullfile(save_folder, sprintf('cid%s.mat',cid)), ...
            'ops',  'prelick_kernels', 'rmses', 'tf_kernels', 'ch_kernels', '-v7.3')
        
        saveas(f, fullfile(save_folder, 'kernel_plots', cid), 'png')
        
        fprintf('\nRWR successfully fit!\n')
        
        
    end
    
end


if ~strcmp(name, 'earth')
    close all
    exit
end

end







