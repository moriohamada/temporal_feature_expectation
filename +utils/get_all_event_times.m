function events = get_all_event_times(trials, daq, ops)
% 'function' to hard code task events to visualize psths. 
% 
% each event is should be assigned as an index of 'events', with fields:
% - name:  string; readable name for event
% - times: [1 x n_events] vector of floats; all times that event occurs (aligned to spike times)
% - win: [start end], float; window around event for viewing psths in seconds (e.g., [-2 2])
% - classes: [1 x n_events] vector; with n_classes unique values, specifying different clsases for
%            this event, which will be plotted separately. e.g. [-1.75 -1 -.5 .5 1 1.75], for
%            different change frequencies in switch task. Can be left empty if no class distinctions
%            are desired
% - class_labels: {1 x n_classes}; labels for the classes, if any. corresponds to values returned by
%                 sort(unique(classes))
% 
% 
% --------------------------------------------------------------------------------------------------

ii =0;

[trials, daq] = utils.remove_excluded_trials(trials, daq);
%% baseline onset (short)

ii = ii + 1;

bl_durs = daq.Baseline_ON.fall_t - daq.Baseline_ON.rise_t;

events(ii).name    = 'baseline onset';
events(ii).times   = daq.Baseline_ON.rise_t(bl_durs > ops.rmvTimeAround);
events(ii).win     = [-2 2];

events(ii).classes = ones(1,length(events(ii).times));

%% baseline onset (long)

ii = ii + 1;

events(ii).name    = 'baseline';

events(ii).times   = daq.Baseline_ON.rise_t(bl_durs > 11);
events(ii).win     = [-2 15];

events(ii).classes = ones(1,length(events(ii).times));


%% change onsets

ii = ii + 1;

events(ii).name  = 'change onset';
events(ii).times = daq.Change_ON.rise_t;

events(ii).win     = [-1.5 1.5];


events(ii).classes = num2cell(nan(2,length(events(ii).times)));

for tr = 1:length(events(ii).times)
    if isnan(events(ii).times(tr)) % no change seen
        continue
    end
    if ~strcmp(trials(tr).trialOutcome, 'Hit') & ~strcmp(trials(tr).trialOutcome, 'Miss') % remove ref
        continue
    end
    exp = strcmp(trials(tr).trialType(end), 'E');
    hit = strcmp(trials(tr).trialOutcome, 'Hit');
    ctf = trials(tr).changeTF;
    
    % assign code
    if exp & hit
        code_type = 'exp_hit';
    elseif ~exp & hit
        code_type = 'uex_hit';
    elseif exp & ~hit
        code_type = 'exp_miss';
    elseif ~exp & ~hit
        code_type = 'uex_miss';
    else
        keyboard
    end
    events(ii).classes{1,tr} = code_type;
    events(ii).classes{2,tr} = ctf;
end

%% early licks
% keyboard
ii = ii + 1;

events(ii).name  = 'early lick';

rts = [trials.reactionTimes];
elt = [rts.FA];

events(ii).times = [];

for tr = 1:length(trials)
    if isnan(elt(tr))
        continue
    end
    
    if isfield(daq, 'mouthOpening') & ~isempty(daq.mouthOpening)
        events(ii).times(end+1) = daq.mouthOpening.lick_onset_by_tr(tr);
    else
        events(ii).times(end+1) = min([min(daq.Lick_L.rise_t(daq.Lick_L.rise_t > daq.Baseline_ON.rise_t(tr))), ...
                                       daq.Air_puff.rise_t(tr)]) - .25;
    end

end
events(ii).win   = [-2 .5];
elt(isnan(elt))  = [];

events(ii).classes = elt;


%% TF outliers

ii = ii + 1;
[amps_f, times_f, tr_times_f, licked_f]  =  ...
    utils.get_tf_outliers_time_amp(trials, daq, 2, 0.25, ops.tfOutlier,  1, ops.rmvTimeAround, [0 1.5]);
[amps_s, times_s, tr_times_s, licked_s]  = ...
    utils.get_tf_outliers_time_amp(trials, daq, 2, 0.25, ops.tfOutlier, -1, ops.rmvTimeAround, [0 1.5]);

% [all_times, order] = sort([times_f, times_s], 'ascend');
% amps = [amps_f, amps_s]; amps = amps(order);
% tr_times = [tr_times_f, tr_times_s]; tr_times = tr_times(order);
% licked = [licked_f, licked_s]; licked = licked(order);
all_times = [times_f, times_s];
tr_times = [tr_times_f, tr_times_s];
licked = [licked_f, licked_s];
amps = [amps_f, amps_s];

events(ii).name = 'TF outliers';
events(ii).times = all_times;
events(ii).win = [-1, 2];
events(ii).classes = [amps; tr_times; licked];

end

