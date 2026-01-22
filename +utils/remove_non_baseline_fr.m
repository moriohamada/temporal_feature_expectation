function [fr, t_ax] = remove_non_baseline_fr(fr, t_ax, daq, ops)

in_tr = zeros(size(t_ax));

for tr = 1:length(daq.Baseline_ON.rise_t)
    
    tr_start = daq.Baseline_ON.rise_t(tr) + ops.rmvTimeAround;
    tr_end = daq.Baseline_ON.fall_t(tr)-ops.rmvTimeAround;
    
    if tr_end < tr_start, continue; end
    in_tr = in_tr + isbetween(t_ax, [tr_start tr_end]);

end

fr(:, in_tr==0) = [];
t_ax(:, in_tr==0) = [];

end