function [sessions, trials_all, daq_all, sp_all] = ...
                            select_sessions_in_db(sessions, trials_all, daq_all, sp_all, db)

in_db = zeros(length(sessions),1);
for s = 1:length(sessions)
    animal  = sessions(s).animal;
    session = sessions(s).session;
    animal_id = find(strcmp(db.animals, animal));
    if ~isempty(animal_id)
        sess_id = find(strcmp(db.sessions{animal_id}, session));
        if ~isempty(sess_id)
            in_db(s) = 1;
        end
    end
end

% keyboard
                        
end