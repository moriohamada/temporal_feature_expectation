% Define your areas of interest and their possible names in the 'loc' column
areaDefinitions = struct();
areaDefinitions.MOs = {'MOs1', 'MOs2/3', 'MOs5', 'MOs6a', 'MOs6b'};
areaDefinitions.CP = {'CP'};
areaDefinitions.HVA= {'VISa1', 'VISa2/3', 'VISa4', 'VISa5', 'VISa6a', 'VISa6b', ...
             'VISrl1', 'VISrl2/3', 'VISrl4', 'VISrl5', 'VISrl6a', 'VISrl6b', ...
             'VISam1', 'VISam2/3', 'VISam4', 'VISam5', 'VISam6a', 'VISam6b', ...
             'VISpm1', 'VISpm2/3', 'VISpm4', 'VISpm5', 'VISpm6a', 'VISpm6b',   ...
             'RSPagl1', 'RSPagl2/3', 'RSPagl5', 'RSPagl6a','RSPagl6b', ...
             'RSPd1', 'RSPd2/3', 'RSPd5', 'RSPd6a','RSPd6b', ...
             'RSPv1', 'RSPv2/3', 'RSPv5', 'RSPv6a','RSPv6b' };
areaDefinitions.V1 =  {'VISp1','VISp2/3','VISp4', 'VISp5','VISp6a', 'VISp6b'};
areaDefinitions.VisTh =  {'LGd', 'LP'};

multi = utils.get_multi(avg_resps, indexes);
dataset = indexes(~multi,:);
[tf_sensitive, tf_pref] = utils.get_tf_pref(dataset);

tf_sensitive = (abs(indexes.tf_z_peakF)>2.58 | abs(indexes.tf_z_peakS)>2.58) & ...
                indexes.tf_short_p<.05 & ...
                 sign(indexes.tf_short)==sign(indexes.tf_z_peakD);
% Get unique animal-session combinations
[uniqueCombos, ~, groupIdx] = unique(dataset(:, {'animal', 'session'}), 'rows');

% Initialize result table
areaNames = fieldnames(areaDefinitions);
numAreas = length(areaNames);
numGroups = height(uniqueCombos);

% Initialize data matrices
resultData = zeros(numGroups, numAreas);
resultDataTfSens = zeros(numGroups, numAreas);

% Count neurons for each area in each session
for i = 1:numGroups
    % Get neurons for this animal-session combination
    sessionIdx = (groupIdx == i);
    sessionLocs = dataset.loc(sessionIdx);
    sessionTfSens = tf_sensitive(sessionIdx);
    
    % Count neurons for each area of interest
    for j = 1:numAreas
        areaName = areaNames{j};
        possibleNames = areaDefinitions.(areaName);
        
        % Check which neurons belong to this area
        isInArea = false(length(sessionLocs), 1);
        for k = 1:length(possibleNames)
            isInArea = isInArea | contains(sessionLocs, possibleNames{k});
        end
        
        % Total count for this area
        resultData(i, j) = sum(isInArea);
        
        % Count tf_sensitive neurons in this area
        resultDataTfSens(i, j) = sum(isInArea & sessionTfSens);
    end
end

% Calculate percentages for each session (avoid divide by zero)
resultDataPct = zeros(size(resultData));
for i = 1:numGroups
    for j = 1:numAreas
        if resultData(i, j) > 0
            resultDataPct(i, j) = 100 * resultDataTfSens(i, j) / resultData(i, j);
        else
            resultDataPct(i, j) = 0;
        end
    end
end

% Create column names and data
colNames = {};
colData = [];
for j = 1:numAreas
    colNames{end+1} = ['nN_' areaNames{j}];
    colNames{end+1} = ['nN_' areaNames{j} '_tfSens'];
    colNames{end+1} = ['pct_' areaNames{j} '_tfSens'];
    colData = [colData, resultData(:,j), resultDataTfSens(:,j), resultDataPct(:,j)];
end

% Create the main table
resultTable = [uniqueCombos, array2table(colData, 'VariableNames', colNames)];

% Calculate summary row (sum across all sessions)
summaryRow = table();
summaryRow.animal = {'ALL'};
summaryRow.session = {'SUMMARY'};

% Sum columns and calculate percentages for summary
summaryData = [];
for j = 1:numAreas
    areaTotal = sum(resultData(:,j));
    areaTfSens = sum(resultDataTfSens(:,j));
    
    % Calculate overall percentage
    if areaTotal > 0
        areaPct = areaTfSens / areaTotal;
    else
        areaPct = 0;
    end
    areaPct = round(areaPct, 3);
    summaryData = [summaryData, areaTotal, areaTfSens, areaPct];
end

% Add data to summary row
summaryRow = [summaryRow, array2table(summaryData, 'VariableNames', colNames)];

% Add summary row to the bottom
resultTable = [resultTable; summaryRow];

% Display result
disp(resultTable);
writetable(resultTable, 'neuron_counts_by_session_tf.xlsx');