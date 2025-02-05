function flip_time = calculate_flip_time(elts, elt, ops)
% 
% Take sliding windows for lick-triggered average, find optimal time for flipping.
%%
flip_time_candidates = 5:.25:9;

elt(elt < ops.ignoreTrStart) = nan;
diffs = zeros(length(flip_time_candidates), 11);

for fti = 1:length(flip_time_candidates)
   
    ft = flip_time_candidates(fti);
    
    early_idx = elt < ft-.25;
    late_idx  = elt > ft+.25;
    
    early_lta = nanmean(elts(early_idx, 25:35),1);
    late_lta  = nanmean(elts(late_idx, 25:35), 1);
    diff = abs(smoothdata(early_lta - late_lta, 'movmean', 3));

    diffs(fti,:) = diff;
    
end
diffs = smoothdata(diffs, 'movmean', 3);
abs_diff_sum = sum(abs(diffs), 2);
[~, max_diff_id] = max(abs_diff_sum);

flip_time = flip_time_candidates(max_diff_id);
end