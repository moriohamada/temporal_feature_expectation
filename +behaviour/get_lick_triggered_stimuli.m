function [elts, elt] = get_lick_triggered_stimuli(trials, ops)
% 
% for every false alarm, return stimuli preceding it (and time of lick)
% 
% --------------------------------------------------------------------------------------------------

%%

trials = trials(logical([trials.keepTrial]) & logical([trials.deviantsOn]));

t_hist=ops.tHistory+.5; % padding for smoothing

elts = nan(0, t_hist*20);
elt  = nan(0, 1);

for tr = 1:length(trials)
   
    if ~strcmp(trials(tr).trialOutcome, 'FA')
        continue
    end
    
    tf = log2(trials(tr).baselineStimVec(1:3:end)/2);
    
    lick_t  = trials(tr).reactionTimes.FA;
    if isnan(lick_t)
        continue
    end
    lick_fr = round(lick_t * 20);
    
    if lick_fr < 1
        continue
    end
    
    pre_fa_tf = tf(max([1, lick_fr-t_hist*20+1]):lick_fr);
    
    if length(pre_fa_tf) < t_hist*20
        missing = round(t_hist*20) - length(pre_fa_tf);
        pre_fa_tf = [nan(missing,1); pre_fa_tf];
    end
    elts(end+1, :) = pre_fa_tf';
    elt(end+1, :)  = lick_t;    
    
end


end