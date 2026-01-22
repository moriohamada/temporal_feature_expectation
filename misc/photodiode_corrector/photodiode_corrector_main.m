%% re-check nidaq frame times trial-by-trial. 
% Run GUI to load raw photodiode trace, label extracted frame times,
% and correct or discard as needed (mark frames as nan).
% After running on a session, a field will be added to the 'daq' 
% struct in preprocessed data: 'photodiode_checked', as well as 
% 'frame_times_tr_checked', containing extracted (possibly unchanged)
% frame times for each trial. 

%%
% specify paths
paths.npxDir = '/mnt/ceph/public/projects/MoHa_20201102_SwitchChangeDetection/npx/';
paths.preprocessedDir = '/media/morio/Data_Fast/switch_task_revisions/session_data/';
paths.photodiodeData = '/media/morio/Data_Fast/switch_task_revisions/photodiode_data/';

% specify data with ephys
db.animals  = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_010', 'MH_011', 'MH_015', ...
               'MH_100', 'MH_103', 'MH_105', 'MH_110', 'MH_111'};
db.sessions = {{'e1', 'e2', 'e3', 'e4', 'e5', 'e8'}, ...                   % MH_001
               {'e1', 'e2', 'e3'}, ...                                     % MH_002 
               {'e1','e2','e3','e4', 'e6','e7','e8','e9'}, ...             % MH_004
               {'e2','e3','e4','e5','e6', 'e7','e8'}, ...                  % MH_006
               {'e1','e2','e3', 'e5','e6'}, ...                            % MH_010
               {'e1', 'e2', 'e3', 'e4'}, ...                               % MH_011
               {'e1', 'e2', 'e3',  'e5', 'e6'}, ...                        % MH_015
               {'e2', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9', 'e10'}, ...      % MH_100
               {'e1', 'e2', 'e3', 'e4', 'e5'}, ...                         % MH_103
               {'e2', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9'}, ...             % MH_105
               {'e1', 'e2', 'e5', 'e6', 'e7','e8', 'e9', 'e10', 'e11'},... % MH_110
               {'e1','e2','e3','e4','e5', 'e7','e8','e9'}};                % MH_111


% first prepare data: extract trial-by-trial photodiode signals and
% get extracted times
extract_raw_photodiode_signal(paths, db);

%% Run gui

photodiodeCheckerGUI(paths.photodiodeData)
