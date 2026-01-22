function values = get_peak_tf_values(data3D, peakTimes)
    [numRows, numCols, ~] = size(data3D);
    
    % Create the necessary indices
    [rowIndices, colIndices] = ndgrid(1:numRows, 1:numCols);
    
    % Expand peakTimes to match the dimensions
    depthIndices = repmat(peakTimes, 1, numCols);
    
    % Convert to linear indices
    linearIndices = sub2ind(size(data3D), rowIndices, colIndices, depthIndices);
    
    % Extract the values
    values = reshape(data3D(linearIndices), numRows, numCols);
end