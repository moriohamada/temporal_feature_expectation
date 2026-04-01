function [peakVals, peakTimes] = findFirstAbsPeaks(X)
% X: nN x nT
% use find peaks toolbox
[numRows, ~] = size(X);
peakVals  = zeros(numRows, 1);
peakTimes = zeros(numRows, 1);

for n = 1:numRows
    absRow = abs(X(n, :));
    [val, locs] = findpeaks(absRow);

    if ~isempty(locs)
        peakTimes(n) = locs(1);
        val = val(1);
    else
        % Handle case when findpeaks doesn't find any peaks
        [val, maxIdx] = max(absRow);
        peakTimes(n) = maxIdx(1);
    end

    peakVals(n) = val * sign(X(n, peakTimes(n)));
end
end
