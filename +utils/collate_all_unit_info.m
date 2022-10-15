function neuron_info = collate_all_unit_info(sessions, sp_all)
%%
neuron_info = table();

for s = 1:length(sessions)
    animal  = sessions(s).animal;
    session = sessions(s).session;
    cont    = sessions(s).contingency;
    
    
    if strcmp(session(1), 'h') % not recording session
        continue
    end
    
    sp = sp_all{s};
    
    cids = sp.cids;
    locs = sp.clu_locs';
    cgs  = sp.cgs';
    nN = length(cids);
    
    sess_info = table(repelem(animal, nN, 1), repelem(string(session), nN, 1), repelem(cont, nN, 1), ...
                      cids, locs, cgs, ...
                      'VariableNames', {'animal', 'session', 'cont', 'cid', 'loc', 'cg'});
                  
    if isempty(neuron_info)
        neuron_info = sess_info;
    else
        try
        neuron_info = [neuron_info; sess_info];
        catch 
            keyboard
        end
    end

end

end