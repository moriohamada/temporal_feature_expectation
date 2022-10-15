function [t, tr_t, info] = get_times_of_events(trials, daq, ops, ev)
% 
% Return times (absolute and in trial) of particular events, as well as events 
% 
% --------------------------------------------------------------------------------------------------


switch lower(ev)
    
    case {'bl', 'blon', 'baseline onset'}
        % info returned: tr outcome
        t = [];
        tr_t = [];
        info = {};

        for tr = 1:length(trials)
            
            bl_on  = daq.frame_times_tr_corrected.time{tr}(1);
%             bl_on  = daq.Baseline_ON.rise_t(tr);
            bl_off = daq.Baseline_ON.fall_t(tr);
            
            if bl_off - bl_on < ops.minTrialDur
                continue
            end
            
            t(end+1)    = bl_on;
            tr_t(end+1) = 0;
            info{end+1} = trials(tr).trialOutcome;  
            
        end
            
    case {'tf', 'tf outlier'}
        % info returned: tf value, licked
        [tfF, timesF, tr_timesF, lickedF] = ...
            get_tf_outliers_time_amp(trials, daq, 2, .25, ops.tfOutlier, 1, ops.rmvTimeAround, [0 ops.rmvTimeAround]);
        
        [tfS, timesS, tr_timesS, lickedS] = ...
            get_tf_outliers_time_amp(trials, daq, 2, .25, ops.tfOutlier, -1, ops.rmvTimeAround, [0 ops.rmvTimeAround]);

        tf = [tfF, tfS];
        licked = [lickedF, lickedS];
        info = [tf', licked'];
        t    = [timesF, timesS];
        tr_t = [tr_timesF, tr_timesS];
        
    case 'fa'
        % info returned: tr
        t = [];
        tr_t = [];
        info = [];
        for tr = 1:length(trials)
            bl_on  = daq.Baseline_ON.rise_t(tr);
            bl_off = daq.Baseline_ON.fall_t(tr);
            
            if bl_off - bl_on < ops.minTrialDur
                continue
            end
            if ~strcmp(trials(tr).trialOutcome, 'FA')
                continue
            end
            if isfield(daq, 'mouthOpening')
                if daq.mouthOpening.delta_time_by_tr(tr) < .7
                    fa_time = daq.mouthOpening.lick_onset_by_tr(tr);
                else
                    fa_time = min([min(daq.Lick_L.rise_t(daq.Lick_L.rise_t > bl_on)), trials(tr).reactionTimes.FA+bl_on]) ...
                              - nanmean(daq.mouthOpening.delta_time_by_tr);
                end
            else                    
                fa_time = min([min(daq.Lick_L.rise_t(daq.Lick_L.rise_t > bl_on)), trials(tr).reactionTimes.FA+bl_on]) ...
                              - .3;
            end
            t(end+1) = fa_time;
            tr_t(end+1) = fa_time - bl_on;
            info(end+1) = tr;
        end
        
    case 'abort'
        % info returned: tr
        t = [];
        tr_t = [];
        info = [];
        for tr = 1:length(trials)
            bl_on  = daq.Baseline_ON.rise_t(tr);
            bl_off = daq.Baseline_ON.fall_t(tr);
            
            if ~strcmp(trials(tr).trialOutcome, 'abort')
                continue
            end
            abort_time = bl_off - .3;
            t(end+1) = abort_time;
            tr_t(end+1) = abort_time - bl_on;
            info(end+1) = tr;
        end
        
        
    case 'change'
        % info returned: change magnitude, hit(1)/miss(0), E(1)/U(0); RT
        t = [];
        tr_t = [];
        info = [];
        
        for tr = 1:length(trials)
            if ~strcmp(trials(tr).trialOutcome, 'Hit') & ~strcmp(trials(tr).trialOutcome, 'Miss')
                continue
            end
          
            bl_on  = daq.Baseline_ON.rise_t(tr); % use baseline onset signal - likely similar delay to change
            ch_on  = daq.Change_ON.rise_t(tr);
            
            t(end+1) = ch_on;
            tr_t(end+1) = ch_on-bl_on;
            
            if strcmp(trials(tr).trialOutcome, 'Hit')
                out = 1;
                rt = trials(tr).reactionTimes.RT;
            elseif strcmp(trials(tr).trialOutcome, 'Miss')
                out = 0;
                rt = 2.15;
            end
            
            if strcmp(trials(tr).trialType(end), 'U')
                exp = 0;
            else
                exp = 1;
            end
            
            
            
            info(end+1,:) = [trials(tr).changeTF-2, out, exp, rt, tr];
            
            
        end
        
    case 'hit'
        % info returned: change magnitude, E(1)/U(0); RT
        t = [];
        tr_t = [];
        info = [];
        
        for tr = 1:length(trials)
            if ~strcmp(trials(tr).trialOutcome, 'Hit')
                continue
            end
          
            bl_on  = daq.Baseline_ON.rise_t(tr); % use baseline onset signal - likely similar delay to change
            ch_on  = daq.Change_ON.rise_t(tr);
%             keyboard
            if isfield(daq, 'mouthOpening')
                if daq.mouthOpening.delta_time_by_tr(tr) < .7
                    hit_t = daq.mouthOpening.lick_onset_by_tr(tr);
                else
                    hit_t  = min(daq.Lick_L.rise_t(daq.Lick_L.rise_t>ch_on)) ...
                             - nanmean(daq.mouthOpening.delta_time_by_tr);
                end
            else
                hit_t  = min(daq.Lick_L.rise_t(daq.Lick_L.rise_t>ch_on));
            end
            
            if isempty(hit_t)
                hit_t = ch_on + trials(tr).reactionTimes.RT;
            end
            
            t(end+1) = hit_t;
            tr_t(end+1) = hit_t-bl_on;
            
            rt = hit_t - ch_on;
            
            if strcmp(trials(tr).trialType(end), 'U')
                exp = 0;
            else
                exp = 1;
            end
            
            
            
            info(end+1,:) = [trials(tr).changeTF-2, exp, rt, tr];
            
            
        end

end