function structure_tree = load_structure_tree(structure_tree_path)
    % Load the structure tree CSV file.
    structure_tree = readtable(structure_tree_path, 'Delimiter', ',', 'PreserveVariableNames', true);
end
