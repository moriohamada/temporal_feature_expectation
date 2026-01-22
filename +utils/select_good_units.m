function good_units = select_good_units(sp, ops)


stable_clu = utils.find_stable_clusters(sp, ops);

if ops.suOnly
    good_clu = sp.cids(sp.cgs==2 & stable_clu);
else
    good_clu = sp.cids(stable_clu);
end

good_units.clu       = sp.clu(ismember(sp.clu, good_clu));
good_units.st        = sp.st(ismember(sp.clu, good_clu));
good_units.cids      = sort(unique(good_units.clu));
good_units.cgs       = sp.cgs(ismember(sp.cids, good_clu));

% may already have processed to good_units - in this case getting location is simply
if iscell(sp.clu_locs)
    cid_idx = find(ismember(sp.cids, good_units.cids));
    good_units.clu_locs = sp.clu_locs(cid_idx);
else
    try
        % get locations
        cids_all      = [sp.clu_locs.cid];
        all_locations = {sp.clu_locs.brain_region};

        good_unit_loc = all_locations(ismember(cids_all, good_units.cids));

        good_units.clu_locs  = good_unit_loc;
    catch
        keyboard
    end
end

end