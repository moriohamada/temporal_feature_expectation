function [p_lick_single, p_lick_double, binMids] = calculate_multi_pulse_lick_probability(tfs, t, licked, wins, ops)
% 
% p_lick_single: [n_win x n_tfBins]
% p_lick_double: [n_win x n_delays x n_tfBins x n_tfBins]
%
% --------------------------------------------------------------------------------------------------


binStarts = ops.tfBinStarts;
binEnds   = binStarts + ops.tfBinSize;

binMids = mean([binStarts; binEnds],1);

[~,zero_id] = min(abs(binMids));

n_win = size(wins, 1);
n_delays = length(ops.delays);

p_lick_single = nan(n_win, length(binMids));
p_lick_double = nan(n_win, n_delays, length(binMids), length(binMids));

for w = 1:n_win
    
    win = wins(w,:);
    
    in_win = isbetween(t, win);
    
    % get single pulse lick p
    for b = 1:length(binStarts)
        bin_start = binStarts(b);
        bin_end   = binEnds(b);
        
        in_bin = isbetween(tfs, [bin_start, bin_end]);
        if sum(in_win & in_bin) < ops.minPulses
            continue
        end
        p_lick_single(w, b) = sum(licked(in_win & in_bin))/sum(in_win & in_bin);
         
    end
    
    % get double pulse lick p
    
    for b1 = 1:length(binStarts)
        for b2 = 1:length(binStarts)
            bin_start1 = binStarts(b1);
            bin_end1   = binEnds(b1);
            bin_start2 = binStarts(b2);
            bin_end2   = binEnds(b2);
            
            for d = 1:n_delays
                delay = ops.delays(d);
                
                in_bin = isbetween(tfs, [bin_start1, bin_end1]);
                prev_in_bin = isbetween(circshift(tfs, delay), [bin_start2, bin_end2]);
                  
                in_bin(1:delay) = 0;
                prev_in_bin(1:delay) = 0;
                
                if sum(in_win & in_bin & prev_in_bin) < ops.minMultiPulses
                    continue
                end
                p_lick_double(w, d, b1, b2) = sum(licked(in_win & in_bin & prev_in_bin)) / ...
                                              sum(in_win & in_bin & prev_in_bin);
 
                                          
            end
        end
        
        
    end


end

end



