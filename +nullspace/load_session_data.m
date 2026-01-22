function [N, M, licks, mu, sd] = load_session_data(trials, daq, sp, resps, sess_units, t_ax, ...
                                                   lick_data_path, ops)
                                                      
                                                      
[M, licks] = loadVariables(lick_data_path, 'M', 'licks');
% normalize M
M_sd = std(reshape(M, size(M,1), []), [], 2);
M = M ./ M_sd;

% get activity around licks
inc_cids = resps{sess_units, 'cid'};
inc_spx = ismember(sp.clu, inc_cids);
sp.clu = sp.clu(inc_spx);
sp.st = sp.st(inc_spx);
sp.cids = inc_cids;
[fr, tax_fr] = utils.spike_times_to_fr(sp, 10);
[fr_tmp,~] = utils.remove_out_of_trial_fr(fr, tax_fr, daq);
fr_tmp = smoothdata(fr_tmp, 2, 'movmean', [5 0]);
mu = nanmean(fr_tmp,2);
sd = nanstd(fr_tmp,[],2); sd(sd==0|isnan(sd)|sd==inf)=inf; 
clear fr_tmp;
fr = (fr - mu)./sd;
fr = smoothdata(fr, 2, 'movmean', 3);

[tax_N, N] = utils.get_response_to_event_from_FR_matrix(fr, tax_fr, licks.times', [t_ax(1)-.02 t_ax(end)+.02]);

% resample to t_ax
N = interp1(tax_N, permute(N, [3 1 2]), t_ax);
N = permute(N, [2 3 1]);

end