function [W_toPot, W_toNull, N_pot, N_null] = calculate_movement_dims_LD(Ndr, Mdr, coeffN, coeffM, t_ax, ops)
% Identify potent and null dims
% subtract average activity between -2 and -1.5 s
nrep = size(Ndr,2)/length(t_ax);
tax_repeated = repmat(t_ax, 1, nrep);
t_bl = tax_repeated > -1.99 & tax_repeated < -1.5;

% Ndr = Ndr - nanmean(Ndr(:,t_bl),2);
% Mdr = Mdr - nanmean(Mdr(:,t_bl),2);


% % select only lick time
t_lick = isbetween(tax_repeated, [-.5 .5]);
% t_lick = isbetween(t_ax, [-.5 .5]);


% Calculate the pseudo-inverse of N and compute W 
Ndr_shift = circshift(Ndr, -3, 2);
N_pinv = pinv(Ndr_shift(:,t_lick));
W = Mdr(:,t_lick) * N_pinv; 
W_null = null(W)';


% First find dim that separates F and S
% keyboard
t_tf = t_ax > -.5 & t_ax <= .25;
N_null = W_null * Ndr;
N_null_by_ch = permute(reshape(N_null, size(N_null,1),  length(t_ax), nrep), [1 3 2]);
% get respon period
N_null_by_ch = mean(N_null_by_ch(:,:,t_tf),3);
N_null_by_ch = log(abs(N_null_by_ch)) .* sign(N_null_by_ch);
W_tf = mean(N_null_by_ch(:, 1:nrep/2),2) - mean(N_null_by_ch(:, [1:nrep/2]+nrep/2),2);
W_tf = W_tf'/norm(W_tf);

% get pc
t_pre = tax_repeated > -.5 & tax_repeated <= 0;
[coeffNull, scoreNull, ~, ~, expNull] = pca(N_null(:,t_pre)');
W_null = [W_tf; coeffNull(:,1:(ops.nDim_N-1))'] * W_null;
[q, ~] = qr(W_null');
W_null = flipud(q(:,1:2)');

% get full mappings from single units to movement potent and null space
W_toPot  = W * coeffN(:,1:ops.nDim_denoise)';
W_toNull = W_null * coeffN(:,1:ops.nDim_denoise)';
N_pot    = W * Ndr;  
N_null   = W_null * Ndr;