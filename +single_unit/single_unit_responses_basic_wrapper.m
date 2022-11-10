% function single_unit_select_responses_basic_wrapper(sessions, trials_all, daq_all, sp_all, units, ops)
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
    
    fprintf('\tsession %d/%d\n', s, n_sess);

    if isempty(sp_all{s}) % not recording session
        continue
    end
    
    animal = sessions(s).animal;
    session = sessions(s).session;
    this_sess_units = contains(units(:,1), animal) & contains(units(:,2),session);
    if sum(this_sess_units)==0
        continue
    end
    
    % get cids in this session
    cids = sort(cell2mat(units(this_sess_units, 3)));
    sp = sp_all{s};
    
    unit_idx = ismember(sp.cids, cids);
    sp.cids = cids;
    sp.st = sp.st(ismember(sp.clu, cids));
    sp.clu = sp.clu(ismember(sp.clu, cids));
    sp.cgs = sp.cgs(unit_idx);
    sp.clu_locs = sp.clu_locs(unit_idx);
    
    % get flip time
    flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');
    animal_id = find(strcmp(animals, sessions(s).animal));
    
    % get times of events of interest
    ev_times = get_event_times(trials_all{s}, daq_all{s}, ops);
    
    
    % plot psths
    single_unit_psths(ev_times, sp, flip_times(animal_id), sessions(s), ops);
    
end

fprintf('\tdone.\n')




end