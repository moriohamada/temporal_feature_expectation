function daq_all = add_corrected_frame_times(sessions, trials_all, daq_all)
% update daq frame times with re-extracted frame times.
% This code does not find the re-extracted frame times itself! 

%%
for ii = 1:length(daq_all)

    if isempty(daq_all{ii})
        continue
    end
    try
    new_frame_times = daq_all{ii}.frame_times_tr_adj.time;
    old_frame_times = daq_all{ii}.frame_times_tr_corrected.time;
    nTr = length(new_frame_times);
    catch
        if ~isfield(daq_all{ii}, 'frame_times_tr_adj')
            continue
        end
    end
    n_changed = 0;
    for tr = 1:nTr
        bl_on  = daq_all{ii}.Baseline_ON.rise_t(tr);
        bl_off = daq_all{ii}.Baseline_ON.fall_t(tr);
        ch_off = daq_all{ii}.Change_ON.fall_t(tr);
        tr_end = max([bl_off, ch_off]);

        expected_frame_times = bl_on:1/60:tr_end;

        new_tr_times = new_frame_times{tr};
        old_tr_times = old_frame_times{tr};

        % check if new trial times are reasonable
        new_good_check = 0;
        old_good_check = 0;
        length_diff_new = abs(length(expected_frame_times) - length(new_tr_times)) ;
        if length_diff_new < 5 
            new_good_check = new_good_check + 1;
        end
        length_diff_old = abs(length(expected_frame_times) - length(old_tr_times));
        if length_diff_old < 5
            old_good_check = old_good_check + 1;
        end

        % align lengths & check which is closer to expected
        if length(expected_frame_times) > length(new_tr_times)
            new_tr_times(end+1:length(expected_frame_times)) = NaN; % Pad with NaNs
        else
            new_tr_times = new_tr_times(1:length(expected_frame_times)); % Trim to match
        end
        if length(expected_frame_times) > length(old_tr_times)
            old_tr_times(end+1:length(expected_frame_times)) = NaN; % Pad with NaNs
        else
            old_tr_times = old_tr_times(1:length(expected_frame_times)); % Trim to match
        end

        mean_diff_new = mean(abs(new_tr_times - expected_frame_times), 'omitmissing') - min(abs(new_tr_times - expected_frame_times));
        var_diff_new  = std(abs(new_tr_times - expected_frame_times), 'omitmissing');
        mean_diff_old = mean(abs(old_tr_times - expected_frame_times), 'omitmissing') - min(abs(old_tr_times - expected_frame_times));
        var_diff_old = std(abs(old_tr_times - expected_frame_times), 'omitmissing');

        if mean_diff_new <= 1/20 & var_diff_new <= 1/60
            new_good_check = new_good_check+1; 
        end
        
        if mean_diff_old <= 1/20 & var_diff_old <= 1/60
            old_good_check = old_good_check+1; 
        end
     

        % check reasonable IFI
        if (max(diff(new_tr_times))<.05 & abs(mean(diff(new_tr_times), 'omitmissing') - 1/60)<.005) ...
            new_good_check = new_good_check + 1;
        end


        if (max(diff(old_tr_times))<.05 & abs(mean(diff(old_tr_times), 'omitmissing') - 1/60)<.005) ...
            old_good_check = old_good_check + 1;
        end

        if new_good_check >= old_good_check
            daq_all{ii}.frame_times_tr_corrected.time{tr} = new_tr_times; % Update with new trial times
            n_changed = n_changed + 1;
        end
        
    end
    fprintf('%s, %s\n', sessions(ii).animal, sessions(ii).session)
    fprintf('Number of trials changed: %d/%d\n', n_changed, nTr)
end