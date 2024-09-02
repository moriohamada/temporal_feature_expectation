function [W_toPot, W_toNull, N_pot, N_null] = calculate_movement_dims(Ndr, Mdr, coeffN, coeffM, t_ax, ops)
% Identify potent and null dims
% subtract average activity between -2 and -1.5 s
nrep = size(Ndr,2)/length(t_ax);
tax_repeated = repmat(t_ax, 1, nrep);
t_bl = tax_repeated > -1.99 & tax_repeated < -1.5;
Ndr = Ndr - nanmean(Ndr(:,t_bl),2);
Mdr = Mdr - nanmean(Mdr(:,t_bl),2);

% % select only lick time

t_lick = isbetween(tax_repeated, [-.5 .5]);

% opt 1 - lsr
% Calculate the pseudo-inverse of N
Ndr_shift = circshift(Ndr, 0, 2);
N_pinv = pinv(Ndr_shift(:,t_lick));
% N_pinv = pinv(Ndr(:,t_lick));
% 
% % Compute W using the pseudo-inverse of N
W = Mdr(:,t_lick) * N_pinv

%% opt 2 - lasso

% [W, fitinfo] = lasso(Ndr(:, t_lick)', Mdr(:,t_lick), 'alpha', .5, 'lambda', .1);
% W = W'
% keybard
%%
W_null = null(W)';

% rotate Wnull to explain pre-lick variance
t_pre = tax_repeated > -1 & tax_repeated <= 0;
% t_pre(1800:end)=0; % dont include false alarms
N_null = W_null * Ndr;

[coeffNull, scoreNull, ~, ~, expNull] = pca(N_null(:,t_pre)');
% coeffNull = eye(size(coeffNull));
% [coeffNull, scoresNull, sparsity, expNull] = spca(N_null(:,t_pre)', ops.nDim_N, .1);

W_null = coeffNull(:,1:ops.nDim_N)' * W_null;
N_null = W_null * Ndr;
if nansum(N_null(1,:))<0, W_null(1,:) = -1 * W_null(1,:); end
fprintf('%.2f%s null space variance captured\n', sum(expNull(1:ops.nDim_N)), '%')

% get full mappings from single units to movement potent and null space
W_toPot  = W * coeffN(:,1:ops.nDim_denoise)';
W_toNull = W_null * coeffN(:,1:ops.nDim_denoise)';
N_pot    = W * Ndr;  
N_null   = W_null * Ndr;