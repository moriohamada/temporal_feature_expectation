function features = one_hot_outcomes(features)

% One-hot encode trialOutcome
outcomes = {features.trialOutcome}';  % extract as cell array of strings
outcome_types = {'Miss', 'Hit', 'FA', 'abort'};

for i = 1:length(outcome_types)
    onehot = strcmp(outcomes, outcome_types{i});
    onehot_cell = num2cell(onehot);
    [features.(sprintf('outcome_%s', outcome_types{i}))] = onehot_cell{:};
end

features = rmfield(features, 'trialOutcome');
end