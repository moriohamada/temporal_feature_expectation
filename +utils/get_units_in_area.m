function units_in_area = get_units_in_area(locs, areas)
locs = locs(:); % for column
units_in_area = zeros(length(locs),1);

for a = 1:length(areas)
    in_sub_area = strcmp(locs, areas{a});
    units_in_area = units_in_area + in_sub_area;
end

units_in_area = logical(units_in_area);
end