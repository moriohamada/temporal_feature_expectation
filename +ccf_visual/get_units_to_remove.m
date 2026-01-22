function rmv = get_units_to_remove(sp, sp_ref)

rmv = ~ismember(sp.cids, sp_ref.cids);




end