function sp_all = remove_nonROI_units(sp_all)
% Remove data from units not in any region of interest, for saving ram space


all_rois = utils.get_all_rois();

if iscell(sp_all) % then multiple sessions
    n_sessions = length(sp_all);

    for s = 1:n_sessions
        sp = sp_all{s};

        if isempty(sp)
            continue
        end

        is_roi = ismember(sp.clu_locs, all_rois);
        spx_to_keep = ismember(sp.clu, sp.cids(is_roi));

        sp.clu = sp.clu(spx_to_keep);
        sp.st  = sp.st(spx_to_keep);
        sp.cids = sp.cids(is_roi);
        sp.cgs = sp.cgs(is_roi);
        sp.clu_locs = sp.clu_locs(is_roi);

        sp_all{s} = sp;

        clear sp;
    end
elseif isstruct(sp_all)
    sp = sp_all;

    if iscell(sp.clu_locs)
        is_roi = ismember(sp.clu_locs, all_rois);
    else
        is_roi = ismember({sp.clu_locs.brain_region}, all_rois);
    end
    spx_to_keep = ismember(sp.clu, sp.cids(is_roi));

    sp.clu = sp.clu(spx_to_keep);
    sp.st  = sp.st(spx_to_keep);
    sp.cids = sp.cids(is_roi);
    sp.cgs = sp.cgs(is_roi);
    sp.clu_locs = sp.clu_locs(is_roi);

    sp_all = sp;
end
end