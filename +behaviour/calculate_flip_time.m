function flip_time = calculate_flip_time(elts, elt, ops)
% 
% Take sliding windows for lick-triggered average, find optimal time for flipping.
%%
flip_time_candidates = 4:.1:10;

elt(elt < ops.ignoreTrStart) = nan;
diffs = zeros(length(flip_time_candidates), 12);


for fti = 1:length(flip_time_candidates)
   
    ft = flip_time_candidates(fti);
    
    early_idx = elt < ft-.5;
    late_idx  = elt > ft+.5;
    
%     early_lta = nanmean(elts(early_idx, 11:30),1);
%     late_lta  = nanmean(elts(late_idx, 11:30), 1);
    
    early_lta = smoothdata(nanmean(elts(early_idx, 25:36),1),2,'movmean',5);
    late_lta  = smoothdata(nanmean(elts(late_idx, 25:36), 1),2,'movmean',5);
    diff = abs(smoothdata(early_lta - late_lta, 'movmean', 3));
%     diff(diff<prctile(diff,50)) = 0;
    diffs(fti,:) = diff;
    
end
diffs = smoothdata(diffs, 2, 'movmean', 2);
abs_diff_sum = smoothdata(sum(abs(diffs), 2), 1, 'movmedian', 5);
[~, max_diff_id] = max(abs_diff_sum);

flip_time = flip_time_candidates(max_diff_id);
flip_time(flip_time<4)=4;
% keyboard
%
% 
% figure; plot(diffs(max_diff_id,:))
% 
% ft = flip_time
% early_idx = elt < ft;
% late_idx  = elt > ft;
% 
% early_lta = nanmean(elts(early_idx, 11:30),1);
% late_lta  = nanmean(elts(late_idx, 11:30), 1);
% 
% diff = abs(smoothdata(early_lta - late_lta, 'movmedian', 5));
% diff(diff<prctile(diff,50)) = 0;
% diffs(fti,:) = diff;
% 
% figure; subplot(2,1,1); plot(early_lta, 'r'); hold on; plot(late_lta, 'b'); subplot(2,1,2); plot(diff,'k')

end