function [Mdr, Ndr, coeffN, coeffM] = pca_dim_reduction(N, M, t_ax, ops)


lick_inds_to_use = [1 2 3 4 5 6];
t_starts_to_use  = (lick_inds_to_use-1) * length(t_ax) + 1;
t_ends_to_use    = lick_inds_to_use*300;
t_inds           = arrayfun(@(s, e) s:e, t_starts_to_use, t_ends_to_use, 'UniformOutput', false);
t_inds           = cell2mat(t_inds);

N = N(:, t_inds);
M = M(:, t_inds);

% subtract average activity between -2 and -1.5 s
nrep = size(N,2)/length(t_ax);
tax_repeated = repmat(t_ax, 1, nrep);
t_bl = tax_repeated > -1.99 & tax_repeated < -1.5;
N = (N - nanmean(N(:,t_bl),2));
M = (M - nanmean(M(:,t_bl),2)); 

t_rel = isbetween(tax_repeated, [-1 .5]);
[coeffN, scoreN, ~, ~, expN] = pca(N(:,t_rel)');
[coeffM, scoreM, ~, ~, expM] = pca(M(:,t_rel)'); 

fprintf('\n%.2f%s movement energy variance explained\n', sum(expM(1:ops.nDim_M)), '%')
fprintf('%.2f%s neural activity variance explained\n', sum(expN(1:ops.nDim_denoise)), '%')

Ndr = coeffN(:,1:ops.nDim_denoise)' * N;
Mdr = coeffM(:,1:ops.nDim_M)' * M;


end