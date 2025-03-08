function [x_indices, y_indices, z_indices] = coords_to_indices(neuron_coords, voxel_size, volume_size)
    % Convert neuron coordinates to voxel indices.
    % Inputs:
    %   neuron_coords: 3 x N array of neuron coordinates in micrometers.
    %   voxel_size: voxel size in micrometers.
    %   volume_size: size of the annotation volume.
    % Outputs:
    %   x_indices, y_indices, z_indices: arrays of voxel indices.

    % Convert coordinates to voxel indices
    x_indices = round(neuron_coords(1, :) / voxel_size);
    y_indices = round(neuron_coords(2, :) / voxel_size);
    z_indices = round(neuron_coords(3, :) / voxel_size);

    % Ensure indices are within bounds
%     x_indices = max(min(x_indices, volume_size(1)), 1);
%     y_indices = max(min(y_indices, volume_size(2)), 1);
%     z_indices = max(min(z_indices, volume_size(3)), 1);
end
