function [trialFeatures, trStarts] = extract_features(trials, daq, motE, glm_ops)

nTr = length(trials);
binSize = glm_ops.tBin;
trialFeatures = struct();
if isfield(daq, 'mouthOpening')
    mouthO = daq.mouthOpening;
else
    mouthO=[];
end

%% Get trial timings
bl_starts = [daq.Baseline_ON.rise_t];
bl_ends   = [daq.Baseline_ON.fall_t];
ch_ends   = [daq.Change_ON.fall_t];

tr  = 0; % counter for good trials

%% Motion and treadmill
% movement
if isfield(daq, 'Front_cam')
motE_tax = daq.Front_cam.rise_t(2:end);
if isempty(motE_tax)
    if length(motE_tax) > length(motE)
        motE_tax = motE_tax(1:length(motE));
    end
end
end
% running speed
A_rise_t = daq.Rot_enc_A.rise_t';
A_fall_t = daq.Rot_enc_A.fall_t';
B_rise_t = daq.Rot_enc_B.rise_t';
B_fall_t = daq.Rot_enc_B.fall_t';

[speed, speed_tax] = utils.rot_enc_to_speed(A_rise_t, A_fall_t, B_rise_t, B_fall_t, binSize);
speed = zscore(speed);

%% Iterate through trials
trStarts = [];
tr = 0; % index of used trials
for tr_i = glm_ops.rmvStart:nTr

    tr_start = daq.frame_times_tr_corrected.time{tr_i}(1);

    % get trial end time
    tr_outcome = trials(tr_i).trialOutcome;
    switch tr_outcome
        case 'Hit'
            tr_end = min([min(daq.Lick_L.rise_t(daq.Lick_L.rise_t > tr_start)), ...
                          bl_ends(tr_i) + trials(tr_i).reactionTimes.RT]);
            bl_end = bl_ends(tr_i);
        case 'Miss'
            tr_end = ch_ends(tr_i);
            bl_end = bl_ends(tr_i);
        case 'FA'
            tr_end = min([min(daq.Lick_L.rise_t(daq.Lick_L.rise_t > tr_start)), ...
                         bl_ends(tr_i)]);
            bl_end = tr_end;
        case {'abort', 'Ref'}
            bl_end = bl_ends(tr_i);
            tr_end = bl_ends(tr_i);
    end

    % skip if trial too short
    if tr_end - tr_start < glm_ops.minTrialDur
        continue
    end

    tr = tr + 1;

    trStarts(tr) = tr_start;
    duration = ceil((tr_end-tr_start)/binSize);
    trialFeatures(tr).duration = duration;

    % Baseline onset
    trialFeatures(tr).baselineOnset = 1;

    % Baseline long
    trialFeatures(tr).baseline = glm_ops.longBLStart/ binSize;

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
    
    if glm_ops.splitELlick
        if lick_t < 7
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

    % Running speed
    trialFeatures(tr).speed = speed(speed_tax >= tr_start & speed_tax <= tr_end)';

    % Trial outcome - for one-hot encoding
    trialFeatures(tr).trialOutcome = tr_outcome;

    % Baseline TF
    tf_values  = glm.get_each_timebin_tf( ...
                         trials(tr_i).TF, ...
                         daq.frame_times_tr_corrected.time{tr_i}, ...
                         tr_start, tr_end, binSize);
    tf_values(tf_values<=0) = 1e-6;

    % split into baseline and change; change magnitudes will be
    % encoded one-hot
    last_bl = min([ceil((bl_end-tr_start + .05)/binSize), length(tf_values)]);

    bl_tf = log2([tf_values(1:last_bl); 2*ones(duration-last_bl,1)]/2)/0.25;

    trialFeatures(tr).TFch = trials(tr_i).changeTF-2;
    trialFeatures(tr).TFchOnset = last_bl+1;

    % split el/fs if specified
    if ~glm_ops.splitELtf && ~glm_ops.splitFStf
        trialFeatures(tr).TFbl = bl_tf;
    elseif glm_ops.splitELtf && ~glm_ops.splitFStf
        flip = round(7/binSize);
        trialFeatures(tr).TFbl_e = bl_tf(1:flip);
        trialFeatures(tr).TFbl_l = bl_tf(flip+1:end);
    elseif ~glm_ops.splitELtf && glm_ops.splitFStf
        bl_tf_F = bl_tf; bl_tf_F(bl_tf_F<0) = 0;
        bl_tf_S = bl_tf; bl_tf_S(bl_tf_S>0) = 0; bl_tf_S = bl_tf_S*-1;
        trialFeatures(tr).TFbl_f = bl_tf_F;
        trialFeatures(tr).TFbl_s = bl_tf_S;
    elseif glm_ops.splitELtf && glm_ops.splitFStf
        % first f-s split
        bl_tf_F = bl_tf; bl_tf_F(bl_tf_F<0) = 0;
        bl_tf_S = bl_tf; bl_tf_S(bl_tf_S>0) = 0;
        % then e-l split
        flip = round(7/binSize);
        bl_tf_FE = bl_tf_F; bl_tf_FE(flip+1:end) = 0;
        bl_tf_FL = bl_tf_F; bl_tf_FL(1:flip) = 0;
        bl_tf_SE = bl_tf_S; bl_tf_SE(flip+1:end) = 0; bl_tf_SE = bl_tf_SE*-1;
        bl_tf_SL = bl_tf_S; bl_tf_SL(1:flip) = 0; bl_tf_SL = bl_tf_SL*-1;
        trialFeatures(tr).TFbl_fe = bl_tf_FE;
        trialFeatures(tr).TFbl_fl = bl_tf_FL;
        trialFeatures(tr).TFbl_se = bl_tf_SE;
        trialFeatures(tr).TFbl_sl = bl_tf_SL;
    end

    % motion energy 
    if glm_ops.includeMotionEnergy & ~isempty(motE)
        motE = zscore(motE);
        in_tr_frames = isbetween(motE_tax, [tr_start tr_end]);
        tr_motE = motE(in_tr_frames);
        try
            tr_motE = interp1(motE_tax(in_tr_frames), tr_motE, tr_start:glm_ops.tBin:tr_end);
            tr_motE(isnan(tr_motE)) = 0;
            trialFeatures(tr).motionEnergy = tr_motE';
        catch
            tr_motE = zeros(length(tr_start:glm_ops.tBin:tr_end),1);
        end
    end

    % running speed



    



end


end