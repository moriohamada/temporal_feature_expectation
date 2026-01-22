function f = visualize_neurons_on_atlas(neuron_coords, highlight_regions, annotation_volume_path, structure_tree_path, preference, preference_colormap)
    % Visualize neurons overlaid on the Allen CCF atlas.
    % Inputs:
    %   neuron_coords: 3 x N array of neuron coordinates in micrometers (Allen CCF)
    %   highlight_regions: cell array of structures with fields:
    %       - 'regions': cell array of region names
    %       - 'color': RGB vector for the group color
    %   annotation_volume_path: file path to 'annotation_25.nrrd'
    %   structure_tree_path: file path to 'structure_tree_safe_2017.csv'
    %   preference: (Optional) 1 x N array of values to color neurons
    %   preference_colormap: (Optional) Colormap or cell array of colors for preferences

    % Load atlas data
    [av, voxel_size] = ccf_visual.load_annotation_volume(annotation_volume_path);

    % Load structure tree
    structure_tree = ccf_visual.load_structure_tree(structure_tree_path);

    % Map neuron coordinates to voxel indices
    [x_indices, y_indices, z_indices] = ccf_visual.coords_to_indices(neuron_coords, voxel_size, size(av));

    % Generate the visualization
    f = ccf_visual.create_visualization(neuron_coords, highlight_regions, av, voxel_size, structure_tree, preference, preference_colormap);
end
