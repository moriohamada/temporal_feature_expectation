function single_unit_responses_basic_wrapper(sessions, trials_all, daq_all, sp_all, ops)
% 
% Wrapper function for basic single unit analyse, including:
% 
% - PSTHs/Rasters for every unit - separately and sumamries across areas
% - Calculate 'tuning curves' for time
% - Calculate TF tuning curves as function for time
% 
% Does not include analyses looking at relationships bettween different stimulus/task dimensions
% etc - rather just runs analyses to visualize how responses look across different areas.
% 
% --------------------------------------------------------------------------------------------------

%% Single unit PSTHs for each session

fprintf('Plotting single unit PSTHs for every recording session\n')
n_sess = length(sessions);
animals = unique({sessions.animal});

for s = 1:n_sess
    try
        fprintf('\tsession %d/%d\n', s, n_sess);

        if isempty(sp_all{s}) % not recording session
            continue
        end

        % get flip time
        flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');
        animal_id = find(strcmp(animals, sessions(s).animal));

        % get times of events of interest
        ev_times = get_event_times(trials_all{s}, daq_all{s}, ops);


        % plot psths
        single_unit_psths(ev_times, sp_all{s}, flip_times(animal_id), sessions(s), ops);
        % single_unit_psths(ev_times, sp_all{s}, 6.5, sessions(s), ops);
    catch me
        keyboard
        fprintf('failed...\n')
    end
end

fprintf('\tdone.\n')




end