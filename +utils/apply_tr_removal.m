function trials_all = apply_tr_removal(trials_all, ops)
%%
trials_to_keep = ones(1, length(trials_all));

% remove starts
trials_to_keep([trials_all.trsSinceSessStart] <= 10) = 0;

% calculating running performance for eahc session
[hitRate, missRate, faRate, abortRate] = calculate_running_performance(trials_all, ops.performanceBin);

% remove periods where miss rate too high
trials_to_keep(missRate > ops.missThresh) = 0;

% remove periods where fa rate too high
trials_to_keep(faRate > ops.falseAlarmThresh) = 0;

% remove periods where abort rate too high
trials_to_keep(abortRate > ops.abortThresh) = 0;

% remove periods where combined fa and abort rate (i.e. early termination) rate too hihg
trials_to_keep(abortRate + faRate > ops.combinedAbortFA) = 0;


% label periods where deviant stimuli could have been presented
deviants_on = ones(1, length(trials_all));
deviants_on([trials_all.trSinceFSMStart] < 10) = 0;
deviants_on(~strcmp({trials_all.antiBias}, 'none')) = 0;

%%
trials_to_keep = num2cell(trials_to_keep);
[trials_all(:).keepTrial] = deal(trials_to_keep{:});

deviants_on = num2cell(deviants_on);
[trials_all(:).deviantsOn] = deal(deviants_on{:});

end

function [hitRate, missRate, faRate, abortRate] = calculate_running_performance(trials_all, bin)

hit_trs   = strcmp({trials_all.trialOutcome}, 'Hit');
miss_trs  = strcmp({trials_all.trialOutcome}, 'Miss');
fa_trs    = strcmp({trials_all.trialOutcome}, 'FA');
abort_trs = strcmp({trials_all.trialOutcome}, 'abort');
change_tr = ~strcmp({trials_all.trialType}, 'zero');

n_tr = length(trials_all);

hitRate   = nan(1, n_tr);
missRate  = nan(1, n_tr);
faRate    = nan(1, n_tr);
abortRate = nan(1, n_tr);

for tr = 1:n_tr
    
    win = ceil(max([tr-bin/2, 1])):floor(min([tr+bin/2, n_tr]));
    
    hitRate(tr)  = sum(hit_trs(win) & change_tr(win)) / ...
                   sum((hit_trs(win) | miss_trs(win)) & change_tr(win));
    missRate(tr) = sum(miss_trs(win) & change_tr(win)) / ...
                   sum((hit_trs(win) | miss_trs(win)) & change_tr(win));
              
    faRate(tr)    = sum(fa_trs(win))/numel(win);
    abortRate(tr) = sum(abort_trs(win))/numel(win);
    
end

end