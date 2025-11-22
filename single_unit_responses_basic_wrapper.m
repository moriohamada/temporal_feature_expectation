function single_unit_responses_basic_wrapper(sessions, trials_all, daq_all, sp_all, ops)
% 
% run basic visualisations of single unit PSTHs
% 
% --------------------------------------------------------------------

fprintf('Plotting single unit PSTHs for every recording session\n')

n_sess = length(sessions);
animals = unique({sessions.animal});

for s = 1:n_sess

    fprintf('\tsession %d/%d\n', s, n_sess);

    if isempty(sp_all{s}) % not recording session
        continue
    end

    % get flip time
    flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');
    animal_id = find(strcmp(animals, sessions(s).animal));

    % get times of events of interest
    ev_times = utils.get_all_event_times(trials_all{s}, daq_all{s}, ops);

    % plot psths
    single_unit.single_unit_psths(ev_times, sp_all{s}, flip_times(animal_id), sessions(s), ops);

end

end