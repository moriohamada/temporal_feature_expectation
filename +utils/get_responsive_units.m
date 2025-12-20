function responsive = get_responsive_units(indexes)

ind_fields = fields(indexes);
ind_fields = ind_fields(contains(ind_fields, '_p') & ~contains(ind_fields, 'Exp') & ~contains(ind_fields, 'peak'));

ps = indexes(:, ind_fields);
n_sigs = sum(ps{:,:}<.01,2);

responsive = n_sigs >= 1;
end