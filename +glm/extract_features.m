function [trialFeatures, trStarts] = extract_glm_features_final(trials, daq, motE, flip_t, ops)

n_tr = length(trials);
binSize = ops.tBin; %s
trialFeatures = struct();
mouthO = daq.mouthOpening;
% keyboard
%% Iterate through trials and extract features trial-by-trial 
bl_starts = [daq.Baseline_ON.rise_t];
bl_ends   = [daq.Baseline_ON.fall_t];
ch_ends   = [daq.Change_ON.fall_t];

tr  = 0; % counter for good trials

% movement
motE_tax = daq.Front_cam.rise_t(2:end);
if length(motE_tax) > length(motE)
    motE_tax = motE_tax(1:length(motE));
end
% motE = zscore(motE);

% running speed
A_rise_t = daq.Rot_enc_A.rise_t';
A_fall_t = daq.Rot_enc_A.fall_t';
B_rise_t = daq.Rot_enc_B.rise_t';
B_fall_t = daq.Rot_enc_B.fall_t';

[speed, speed_tax] = rot_enc_to_speed(A_rise_t, A_fall_t, B_rise_t, B_fall_t, binSize);
speed = zscore(speed);

trStarts = [];

for tr_i = 1:n_tr
    
    % skip if abort
    if strcmp(trials(tr_i).trialOutcome, 'abort') | strcmp(trials(tr_i).trialOutcome, 'Ref') 
        continue
    end
%    
%     if daq.frame_times_tr.time{tr_i}(1) - bl_starts(tr_i) < .05
%         tr_start = daq.frame_times_tr.time{tr_i}(1);
%     else
%         tr_start = bl_starts(tr_i) + .04;
%     end
    tr_start = daq.frame_times_tr_corrected.time{tr_i}(1);
    % get trial end time
    tr_outcome = trials(tr_i).trialOutcome;
    switch tr_outcome
        case 'Hit'
            tr_end = min([min(daq.Lick_L.rise_t(daq.Lick_L.rise_t > tr_start)), ...
                          bl_ends(tr_i) + trials(tr_i).reactionTimes.RT])+1;
            bl_end = bl_ends(tr_i);
        case 'Miss'
            tr_end = ch_ends(tr_i);
            bl_end = bl_ends(tr_i);
        case 'FA'
            tr_end = min([min(daq.Lick_L.rise_t(daq.Lick_L.rise_t > tr_start)), ...
                         bl_ends(tr_i)]) + 1;
            bl_end = tr_end+1;
        case {'abort', 'Ref'}
            tr_end = bl_ends(tr_i) - 2;
    end
        
    % skip if trial too short
    if tr_end - tr_start < ops.minTrialDur
        continue
    end
        
    tr = tr + 1;
    
    trStarts(tr) = tr_start;
%     keyboard
    duration = ceil((tr_end-tr_start)/binSize);

    trialFeatures(tr).duration = duration;
    
    % Baseline onset
    trialFeatures(tr).baselineOnset = 1;
    
    % Baseline sustained
    trialFeatures(tr).baseline = ops.longBLStart/ binSize;
    
    % Licks
    lick_time = min(daq.Lick_L.rise_t(daq.Lick_L.rise_t > tr_start));
    if ~isempty(mouthO) 
        mouth_o_time = mouthO.lick_onset_by_tr(tr_i);
    else
        mouth_o_time = lick_time - .25;
    end
    if lick_time - mouth_o_time > 1
        mouth_o_time = lick_time - .25;
    end
    
    lick_t = mouth_o_time - tr_start;
    
    if ops.splitELlick
        if lick_t < flip_t
            trialFeatures(tr).PreLick_e = round(lick_t / binSize);
            trialFeatures(tr).Lick_e = round(lick_t / binSize);
            trialFeatures(tr).PreLick_l = [];
            trialFeatures(tr).Lick_l = [];
        else
            trialFeatures(tr).PreLick_e = [];
            trialFeatures(tr).Lick_e = [];
            trialFeatures(tr).PreLick_l = round(lick_t / binSize);
            trialFeatures(tr).Lick_l = round(lick_t / binSize);
        end
    else
        trialFeatures(tr).PreLick = round(lick_t / binSize);
        trialFeatures(tr).Lick = round(lick_t / binSize);
    end
    
    % Trial Outcomeo
    if ops.includeTrialOutcome
        switch tr_outcome
            case 'Miss'
                tr_lick = 0;
                tr_fin  = 1;
            case 'Hit'
                tr_lick = 1;
                tr_fin  = 1;
            case 'FA'
                tr_lick = 1;
                tr_fin = 0;
        end
        trialFeatures(tr).trialLicked   = tr_lick;
        trialFeatures(tr).trialFinished = tr_fin;
    end
    
    % TF values
    tf_values  = get_each_timebin_tf(trials(tr_i).TF, ...
                                     daq.frame_times_tr_corrected.time{tr_i}, ...
                                     daq.frame_times_tr_corrected.delayed_frames_numb(tr_i), ...
                                     tr_start, tr_end, binSize);
    
    %tf_values  = log2(tf_values/2);
    %tf_values(tf_values==-inf) = 0;
    % now remove all entries where values are same as previous
    diffs = diff(tf_values); diffs = [1; diffs];
    tf_values(diffs==0) = 0;
    tf_values(tf_values==0)=2;

    % split into baseline and change
    last_bl = min([round((bl_end-tr_start)/binSize), length(tf_values)]);
    tf_bl = tf_values(1:last_bl);
%     keyboard
    if last_bl <= length(tf_values)
        tf_ch = tf_values(last_bl:end);
        
    else
        tf_ch = [];
    end
    
    bl_tf = log2([tf_bl; 2*ones(duration-length(tf_bl),1)]/2);
    ch_tf = [2*ones(duration-length(tf_ch),1); tf_ch]-2;
    
    if ~ops.splitELtf & ~ops.splitFStf
        trialFeatures(tr).TFbl = bl_tf;
        trialFeatures(tr).TFch = ch_tf;
    elseif ops.splitELtf & ~ops.splitFStf
        ch_time    = round(flip_t / ops.tBin);
        shift_time = round(ops.switchPeriod / ops.tBin);
        early_mult = [ones(1, ch_time-shift_time), linspace(1, 0, shift_time), zeros(1, duration)]';
        late_mult  = 1 - early_mult;
        early_mult = early_mult(1:duration);
        late_mult  = late_mult(1:duration);
        
        trialFeatures(tr).TFbl_e = bl_tf .* early_mult;
        trialFeatures(tr).TFbl_l = bl_tf .* late_mult;
        trialFeatures(tr).TFch   = ch_tf;
    elseif ~ops.splitELtf & ops.splitFStf
        bl_tf_F = bl_tf; bl_tf_F(bl_tf<0) = 0;
        bl_tf_S = bl_tf; bl_tf_S(bl_tf>0) = 0; bl_tf_S = -bl_tf_S;
        ch_tf_F = ch_tf; ch_tf_F(ch_tf<0) = 0;
        ch_tf_S = ch_tf; ch_tf_S(ch_tf>0) = 0; ch_tf_S = -ch_tf_S;
        
        trialFeatures(tr).TFbl_f = bl_tf_F;
        trialFeatures(tr).TFbl_s = bl_tf_S;
        trialFeatures(tr).TFch_f = ch_tf_F;
        trialFeatures(tr).TFch_s = ch_tf_S;
        
    elseif ops.splitELtf & ops.splitFStf
        ch_time    = round(flip_t / ops.tBin);
        shift_time = round(ops.switchPeriod / ops.tBin);
        early_mult = [ones(1, ch_time-shift_time), linspace(1, 0, shift_time), zeros(1, duration)]';
        late_mult  = 1 - early_mult;
        early_mult = early_mult(1:duration);
        late_mult  = late_mult(1:duration);
        
        early_bl = bl_tf .* early_mult;
        late_bl  = bl_tf .* late_mult;
        
        % early
        bl_tf_F = early_bl; bl_tf_F(bl_tf<0) = 0;
        bl_tf_S = early_bl; bl_tf_S(bl_tf>0) = 0; bl_tf_S = -bl_tf_S;
        trialFeatures(tr).TFbl_fe = bl_tf_F;
        trialFeatures(tr).TFbl_se = bl_tf_S;
        
        % late
        bl_tf_F = late_bl; bl_tf_F(bl_tf<0) = 0;
        bl_tf_S = late_bl; bl_tf_S(bl_tf>0) = 0; bl_tf_S = -bl_tf_S;
        trialFeatures(tr).TFbl_fl = bl_tf_F;
        trialFeatures(tr).TFbl_sl = bl_tf_S;
        
        ch_tf_F = ch_tf; ch_tf_F(ch_tf<0) = 0;
        ch_tf_S = ch_tf; ch_tf_S(ch_tf>0) = 0; ch_tf_S = -ch_tf_S;
        trialFeatures(tr).TFch_f = ch_tf_F;
        trialFeatures(tr).TFch_s = ch_tf_S;
    else
        warning('\nbasleine TF EL/FS split combination not implemented!\n')
        trialFeatures(tr).TFbl = bl_tf;
        trialFeatures(tr).TFch = ch_tf;
    end
    
    % absolute TF
%     if ops.includeAbsoluteTF
%         trialFeatures(tr).TFbl_abs = abs(bl_tf);
%     end
    
    % Direction
    this_tr_ori = trials(tr_i).orientation;
    if this_tr_ori == 90, ori_val = 1; elseif this_tr_ori == 270, ori_val = -1; end
%     
%     if ops.includeDirection
%         trialFeatures(tr).Direction = ori_val;
%         if ~ops.splitELtf
%             trialFeatures(tr).TFblXDir = trialFeatures(tr).TFbl * ori_val;
%         end
%     end
%             
    % phase
    if ops.includePhase
        phases  = get_each_timebin_tf(trials(tr_i).phase, ...
                                     daq.frame_times_tr_corrected.time{tr_i}, ...
                                     daq.frame_times_tr_corrected.delayed_frames_numb(tr_i), ...
                                     tr_start, tr_end, binSize);
        phases = mod(phases.*ori_val, 360);
        for ph_bin = 1:360/ops.phaseSplit
            ph_range = [(ph_bin-1)*ops.phaseSplit, ph_bin*ops.phaseSplit];
            this_bin_phase = phases;
            this_bin_phase(~isbetween(this_bin_phase, ph_range)) = 0;
            this_bin_phase(this_bin_phase~=0) = 1;
            diffs = diff(this_bin_phase); diffs = [1; diffs];
            this_bin_phase(diffs==0) = 0;
            trialFeatures(tr).(sprintf('Phase%d',ph_bin)) = this_bin_phase;
        end
    end
        
    
    % Time x TF interaction
%     if ops.includeTimeTFInteration
%         flip_fr = flip_t/binSize;
%         transition = round(ops.switchPeriod/binSize/2);
%         time_vec = [-1*ones(flip_fr-transition, 1); ...
%             linspace(-1, 1, flip_fr+transition)'; ...
%             ones(flip_fr + 10/binSize,1)];
%         
%         time_vec = time_vec(1:duration);
%         trialFeatures(tr).TFblXtime = trialFeatures(tr).TFbl .* time_vec(1:length(trialFeatures(tr).TFbl));
%     end
    
    % motion energy
    if ops.includeMotionEnergy
        
        in_tr_frames = isbetween(motE_tax, [tr_start tr_end]);
        tr_motE = motE(in_tr_frames);
        
        % resample to match glm tbin
        try
        tr_motE = interp1(motE_tax(in_tr_frames), tr_motE, tr_start:ops.tBin:tr_end);
        tr_motE(isnan(tr_motE)) = 0;
        trialFeatures(tr).motionEnergy = tr_motE';
%         catch
%             keyboard
%         end
        end
    end
    
    
    % running speed
    if ops.includeRunSpeed
        in_tr_spd = isbetween(speed_tax, [tr_start tr_end]);
        tr_spd = speed(in_tr_spd);
        tr_spd = interp1(speed_tax(in_tr_spd), tr_spd, tr_start:ops.tBin:tr_end);
        tr_spd(isnan(tr_spd)) = 0;
        trialFeatures(tr).runSpeed = tr_spd';
    end
    
end

end


