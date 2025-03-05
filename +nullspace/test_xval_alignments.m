function alignments = test_xval_alignments(projs_iters, dims_iters, ops)
% 
% Use cross-validation data to test alignments between extracted dimensions and responses:
% 
% 1) get alignments between dimensions
% 2) get TF response magnitudes along dimensions

nIter = length(projs_iters);
dims  = fields(dims_iters{1});
nDim  = numel(dims);

%%
% dim_corrs = nan(nDim, nDim, nIter);
dim_cos = nan(nDim, nDim, nIter);
dim_cos_control = nan(nDim, nDim, nIter);
for d1 = 1:nDim
    dim1 = dims{d1};
    for d2 = d1+1:nDim
        dim2 = dims{d2};
        for iter = 1:nIter
            % dim_corrs(d1, d2, iter) = corr(dims_iters{iter}.(dim1), dims_iters{iter}.(dim2));
            dim_cos(d1, d2, iter)   = cosineSim(dims_iters{iter}.(dim1), dims_iters{iter}.(dim2));
            cntrl = dims_iters{iter}.(dim2);
            cntrl = cntrl(randperm(length(cntrl)));
%             cntrl = rand(size(dims_iters{iter}.(dim2)));
%             cntrl = cntrl/norm(cntrl,2);
            dim_cos_control(d1, d2, iter)   = cosineSim(dims_iters{iter}.(dim1), cntrl);
        end
    end
end
alignments.dims = dim_cos;
alignments.dims_control = dim_cos_control;
%% project F/S/N onto movement space
tf_dims_proj = nan(3, 3, nIter);
tf_axs = {'tf_fast', 'tf_slow', 'tf_none'};
for iter = 1:nIter
    movespace = [dims_iters{iter}.movement_potent, ...
                 dims_iters{iter}.movement_null1, ...
                 dims_iters{iter}.movement_null2];
    for tf_pref_i = 1:3
        tf_ax = tf_axs{tf_pref_i};
        
        tf_dims_proj(:,tf_pref_i,iter) = movespace' * dims_iters{iter}.(tf_ax);
        
        tf_dims_proj(:,tf_pref_i,iter) = tf_dims_proj(:,tf_pref_i,iter)/norm(tf_dims_proj(:,tf_pref_i,iter));
    end
end
alignments.tf_dims_projected = tf_dims_proj;

% control
tf_dims_proj_control = nan(3, 3, nIter);
tf_axs = {'tf_fast', 'tf_slow', 'tf_none'};
for iter = 1:nIter
    movespace = [dims_iters{iter}.movement_potent, ...
                 dims_iters{iter}.movement_null1, ...
                 dims_iters{iter}.movement_null2];
    for tf_pref_i = 1:3
        tf_ax = tf_axs{tf_pref_i};
        tf_control = dims_iters{iter}.(tf_ax);
        tf_control = tf_control(randperm(length(tf_control)));
        tf_dims_proj_control(:,tf_pref_i,iter) = movespace' * tf_control;
        tf_dims_proj_control(:,tf_pref_i,iter) = tf_dims_proj_control(:,tf_pref_i,iter)/norm(tf_dims_proj_control(:,tf_pref_i,iter));
    end
end
alignments.tf_dims_projected_control = tf_dims_proj_control;

%% Projection alignments - how do TF pulses move activity along movement potent and null 1


tf_resp_names = {'FexpF', 'SexpF', 'FexpS', 'SexpS'};
tf_cols = [ops.colors.F; ops.colors.F*.6; ops.colors.S*.6; ops.colors.S];
move_dims = {'movement_potent', 'movement_null1', 'movement_null2'};

tf_resps = nan(length(move_dims), 4, nIter); % dim x exp x iter
tf_resps_control = nan(length(move_dims), 4, nIter); % dim x exp x iter

tf_tax = linspace(-.49, 1.5, 200);
resp_inds = isbetween(tf_tax, [.1 .5]);
bl_inds   = isbetween(tf_tax, [-.5 -.1]);

for d = 1:length(move_dims)
    dim = move_dims{d};
    for iter = 1:nIter
        for tfi = 1:length(tf_resp_names)
            tf_resp_name = tf_resp_names{tfi};
            tf_resps(d, tfi, iter) = mean(projs_iters{iter}.(dim).(tf_resp_name)(resp_inds)) - ...
                                     mean(projs_iters{iter}.(dim).(tf_resp_name)(bl_inds));
                                  
            tf_resps_control(d, tfi, iter) = mean(projs_iters{iter}.(sprintf('%s_shuffled',dim)).(tf_resp_name)(resp_inds)) - ...
                                             mean(projs_iters{iter}.(sprintf('%s_shuffled',dim)).(tf_resp_name)(bl_inds));
        end
    end
end

tf_resp_indexes = cat(2, tf_resps(:,1,:) - tf_resps(:,2,:), ...
                         (tf_resps(:,3,:) - tf_resps(:,4,:))); 
alignments.tfIndexes = tf_resp_indexes;

tf_resp_indexes_control = cat(2, tf_resps_control(:,1,:) - tf_resps_control(:,2,:), ...
                         (tf_resps_control(:,3,:) - tf_resps_control(:,4,:))); 
alignments.tfIndexes_control = tf_resp_indexes_control;
end




















