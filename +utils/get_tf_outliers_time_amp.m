function [amps, times, tr_times, licked] = ...
            get_tf_outliers_time_amp(trials, daq, bltf, sd, thresh, direction, rmvTimeAround, respWin)
% 
% Return amplitude and times of high or low tf fluctations in baseline stim, and whether there was a
% lick within next respWin seconds of pulse
% 
% INPUTS -------------------------------------------------------------------------------------------
% 
% trials
%   (n_trials x 1) struct; session data read in from json files
% 
% daq
%   (1 x 1 struct); wih fields for different NIDAQ events
% 
% bltf
%   float; mean baseline temporal frequency.
% 
% thresh
%   float; threshold (in standard deviations) away from mean to consider outlier
% 
% direction
%   +/- 1, for positive and negative fluctuations, respectively
% 
% rmvTimeAround
%   float; don't consider this much time around salient events (baseline onset, movement)
%
% respWin
%   [1 x 2] vector of floats; 
% 
% OUTPUTS ------------------------------------------------------------------------------------------
% 
% times
%   [1 x n_events] - time of outlier fluctuations, in seconds
% 
% TYPICAL USAGE EXAMPLE ----------------------------------------------------------------------------
% 
% animal = 'XX_000';
% session = 'e1';
% ops.dataDir = '/path/to/data/';
% 
% [trials, exp_settings, daq, sp] = load_single_session(animal, session, ops);
% 
% bltf = exp_settings.BaselineTFs;   % mean baseline TF
% sd = exp_settings.NoiseLevels;     % noise level of baseline (octaves)
% thresh = 1.5;                      % want fluctations >1.5 standard deviations from mean
% direction = 1;                     % get positive fluctuations
% rmvTimeAround = 1;                 % remove 1s around salient events
% 
% fast_tf_outlier_times = get_tf_outliers(trials, daq, bltf, sd, thresh, direction, rmvTimeAround);
% 
% --------------------------------------------------------------------------------------------------

n_tr = length(trials);

times = [];
tr_times = [];
amps  = [];
licked = [];

% keyboard
for tr = 1:n_tr
     
    baseline_tf_vec = trials(tr).baselineStimVec(1:3:end);
    
    % find all frames where baseline higher/lower than <thresh> sd:
    if direction == 1 % looking for high tf
        upper_thresh = 2^(log2(bltf)+sd*thresh);
        outliers = baseline_tf_vec > upper_thresh ; 
    elseif direction == -1
        lower_thresh = 2^(log2(bltf)-sd*thresh);
        outliers = baseline_tf_vec < lower_thresh ;% 
    elseif direction == 2 % both
        lower_thresh = 2^(log2(bltf)-sd*thresh);
        upper_thresh = 2^(log2(bltf)+sd*thresh);
        outliers = baseline_tf_vec < lower_thresh | baseline_tf_vec > upper_thresh;
    elseif direction == 0 % between
        lower_thresh = 2^(log2(bltf)-sd*thresh);
        upper_thresh = 2^(log2(bltf)+sd*thresh);
        outliers = baseline_tf_vec > lower_thresh & baseline_tf_vec < upper_thresh;
    else
        keyboard
    end
    
    outliers = find(outliers); 
    try
    this_tr_frames = daq.frame_times_tr_corrected.time{tr}(1:3:end);
    catch
    this_tr_frames = daq.frame_times_tr.time{tr}(1:3:end);
    end
    baseline_end_t  = daq.Baseline_ON.fall_t(tr);
    
    outliers(outliers > length(this_tr_frames)) = []; 
    
    if ~isempty(outliers)
        
        this_tr_times = this_tr_frames(outliers);
        this_tr_amps  = baseline_tf_vec(outliers);
        
        
        % remove anything within <rmvTimeAround> seconds of baseline onset
        this_tr_amps(this_tr_times < daq.Baseline_ON.rise_t(tr) + rmvTimeAround) = [];
        this_tr_times(this_tr_times < daq.Baseline_ON.rise_t(tr) + rmvTimeAround) = [];

        switch trials(tr).trialOutcome
            
            % last time point in trial to consider depends on trial outcome
            case {'Hit', 'Ref'} 
                % if there was a lick after change, consider until before lick or end of baseline stim
                % (whichever is first)
                lick_time = min(daq.Lick_L.rise_t(daq.Lick_L.rise_t > daq.Baseline_ON.rise_t(tr))); % first lick after baseline onset
                bl_end_time = min([daq.Baseline_ON.fall_t(tr), lick_time-rmvTimeAround]);
                
                this_tr_amps(this_tr_times > bl_end_time)  = [];
                this_tr_times(this_tr_times > bl_end_time ) = [];
                this_tr_licked = zeros(size(this_tr_times));
            case 'Miss' 
                % if no lick/movement throughout trial, then use the whole baseline period
                bl_end_time = daq.Baseline_ON.fall_t(tr);
                this_tr_amps(this_tr_times > bl_end_time)  = [];
                this_tr_times(this_tr_times > bl_end_time ) = [];
                this_tr_licked = zeros(size(this_tr_times));
            case 'abort'
                % for aborts, take up to <rmvTimeAround> seconds before running onset
                bl_end_time = daq.Baseline_ON.fall_t(tr)-rmvTimeAround;
                this_tr_amps(this_tr_times > bl_end_time)  = [];
                this_tr_times(this_tr_times > bl_end_time ) = [];
                this_tr_licked = zeros(size(this_tr_times));
            case 'FA'
                % for false alarms: remove cases where lick happens too close to tf outlier (smaller
                % than respWin); otherwise, label whether mouse licked
                lick_time = min(daq.Lick_L.rise_t(daq.Lick_L.rise_t > daq.Baseline_ON.rise_t(tr))); % first lick after baseline onset
                if isempty(lick_time)
                    lick_time = daq.Baseline_ON.fall_t(tr);
                end
                bl_end_time = lick_time-respWin(1);
                this_tr_amps(this_tr_times > bl_end_time)  = [];
                this_tr_times(this_tr_times > bl_end_time) = [];
                this_tr_licked = double(isbetween(this_tr_times, [lick_time - respWin(2), lick_time - respWin(1)])); 
                
        end
        
        % get time in trial
        this_tr_times_from_bl = this_tr_times - daq.Baseline_ON.rise_t(tr);
        
        rmv = isnan(this_tr_licked);
        
        times(end+1:end+length(this_tr_times(~rmv))) = this_tr_times(~rmv);
        tr_times(end+1:end+length(this_tr_times(~rmv))) = this_tr_times_from_bl(~rmv);
        amps(end+1:end+length(this_tr_amps(~rmv)))   = log2(this_tr_amps(~rmv)/bltf);
        licked(end+1:end+length(this_tr_licked(~rmv))) = this_tr_licked(~rmv);
                
        
        
    end
    
end

end