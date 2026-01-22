function filtered = keep_glm_fitted_units(original, glm_kernels)
% FILTERUNITSWITHGLMFITS Filters the avg_resps table to keep only units
% that have corresponding entries in the glm_kernels table
%
% Inputs:
%   original    - avg_resps or indexes: table containing response/preference data for all units
%   glm_kernels - Table containing GLM kernels for a subset of units
%
% Output:
%   filtered - filtered table with only units having GLM fits

% Create a logical index for matching units
match_idx = false(height(original), 1);

% Loop through each row in avg_resps
for ii = 1:height(original)
    % Get the identifying info for this unit
    curr_animal = original.animal{ii};
    curr_session = original.session{ii};
    curr_cid = original.cid(ii);
    
    % Check if this unit exists in glm_kernels
    unit_exists = any(strcmp(glm_kernels.animal, curr_animal) & ...
                      strcmp(glm_kernels.session, curr_session) & ...
                      glm_kernels.cid == curr_cid);
    
    % Mark as true if the unit exists in glm_kernels
    match_idx(ii) = unit_exists;
end

% Filter the avg_resps table using the logical index
filtered = original(match_idx, :);
 
end