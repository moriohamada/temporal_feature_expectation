function [tfs, stim_tr, stim_time, next_lick] = get_all_tf_pulses(trials, ops)

tfs        = nan(1e6,1);
stim_tr    = nan(1e6,1);
stim_time  = nan(1e6,1);
next_lick  = nan(1e6,1);

n_pulse = 1;
for tr = 1:length(trials)
    
    bl_tf = log2(trials(tr).baselineStimVec(1:3:end)/2);
    
    switch trials(tr).trialOutcome
        
        case {'Hit', 'Miss', 'Ref'}
            tr_dur  = trials(tr).stimT;
            el_time = nan;
        case 'FA'
            tr_dur  = trials(tr).reactionTimes.FA;
            el_time = trials(tr).reactionTimes.FA;
        case 'abort'
            tr_dur  = trials(tr).reactionTimes.abort;
            el_time = nan; 
            continue
    end
    
    if tr_dur < ops.ignoreTrStart
        continue
    end
    
    bl_tf = bl_tf(1:ceil(tr_dur*20));
    bl_t  = 0:.05:(length(bl_tf)-1)*.05;
    
    t_to_lick = el_time - bl_t;
    
    tfs(n_pulse:n_pulse+length(bl_tf)-1) = bl_tf;
    stim_tr(n_pulse:n_pulse+length(bl_tf)-1) = tr;
    stim_time(n_pulse:n_pulse+length(bl_tf)-1) = bl_t;
    next_lick(n_pulse:n_pulse+length(bl_tf)-1) = t_to_lick;
    
    n_pulse = n_pulse + length(bl_tf);
   
end

% next lick to binary 
next_lick(~isbetween(next_lick, ops.lickRTWin)) = 0;
next_lick( isbetween(next_lick, ops.lickRTWin)) = 1;

% remove any nans
tfs(n_pulse:end)       = [];
stim_tr(n_pulse:end)   = [];
stim_time(n_pulse:end) = [];
next_lick(n_pulse:end) = [];


end


