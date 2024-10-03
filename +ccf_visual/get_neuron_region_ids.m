function neuron_region_ids = get_neuron_region_ids(av, x_indices, y_indices, z_indices)
    % Get region IDs for each neuron based on voxel indices.
    linear_indices = sub2ind(size(av), x_indices, y_indices, z_indices);
    neuron_region_ids = av(linear_indices);
end
