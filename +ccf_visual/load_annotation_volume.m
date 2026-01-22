function [av, voxel_size] = load_annotation_volume(annotation_volume_path)
    % Load the Allen CCF annotation volume from the specified path.
    % Outputs:
    %   av: 3D annotation volume.
    %   voxel_size: size of each voxel in micrometers.

    % Read the NRRD file using nrrdread
    [av, meta] = nrrdread(annotation_volume_path);

    % Extract voxel size from metadata (if available)
    if isfield(meta, 'spacedirections')
        voxel_sizes = diag(meta.spacedirections);
        voxel_size = abs(voxel_sizes(1));  % Convert from meters to micrometers
    else
        % Default voxel size (for 25 µm resolution)
        voxel_size = 25;  % micrometers
    end
end
