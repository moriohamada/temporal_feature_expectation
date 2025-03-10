function [trials, daq] = remove_excluded_trials(trials, daq)
% 
% remove all events that occur in removed trials from both trials and daq structures
% 
% --------------------------------------------------------------------------------------------------

rmv_trial = ~([trials.keepTrial] & [trials.deviantsOn]);

% get trials start times
tr_periods = [daq.Baseline_ON.rise_t'-1, [daq.Baseline_ON.rise_t(2:end)'; inf]];
tr_periods(rmv_trial,:) = [];

% Baseline On
in_tr = ~rmv_trial;
daq.Baseline_ON.rise_t = daq.Baseline_ON.rise_t(in_tr);
daq.Baseline_ON.fall_t = daq.Baseline_ON.fall_t(in_tr);
daq.Baseline_ON.duration = daq.Baseline_ON.duration(in_tr);

% Change on
in_tr = ~rmv_trial;
daq.Change_ON.rise_t = daq.Change_ON.rise_t(in_tr);
daq.Change_ON.fall_t = daq.Change_ON.fall_t(in_tr);
daq.Change_ON.duration = daq.Change_ON.duration(in_tr);

% Air puff
in_tr = ~rmv_trial;
daq.Air_puff.rise_t = daq.Air_puff.rise_t(in_tr);
daq.Air_puff.fall_t = daq.Air_puff.fall_t(in_tr);
daq.Air_puff.duration = daq.Air_puff.duration(in_tr);

% Lick L
in_tr = any(daq.Lick_L.rise_t' > tr_periods(:,1) & daq.Lick_L.rise_t' < tr_periods(:,2), 1);
daq.Lick_L.rise_t = daq.Lick_L.rise_t(in_tr);
daq.Lick_L.fall_t = daq.Lick_L.fall_t(in_tr);
daq.Lick_L.duration = daq.Lick_L.duration(in_tr);

% valve L
in_tr = ~rmv_trial;
daq.Valve_L.rise_t = daq.Valve_L.rise_t(in_tr);
daq.Valve_L.fall_t = daq.Valve_L.fall_t(in_tr);
daq.Valve_L.duration = daq.Valve_L.duration(in_tr);

% frames
in_tr = ~rmv_trial;
daq.frame_times_tr.time = daq.frame_times_tr.time(in_tr);
daq.frame_times_tr.delayed_frames_numb = daq.frame_times_tr.delayed_frames_numb(in_tr);

daq.frame_times_tr_corrected.time = daq.frame_times_tr_corrected.time(in_tr);
daq.frame_times_tr_corrected.delayed_frames_numb = daq.frame_times_tr_corrected.delayed_frames_numb(in_tr);

if isfield(daq, 'frame_times_tr_adj')
daq.frame_times_tr_adj.time = daq.frame_times_tr_adj.time(in_tr);
daq.frame_times_tr_adj.delayed_frames_numb = daq.frame_times_tr_adj.delayed_frames_numb(in_tr);
end
% rot encoders
in_tr = any(daq.Rot_enc_A.rise_t' > tr_periods(:,1) & daq.Rot_enc_A.rise_t' < tr_periods(:,2), 1);
daq.Rot_enc_A.rise_t = daq.Rot_enc_A.rise_t(in_tr);
in_tr = any(daq.Rot_enc_A.fall_t' > tr_periods(:,1) & daq.Rot_enc_A.fall_t' < tr_periods(:,2), 1);
daq.Rot_enc_A.fall_t = daq.Rot_enc_A.fall_t(in_tr);
% daq.Rot_enc_A.duration = daq.Rot_enc_A.duration(in_tr);

in_tr = any(daq.Rot_enc_B.rise_t' > tr_periods(:,1) & daq.Rot_enc_B.rise_t' < tr_periods(:,2), 1);
daq.Rot_enc_B.rise_t = daq.Rot_enc_B.rise_t(in_tr);
in_tr = any(daq.Rot_enc_B.fall_t' > tr_periods(:,1) & daq.Rot_enc_B.fall_t' < tr_periods(:,2), 1);
daq.Rot_enc_B.fall_t = daq.Rot_enc_B.fall_t(in_tr);
% daq.Rot_enc_B.duration = daq.Rot_enc_B.duration(in_tr);

% mouth opening
if isfield(daq, 'mouthOpening')
daq.mouthOpening.delta_time_by_tr = daq.mouthOpening.delta_time_by_tr(~rmv_trial);
daq.mouthOpening.lick_onset_by_tr = daq.mouthOpening.lick_onset_by_tr(~rmv_trial);
end

% trials
trials = trials(~rmv_trial);


end