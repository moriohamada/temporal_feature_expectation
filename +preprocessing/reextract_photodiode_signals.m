%% Re-extract photodiode signal from all sessions
addpath(genpath('~/Documents/MATLAB/General'))
addpath(genpath('/home/morio/Documents/MATLAB/NPX'))
addpath(genpath('~/Documents/MATLAB/final_pipeline'))

ops.npxDir = '/mnt/ceph/public/projects/MoHa_20201102_SwitchChangeDetection/npx';

all_folders = dir2(ops.npxDir);
animals = all_folders(cellfun(@length, all_folders)==6 & contains(all_folders, 'MH_'));
errors = {};
for a = 1:numel(animals)
    animal = animals{a};
    animal_proc = fullfile(ops.npxDir, animal, 'Processed data');
    animal_raw  = fullfile(ops.npxDir, animal, 'Raw data');

    % get session directories
    sess_dirs = dir2(animal_proc);
    sess_dirs = sess_dirs(contains(sess_dirs, sprintf('%s_e', animal)));

    for s = 1:numel(sess_dirs)
        sess_name = sess_dirs{s};
        fprintf('Correcting photodiode signal for %s...', sess_name)
        try
            % load nidaq
            nidaq_evs_file = dir(fullfile(animal_proc, sess_name, 'Nidaq', '*NIdaq_events.mat'));
            NIdaq_events = loadVariable(fullfile(nidaq_evs_file.folder, nidaq_evs_file.name), 'NIdaq_events');
            if isfield(NIdaq_events, 'frame_times_tr_adj')
                fprintf('\n')
                continue 
            else
                keyboard
            end
            
            daq_dir   = fullfile(animal_raw, sess_name, 'EphysNidaq');
            bin_file  = dir(fullfile(daq_dir, '*bin'));
            meta_file = dir(fullfile(daq_dir, '*meta'));

            meta = ReadMeta(bin_file.name, meta_file.folder);
            [MN,MA,XA,DW] = ChannelCountsNI(meta);

            dataArray = ReadBin(0, inf, meta, bin_file.name, daq_dir);

            analog_chs = GainCorrectNI(dataArray(1:XA, :), 1:XA, meta);
            photodiode_signal = analog_chs(1, :);

            NI_sample_rate = SampRate(meta);

            
            % now get frame times
            frames_per_tr = preprocessing.extract_frame_times_from_photodiode(...
                    photodiode_signal, NI_sample_rate, NIdaq_events.Baseline_ON, NIdaq_events.Change_ON);
     
            % save to to nidaq (both on ceph and local
            NIdaq_events.frame_times_tr_adj = frames_per_tr;
            save(fullfile(nidaq_evs_file.folder, nidaq_evs_file.name), 'NIdaq_events', '-append');
    
            local_file = fullfile('/media/morio/Data_Fast/switch_task_revisions/session_data', ...
                                   sprintf('%s.mat', sess_name));
            if exist(local_file, 'file')
                daq = loadVariable(local_file, 'daq');
                daq.frame_times_tr_adj = frames_per_tr;
                save(local_file, 'daq', '-append')
            end
    
            clear daq NIdaq_events meta dataArray analog_chs photodiode_signal
            fprintf('done!\n')
        catch me
            errors{end+1} = me;
            fprintf('failed.\n')
        end
    end

end


% %%
% orig_times = daq.frame_times_tr_corrected.time;
% new_times  = frames_per_tr.time;
% f = figure;
% for tr = 1:length(orig_times)
% 
%     min_len = min([length(orig_times{tr}), length(new_times{tr})]);
%     if abs(length(orig_times{tr})-length(new_times{tr})) > 2 | any((orig_times{tr}(1:min_len)- new_times{tr}(1:min_len))>.02)
%         clf;
%         subplot(2,1,1);
%         scatter(orig_times{tr}(1:min_len), new_times{tr}(1:min_len));
%         % plot diagonal equality line
%         hold on;
%         plot([min(orig_times{tr}), max(orig_times{tr})], [min(orig_times{tr}), max(orig_times{tr})], 'r--'); % Diagonal line
%         hold off;
% 
%         subplot(2,1,2)
%         plot(new_times{tr}(1:min_len)-orig_times{tr}(1:min_len));
%         fprintf('Difference in number of frames: %d\n', length(orig_times{tr})-length(new_times{tr}))
%         sgtitle(sprintf('Trial %d: Scatter Plot of Original vs New Times', tr));
%         pause
%     end
% end
