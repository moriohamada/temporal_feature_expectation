function extract_raw_photodiode_signal(paths, db)
% Extract raw photodiode trace and frame times, save into compact file
% for easy loading in gui.
addpath(genpath('/home/morio/Documents/MATLAB/NPX'))
%%
if ~exist(paths.photodiodeData)
    mkdir(paths.photodiodeData);
end

for a = 1:length(db.animals)
    animal = db.animals{a};
    fprintf('Extracting photodiode data for %s (%d/%d)\n', ...
             animal, a, length(db.animals));
    sessions = db.sessions{a};

    paths.rawAnimal = fullfile(paths.npxDir, animal, 'Raw data');

    for s = 1:length(sessions)
        session = sessions{s};
        fprintf('\tsession %s (%d/%d)\n', session, s, length(sessions))

        paths.saveSess = fullfile(paths.photodiodeData, ...
                                  sprintf('%s_%s.mat', animal, session));
        % if exist(paths.saveSess, 'file')
        %     continue
        % end
        % load frame times
        preprocessed_path = fullfile(paths.preprocessedDir, ...
                                     sprintf('%s_%s.mat', animal, session));

        daq = loadVariable(preprocessed_path, 'daq');
        if isfield(daq, 'frame_times_tr_adj')
            frame_times = daq.frame_times_tr_adj;
        else
            frame_times = daq.frame_times_tr_corrected;
        end

        % load raw data
        if strcmp(animal, 'MH_004')
            paths.rawSess = fullfile(paths.rawAnimal, ...
                                     [animal, '_', session,'_M2']);
        else
            paths.rawSess = fullfile(paths.rawAnimal, ...
                                    [animal, '_', session]);
        end
        daq_dir   = fullfile(paths.rawSess, 'EphysNidaq');
        bin_file  = dir(fullfile(daq_dir, '*bin'));
        meta_file = dir(fullfile(daq_dir, '*meta'));

        meta = ReadMeta(bin_file.name, meta_file.folder);
        [MN,MA,XA,DW] = ChannelCountsNI(meta);

        dataArray = ReadBin(0, inf, meta, bin_file.name, daq_dir);

        analog_chs = GainCorrectNI(dataArray(1:XA, :), 1:XA, meta);
        photodiode_signal_raw = analog_chs(1, :);
        NI_sample_rate = SampRate(meta);

        % get trial-by-trial
        nTr = length(daq.Baseline_ON.rise_t);

        trialStartTimes = daq.Baseline_ON.rise_t;
        trialEndTimes = max([ [row(daq.Change_ON.fall_t)] ; [row(daq.Baseline_ON.fall_t)] ]);
        Trial_Start_smpl_ind = NI_sample_rate * trialStartTimes;
        Trial_End_smpl_ind = NI_sample_rate * trialEndTimes;

        photodiode_signal = cell(nTr, 1);
        for tr = 1:nTr
            tr_start = round(Trial_Start_smpl_ind(tr) - 2*NI_sample_rate); % 2s before trial
            tr_end = round(Trial_End_smpl_ind(tr) + 1*NI_sample_rate); % 1 s after trial
            photodiode_signal{tr} = photodiode_signal_raw(tr_start:tr_end);
        end
         
        clear photodiode_signal_raw analog_chs dataArray MN MA XA DW
 
        % save both to photodiode data path
        
        save(paths.saveSess, 'frame_times', 'photodiode_signal', 'NI_sample_rate', 'trialStartTimes')

        paths = rmfield(paths, 'saveSess');
        paths = rmfield(paths, 'rawSess');
    end

    paths = rmfield(paths, 'rawAnimal');

end

end