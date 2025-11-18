%% correct spike times based on file time discrepancy
%  run meta_file_checker.m first to get discrepancies
%%
for s = 1:length(sessions)
    animal  = sessions(s).animal;
    session = sessions(s).session;

    
    sp = sp_all{s};

    if isempty(sp)
        continue
    end

    if isfield(sp, 'st_correction')
        continue
    end

    for ii = 1:2
        delta = round(file_time_diff(s, ii));
        if isnan(delta) | delta==0
            continue
        end
        % adjust spike times for correct cids
        rel_spx = isbetween(sp.clu, [ii*10000, (ii+1)*10000]);
        sp.st(rel_spx) = sp.st(rel_spx) + delta;
    end
    sp.st_correction = 'file_time_diff';
    data_file = fullfile(ops.dataDir, sprintf('%s_%s.mat', animal, session));
    save(data_file, 'sp', '-append');
    sp_all{s} = sp;
    
end