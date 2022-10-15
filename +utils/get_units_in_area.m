function units_in_area = get_units_in_area(locs, areas)

units_in_area = zeros(length(locs),1);

for a = 1:length(areas)
    in_sub_area = strcmp(locs, areas{a});
    units_in_area = units_in_area + in_sub_area;
end


end