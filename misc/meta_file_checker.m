%% Sanity check - just get spike times from sp struct, and align to licks


% for every session, get difference in file times between nidq and imec
npx_dir = '/mnt/ceph/public/projects/MoHa_20201102_SwitchChangeDetection/npx/';

nidq_data = cell(length(sessions),1);
imec_data = cell(length(sessions),2);

for s = 1:length(sessions)
    if isempty(sp_all{s})
        continue
    end

    animal  = sessions(s).animal;
    session = sessions(s).session;

    if strcmp(animal, 'MH_004')
        session = strcat(session, '_M2');
    end



    % read file time secs from nidaq and each imec probe, save
    raw_sess_dir = fullfile(npx_dir, animal, 'Raw data', [animal,'_',session], ...
                            'EphysNidaq');

    if strcmp(animal, 'MH_010') & strcmp(session, 'e5')
        raw_sess_dir = fullfile(npx_dir, 'MH_006', 'Raw data', 'MH_006_e1', ...
                            'EphysNidaq');
    end
    nidq_meta_file = dir(fullfile(raw_sess_dir, '*meta'));
    nidq_meta_full = ReadMeta(nidq_meta_file.name, nidq_meta_file.folder);
    nidq_meta.fileTimeSecs = nidq_meta_full.fileTimeSecs;
    nidq_meta.firstSample = nidq_meta_full.firstSample;
    nidq_meta.niSampRate = nidq_meta_full.niSampRate;

    nidq_data{s} = nidq_meta;

    clear nidq_meta_full nidq_meta

    % now each imec folder
    all_paths = dir(fullfile(raw_sess_dir));
    dir_flag  = [all_paths.isdir];
    imec_folders = all_paths(dir_flag);
    imec_folders = imec_folders(3:end);

    for ii = 1:length(imec_folders)
        imec_path = fullfile(raw_sess_dir, imec_folders(ii).name);
        imec_meta_file = dir(fullfile(imec_path, '*ap.meta'));
        imec_meta_full = ReadMeta(imec_meta_file.name, imec_meta_file.folder);
        imec_meta.fileTimeSecs = imec_meta_full.fileTimeSecs;
        imec_meta.firstSample = imec_meta_full.firstSample;
        imec_meta.imSampRate = imec_meta_full.imSampRate;
        imec_data{s, ii} = imec_meta;
        clear imec_meta_full imec_meta
    end
end

%% get differences in file starts and file durations

start_time_diff = nan(length(sessions),2);
file_time_diff  = nan(length(sessions),2);

for s = 1:length(sessions)
    if isempty(nidq_data{s})
        continue
    end
    nidq_file_dur = str2double(nidq_data{s}.fileTimeSecs);
    nidq_start_time = str2double(nidq_data{s}.firstSample)/str2double(nidq_data{s}.niSampRate);

    for ii = 1:2
        if isempty(imec_data{s,ii})
            continue
        end
        imec_file_dur = str2double(imec_data{s, ii}.fileTimeSecs);
        imec_start_time = str2double(imec_data{s, ii}.firstSample)/str2double(imec_data{s, ii}.imSampRate);
        
        start_time_diff(s, ii) = nidq_start_time - imec_start_time;
        file_time_diff(s, ii) = nidq_file_dur - imec_file_dur;
    end

end

%% flag 

