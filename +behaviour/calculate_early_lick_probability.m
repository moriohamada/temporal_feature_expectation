function [bin_mids, lick_p, count] = calculate_early_lick_probability(vals, t, licked, wins, ops)
% 
% Calculate probability of early licks following different 'vals' (e.g. tf pulse magnitude,
% or magnitude of projection onto some vector), at in different time windows specified in wins.
% 
% 
% bins - [1 x n_bins]
% lick_p - [n_bins x n_wins]
% --------------------------------------------------------------------------------------------------


bin_mids = linspace(prctile(vals,2.5), prctile(vals,97.5), 100);

bin_size = mean(diff(bin_mids))*5;
bin_starts = bin_mids-bin_size/2;
bin_ends   = bin_mids+bin_size/2;

bin_starts(1) = -inf;
bin_ends(end) = inf;

% find zero bin
[~, zero_bin_id] = min(abs(bin_mids));

lick_p = nan(length(bin_starts), size(wins,1));
count  = nan(length(bin_starts), size(wins,1));

range_bins = isbetween(bin_mids, prctile(vals,[40 60]));

for w = 1:size(wins, 1)
   
    win = wins(w,:);
   
    in_win = isbetween(t, win);
    
    
    for b = 1:length(bin_starts)
        
        in_bin = isbetween(vals, [bin_starts(b) bin_ends(b)]);
        
        if sum(in_bin & in_win) < ops.minPulses
            continue
        end
        count(b,w)  = sum(in_bin & in_win);
        lick_p(b,w) = sum(licked(in_bin & in_win))/sum(in_bin & in_win);
        
    end
    
    if ops.normLickP
        lick_p(:,w) = (lick_p(:,w) - min(lick_p(range_bins,w)));
    end
    
end

bin_mids = bin_mids / max(abs(vals)); 


end

