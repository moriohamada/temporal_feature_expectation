function [index, p] = calculate_preference_index(resps1, resps2, nIter)
% resps1 and 2 should be nN x nEvents


nN = size(resps1,1);
index = zeros(nN,1);
p     = ones(nN,1);


parfor (n = 1:nN, 3)
    norm = (mean(resps2(n,:)) + mean(resps1(n,:)));
    if norm==0
        continue
    end
    index(n) = (mean(resps2(n,:)) - mean(resps1(n,:))) / norm;
    [p(n), ~, ~] = permutationTest(resps1(n,:), resps2(n,:), nIter);
end

end