function [fr, t_ax] = remove_out_of_trial_fr(fr, t_ax, daq)

in_tr = zeros(size(t_ax));

for tr = 1:length(daq.Baseline_ON.rise_t)
    
    tr_start = daq.Baseline_ON.rise_t(tr)-2;
    tr_end   = nanmax([daq.Baseline_ON.fall_t(tr)+2, daq.Change_ON.fall_t(tr)]);
    
    in_tr = in_tr + isbetween(t_ax, [tr_start tr_end]);

end

fr(:, in_tr==0) = [];
t_ax(:, in_tr==0) = [];

end