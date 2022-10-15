function [sessions_all, trials_all, daq_all, good_units_all] = load_all_ephys_data(db, ops)
% 
% Load behavioural and neuropixels data from every session specified in db.
% 
% --------------------------------------------------------------------------------------------------

fprintf('\nLoading data from all sessions. This may take a while...\n')

% load from 
daq_all=[]; good_units_all=[];
ii = 1;
for a = 1:length(db.animals)
    
    animal   = db.animals{a};
    sessions = db.sessions{a};
    
    %% single unit analyses - psth/index calculations, session by session
    for s = 1:length(sessions)
        try
            session = sessions{s};
            session_file = fullfile(ops.dataDir, sprintf('%s_%s.mat', animal, session));
            
            if strcmp(session(1),'h')
                trials = loadVariable(session_file, 'trials');
                % get contingency
                all_changes = [trials.changeTF];
                early_exp   = strcmp({trials.trialType}, 'EarlyE');
                if mean(all_changes(early_exp)) < 2 % early slow
                    cont = 'ESLF';
                else
                    cont = 'EFLS';
                end
                trials = apply_tr_removal(trials, ops);
                sessions_all(ii,1).animal      = animal;
                sessions_all(ii,1).session     = session;
                sessions_all(ii,1).contingency = cont;
                trials_all{ii,1}               = trials;
                ii = ii + 1;
                fprintf('\tloaded data for %s_%s (%d/%d)\n', animal, session, s, length(sessions));
                continue
            end
            
            [trials, exp_settings, daq, sp] = ...
                loadVariables(session_file, 'trials', 'exp_settings', 'daq', 'sp');


            % remove trials too near start of sess/when mouse not behaving
            trials = apply_tr_removal(trials, ops);

            % select good units based on kilosort classification and stability
            good_units = select_good_units(sp, ops);
        
            % Also convert to nN x nT matrix and save
            if ops.saveFRmatrix
                [fr, t_ax] = spike_times_to_fr(sp, ops.spBinWidth);
                unit_info.cids = sort(sp.cids);
                unit_info.locs = {sp.clu_locs.brain_region};
                save(fullfile(ops.frDir, sprintf('%s_%s.mat', animal, session)), ...
                    'fr', 't_ax', 'ops', 'unit_info', '-v7.3');
            end
            clear sp
            
            % trim daq struct and trials
            daq    = remove_unnecessary_daq_fields(daq);
            
            % get contingency
            all_changes = [trials.changeTF];
            early_exp   = strcmp({trials.trialType}, 'EarlyE');
            if mean(all_changes(early_exp)) < 2 % early slow
                cont = 'ESLF';
            else
                cont = 'EFLS';
            end

            sessions_all(ii,1).animal      = animal;
            sessions_all(ii,1).session     = session;
            sessions_all(ii,1).contingency = cont;

            trials_all{ii,1}           = trials;
            daq_all{ii,1}              = daq;
            good_units_all{ii,1}       = good_units;

            clear trials daq good_units
            
            ii = ii + 1;

            fprintf('\tloaded data for %s_%s (%d/%d)\n', animal, session, s, length(sessions));

        catch me
            fprintf('\terror: unable to load data for %s_%s\n', animal, session);
            
        end
    end
    
end

fprintf('\tdata loaded.\n')

end