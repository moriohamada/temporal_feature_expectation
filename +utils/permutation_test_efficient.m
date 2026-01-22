function [p, observeddifference, effectsize] = permutation_test_efficient(sample1, sample2, permutations, varargin)
% permutationTest - Fast implementation of permutation test for difference in means
%                   with early stopping option and parallel processing
%
% Usage:
%   [p, observeddifference, effectsize] = permutationTest(sample1, sample2, permutations, ...)
%
% Required inputs:
%   sample1 - vector of measurements from first sample
%   sample2 - vector of measurements from second sample
%   permutations - maximum number of permutations to perform
%
% Optional name-value pairs:
%   'useparallel' - whether to use parallel processing for remaining iterations (0|1, default 0)
%   'earlyStop' - number of permutations to check for early stopping (0 = disabled, default 0)
%   'earlyStopThreshold' - p-value threshold for early stopping (default 0.1)

% Parse inputs
p = inputParser;
addRequired(p, 'sample1', @isnumeric);
addRequired(p, 'sample2', @isnumeric);
addRequired(p, 'permutations', @isnumeric);
addParameter(p, 'useparallel', 0, @isnumeric);
addParameter(p, 'earlyStop', 100, @isnumeric);
addParameter(p, 'earlyStopThreshold', 0.2, @isnumeric);
parse(p, sample1, sample2, permutations, varargin{:});

sample1 = p.Results.sample1(:)'; % Force row vector
sample2 = p.Results.sample2(:)'; % Force row vector
permutations = p.Results.permutations;
useparallel = p.Results.useparallel;
earlyStop = p.Results.earlyStop;
earlyStopThreshold = p.Results.earlyStopThreshold;

% Validate early stopping parameters
if earlyStop > permutations
    earlyStop = permutations;
elseif earlyStop == 0
    earlyStop = permutations; % No early stopping
end

% Combine samples
n1 = length(sample1);
allobservations = [sample1, sample2];
ntotal = length(allobservations);

% Calculate observed difference and effect size
observeddifference = mean(sample1) - mean(sample2);
pooledstd = sqrt(((n1-1)*var(sample1) + (length(sample2)-1)*var(sample2)) / (ntotal-2));
effectsize = observeddifference / pooledstd;

% Pre-allocate random differences array
randomdifferences = zeros(1, permutations);

% Two-phase approach: first sequential for early stopping, then parallel if needed
% Phase 1: Run initial batch sequentially and check for early stopping
earlyStopBatchSize = min(earlyStop, permutations);

for i = 1:earlyStopBatchSize
    % Generate random permutation
    permutation = randperm(ntotal);
    
    % Split into samples and calculate difference
    randomSample1 = allobservations(permutation(1:n1));
    randomSample2 = allobservations(permutation(n1+1:end));
    
    randomdifferences(i) = mean(randomSample1) - mean(randomSample2);
end

% Check if we should stop early
currentP = (sum(abs(randomdifferences(1:earlyStopBatchSize)) >= abs(observeddifference)) + 1) / (earlyStopBatchSize + 1);
totalPermutations = earlyStopBatchSize;

% Phase 2: If not stopping early and more permutations needed, run remaining permutations
if currentP <= earlyStopThreshold && earlyStopBatchSize < permutations
    remainingPermutations = permutations - earlyStopBatchSize;
    
    % Use parallel processing for remaining iterations if enabled
    if useparallel && remainingPermutations > 1000
        parRemainingDiffs = zeros(1, remainingPermutations);
        
        parfor j = 1:remainingPermutations
            % Generate random permutation
            permutation = randperm(ntotal);
            
            % Split into samples and calculate difference
            randomSample1 = allobservations(permutation(1:n1));
            randomSample2 = allobservations(permutation(n1+1:end));
            
            parRemainingDiffs(j) = mean(randomSample1) - mean(randomSample2);
        end
        
        randomdifferences(earlyStopBatchSize+1:permutations) = parRemainingDiffs;
        totalPermutations = permutations;
    else
        % Sequential processing for remaining iterations
        for j = 1:remainingPermutations
            i = earlyStopBatchSize + j;
            
            % Generate random permutation
            permutation = randperm(ntotal);
            
            % Split into samples and calculate difference
            randomSample1 = allobservations(permutation(1:n1));
            randomSample2 = allobservations(permutation(n1+1:end));
            
            randomdifferences(i) = mean(randomSample1) - mean(randomSample2);
        end
        
        totalPermutations = permutations;
    end
end

% Calculate final p-value based on all permutations performed
p = (sum(abs(randomdifferences(1:totalPermutations)) >= abs(observeddifference)) + 1) / (totalPermutations + 1);

end