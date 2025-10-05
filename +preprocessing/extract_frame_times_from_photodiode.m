function frames_per_tr = extract_frame_times_from_photodiode(photodiode_signal, NI_sample_rate,  Baseline_ON, Change_ON)
% Go through trial-by-trial, extract frame times

trialStartTimes = Baseline_ON.rise_t;
trialEndTimes = max([ [row(Change_ON.fall_t)] ; [row(Baseline_ON.fall_t)] ]);


Trial_Start_smpl_ind = round(NI_sample_rate * trialStartTimes);
Trial_End_smpl_ind = round(NI_sample_rate * trialEndTimes);
t = (1:length(photodiode_signal))/NI_sample_rate;

delta = round(0.08*NI_sample_rate); % extra 50ms
%%
up_state_times = [];
down_state_times = [];
for tr = 1:length(Trial_Start_smpl_ind)
    tr_start = round(Trial_Start_smpl_ind(tr) - 2*NI_sample_rate); % 2s before trial
    tr_end = Trial_End_smpl_ind(tr) + delta;
    tr_signal = photodiode_signal(tr_start:tr_end);
    t_trial = t(tr_start:tr_end);
    
    % get iti distribution
    iti_signal = photodiode_signal(tr_start:round(tr_start+1.5*NI_sample_rate));
    iti_mean   = mean(iti_signal);
    iti_std    = std(iti_signal);
    iti_max    = prctile(iti_signal, 97.5);
    iti_min    = prctile(iti_signal, 2.5);

    % get stim distribution
    stim_signal = photodiode_signal(Trial_Start_smpl_ind(tr)+2:Trial_End_smpl_ind(tr));
    stim_mean   = mean(stim_signal);
    stim_std    = std(stim_signal);

    %% Look for first samples exceeding iti range

    search_window = Trial_Start_smpl_ind(tr):(Trial_Start_smpl_ind(tr)+round(.1*NI_sample_rate));
    search_window = search_window - tr_start;

    % Define ITI "normal" range
    iti_upper = iti_mean + 2*iti_std;  % or use iti_max from your percentile calc
    iti_lower = iti_mean - 2*iti_std;  % or use iti_min

    % Look for first sustained excursion outside ITI range
    n_consecutive = round(0.033 * NI_sample_rate); % 1 cycle
    for ii = 1:length(search_window)
        start_idx = search_window(ii);
        end_idx = min(start_idx + n_consecutive - 1, length(tr_signal));

        window_samples = tr_signal(start_idx:end_idx);

        % Count how many samples exceed ITI range
        exceeds_range = sum(window_samples > iti_upper | window_samples < iti_lower);

        % If enough samples exceed range, we've found transition
        if exceeds_range > n_consecutive * 0.5  % >50% of samples exceed
            transition_idx = start_idx + n_consecutive/2;
            break;
        end
    end

    %%
    % figure; 
    % plot(t_trial(1:transition_idx),tr_signal(1:transition_idx),'b'); 
    % hold on; 
    % plot(t_trial(transition_idx:end),tr_signal(transition_idx:end),'r')
     %%
    % get high peaks in stim period
    try
        [~, up_state_times_tr] = findpeaks([0 tr_signal(transition_idx:end)-stim_mean], t_trial(transition_idx-1:end), ...
                                           'MinPeakProminence', stim_std, 'MinPeakDistance', .02);
        up_state_times = [up_state_times, up_state_times_tr];
    end
    try
        [~, down_state_times_tr] = findpeaks([0 stim_mean-tr_signal(transition_idx:end)], t_trial(transition_idx-1:end), ...
                                             'MinPeakProminence', stim_std, 'MinPeakDistance', .02);
        down_state_times = [down_state_times, down_state_times_tr];
    end
     
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
    if isempty(frame_times_tr)
        if trialEndTimes(tr)-trialStartTimes(tr) < .05
            continue
        end
    end
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