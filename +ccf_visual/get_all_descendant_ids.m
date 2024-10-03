function descendant_ids = get_all_descendant_ids(structure_tree, region_name)
    % Get IDs of the specified region and all its descendants.
    idx = strcmp(structure_tree.acronym, region_name);
    if ~any(idx)
        descendant_ids = [];
        return;
    end
    parent_id = structure_tree.id(idx);

    % Get all descendant IDs
    descendant_mask = contains(structure_tree.structure_id_path, ['/' num2str(parent_id) '/']) | ...
                      (structure_tree.id == parent_id);
    descendant_ids = structure_tree.id(descendant_mask);
end
