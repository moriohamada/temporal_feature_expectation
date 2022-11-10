function single_unit_psths(ev_times, sp, flip_time, session_info, ops)
% 
% Calculate PSTHs for every unit, generate plots, and return an (n_units x 1) struct containing
% responses of every unit to events specified in ev_times
% 
% --------------------------------------------------------------------------------------------------

%%
nN = length(sp.cids);

animal = session_info.animal;
session = session_info.session;
cont = session_info.contingency;

% save_folder = fullfile(ops.saveDir, 'singleUnitExamples', 'PSTHs', animal, session);
save_folder = fullfile(ops.saveDir, 'PSTHs_ks4_adjRecStart_goodTrials', animal, session);

if ~exist(save_folder, 'dir'), mkdir(save_folder); end
set(0, 'DefaultFigureVisible', 'Off')

unit_types = {'multi', 'single'};

% reselect units for plotting
ops.minFR = .5; 
ops.minFRDrop = .1;
stable_clu = find_stable_clusters(sp, ops);
%%
for n = 1:nN
    try
        cid = sp.cids(n);
        try
            loc = sp.clu_locs{n};
        catch
            sp.clu_locs(n).brain_region;
        end
        cg  = sp.cgs(n);

        % remove delimiters from loc
        loc = strrep(loc, '/', '-');
        
        if ~ops.plotMultiUnits & cg == 1
            continue
        end
        
        if ~stable_clu(n)
            continue
        end

        st  = sp.st(sp.clu == cid);
        
        if flip_time > 8, flip_time = 8; end

        f = plot_single_unit_psths(ev_times, st, flip_time, ops);
        sgtitle(sprintf('%s, %s (%s), %sunit cid:%d, %s', ...
                        animal, session, cont, unit_types{cg}, cid, loc), ...
                        'interpreter', 'none', 'horizontalAlignment', 'left')

        save_path = fullfile(save_folder, sprintf('%s_%s_%s_cid%d_%s', animal, session, unit_types{cg}, cid, loc));
%         saveas(f, save_path);
        saveas(f, save_path, 'png');
%         saveas(f, save_path, 'svg');
%         keyboard
        close (f)
    % catch me
    %     keyboard    
    end
    if mod(n,50)==0
        fprintf('\t\tunit %d/%d\n', n, nN);
    end
end
set(0, 'DefaultFigureVisible', 'On')

end


