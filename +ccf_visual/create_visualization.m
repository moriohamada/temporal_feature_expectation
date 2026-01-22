function f = create_visualization(neuron_coords, highlight_regions, av, voxel_size, structure_tree, preference, preference_colormap)
    % Create the 3D visualization with enhanced features.
    % Includes downsampling for performance improvement.

    % Downsample the annotation volume
    downsample_factor = 10;  % Adjust this factor as needed for performance
    av_downsampled = av(1:downsample_factor:end, 1:downsample_factor:end, 1:downsample_factor:end);
    voxel_size_downsampled = voxel_size * downsample_factor;

    f = figure('Units', 'normalized', 'OuterPosition', [.3 .1 .15 .2]);
    hold on;

    % Plot neurons
    if nargin < 6 || isempty(preference)
        % No preference provided; use a default color
        scatter3(neuron_coords(1, :), neuron_coords(2, :), neuron_coords(3, :), 3, 'filled', 'MarkerFaceColor', 'k');
    else
        % Normalize preference values or map to discrete colors
        preference = preference(:)';  % Ensure it's a row vector

        % Plot neurons with colors based on preference
        non_pref = preference == 0;
        scatter3(neuron_coords(1, non_pref), neuron_coords(2, non_pref), neuron_coords(3, non_pref), 3,...
                 preference(non_pref), 'filled', 'MarkerFaceAlpha', .2);
        scatter3(neuron_coords(1, ~non_pref), neuron_coords(2, ~non_pref), neuron_coords(3, ~non_pref), 3,...
                 preference(~non_pref), 'filled', 'MarkerFaceAlpha', 1);
        c_limits = prctile(preference, [5 95]);
        caxis([-1 1] .* max(abs(c_limits)));
        colormap(preference_colormap);
        %colorbar;
    end

    % Highlight specified regions
%     figure; hold on
    for i = 1:length(highlight_regions)
        group = highlight_regions{i};
        regions = {group.regions};
        group_color = group.color;

        % Collect all descendant IDs for the group
        group_region_ids = [];
        for j = 1:length(regions)
            region_name = regions{j};
            region_ids = ccf_visual.get_all_descendant_ids(structure_tree, region_name);
            if isempty(region_ids)
                warning('Region "%s" not found in the structure tree.', region_name);
                continue;
            end
            group_region_ids = [group_region_ids; region_ids];
        end
        group_region_ids = unique(group_region_ids);

        % Create a binary mask for the group using downsampled volume
        region_mask = ismember(av_downsampled, group_region_ids);

        % Generate isosurface mesh
        fv = isosurface(region_mask, 0.5);
        fv = reducepatch(fv, 0.05);  % Reduce mesh complexity

        if isempty(fv.vertices)
            warning('No mesh generated for group %d.', i);
            continue;
        end

        % Plot the mesh with specified color
        patch('Vertices', fv.vertices * voxel_size_downsampled, 'Faces', fv.faces, ...
              'FaceColor', group_color, 'EdgeColor', 'none', 'FaceAlpha', 0.2);
    end

    % Optionally, plot the brain outline
    % Create a mask for the entire brain
    brain_mask = av_downsampled > 0;
    brain_fv = isosurface(brain_mask, 0.5);
    brain_fv = reducepatch(brain_fv, 0.05);  % Reduce mesh complexity

    % Plot the brain outline
    patch('Vertices', brain_fv.vertices * voxel_size_downsampled, 'Faces', brain_fv.faces, ...
          'FaceColor', [0.9, 0.9, 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

    % Adjust plot settings
    xlabel('DV (µm)');
    ylabel('AP (µm)');
    zlabel('ML (µm)');
    axis vis3d equal;
    view([90 90]);
    camorbit(0, 40, 'data', [0 1 0])
    camorbit(-30, 0, 'data', [1 0 0])
    
%     keyboard
    set(gcf, 'Renderer', 'OpenGL');
    set(gca, 'Xcolor', 'none', 'Ycolor', 'none', 'zcolor', 'none')
    hold off;
end
