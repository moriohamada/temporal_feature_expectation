function neuron_region_names = map_region_ids_to_names(structure_tree, neuron_region_ids)
    % Map region IDs to region names.
    [~, idx] = ismember(neuron_region_ids, structure_tree.id);
    neuron_region_names = structure_tree.name(idx);
end
