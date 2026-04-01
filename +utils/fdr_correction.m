function corrected_p = fdr_correction(p_values)
% SEQUENTIAL_BONFERRONI Performs sequential Bonferroni (Holm) correction
%
% Input:
%   p_values - Vector of p-values from hypothesis tests
%
% Output:
%   corrected_p - Sequentially corrected p-values

% Ensure p_values is a column vector
p_values = p_values(:);
m = length(p_values);

% Sort p-values in ascending order
[sorted_p, original_idx] = sort(p_values);

% Initialize adjusted p-values array
adjusted_p = zeros(size(sorted_p));

% Apply sequential correction: 
for i = 1:m
    adjusted_p(i) = sorted_p(i) * i;
end

% Enforce monotonicity (working from smallest to largest p-value)
for i = 2:m
    adjusted_p(i) = max(adjusted_p(i), adjusted_p(i-1));
end

% Map back to original order
corrected_p = zeros(size(p_values));
for i = 1:m
    corrected_p(original_idx(i)) = adjusted_p(i);
end

% Cap values at 1
corrected_p = min(corrected_p, 1);
end
