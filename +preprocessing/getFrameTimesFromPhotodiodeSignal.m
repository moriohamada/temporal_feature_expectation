function frames_per_tr = extract_frame_times_from_photodiode(photodiode_signal, NI_sample_rate,  Baseline_ON, Change_ON)
% Go through trial-by-trial, extract frame times

trialStartTimes = Baseline_ON.rise_t;
trialEndTimes = max([ [Change_ON.fall_t] ; [Baseline_ON.fall_t] ]);


Trial_Start_smpl_ind = round(NI_sample_rate * trialStartTimes);
Trial_End_smpl_ind = round(NI_sample_rate * trialEndTimes);
t = (1:length(photodiode_signal))/NI_sample_rate;

delta = round(0.1*NI_sample_rate); % extra 100ms
%%
up_state_times = [];
down_state_times = [];
for tr = 1:length(Trial_Start_smpl_ind)
    tr_start = round(Trial_Start_smpl_ind(tr) - 2*NI_sample_rate); % 2s before trial
    tr_end = Trial_End_smpl_ind(tr) + delta;
    tr_signal = photodiode_signal(tr_start:tr_end);
    t_trial = t(tr_start:tr_end);
    
    % use ITI to establish thresholds/expected range
    iti_signal = photodiode_signal(tr_start:round(tr_start+1.5*NI_sample_rate));
    iti_mean   = mean(iti_signal);
    iti_std    = std(iti_signal);
    iti_max    = prctile(iti_signal, 97.5);
    iti_min    = prctile(iti_signal, 2.5);

     % get high peaks in trial
     [~, up_state_times_tr] = findpeaks(tr_signal-iti_mean, t_trial, 'MinPeakProminence', 2*(iti_max-iti_min), 'MinPeakDistance', .02);
     up_state_times = [up_state_times, up_state_times_tr];
     [~, down_state_times_tr] = findpeaks(iti_mean-tr_signal, t_trial, 'MinPeakProminence', 2*(iti_max-iti_min), 'MinPeakDistance', .02);
     down_state_times = [down_state_times, down_state_times_tr];
     
end

frame_times_tot = [up_state_times, down_state_times];
frame_times_tot = sort(frame_times_tot);  % these are frame offset times    
IFI = diff(frame_times_tot);
IFI(IFI>0.5) = [];
IFI = median(IFI);

%% check
frames_per_tr = [];
trials_numb = length(Trial_Start_smpl_ind);

for tr = 1:trials_numb

    tr_start_time = trialStartTimes(tr) - 0.5;  % 0.5s just to be safe 
    tr_end_time = trialEndTimes(tr) + 0.5; 

    frame_times_tr = frame_times_tot( find( (frame_times_tot>=tr_start_time)&(frame_times_tot<=tr_end_time) )); 
    frame_times_tr = [ (frame_times_tr(1) - IFI)   frame_times_tr(1:end-1)];    % shifting from frame offset times to onset times

    if any(frame_times_tr<trialStartTimes(tr))
        keyboard
    end
    if any(frame_times_tr>trialEndTimes(tr)+.1)
        keyboard
    end
 
    frames_per_tr.time{1, tr} = frame_times_tr;
    frames_per_tr.delayed_frames_numb(1, tr) = sum( diff(frame_times_tr)>(1.2*IFI));  
end

end