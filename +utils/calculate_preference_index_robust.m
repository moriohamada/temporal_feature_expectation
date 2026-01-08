function [index, p] = calculate_preference_index_robust(resps1, resps2, nIter)
%  allows for negatives

nN = size(resps1,1);
index = zeros(nN,1);
p     = ones(nN,1);

parfor n = 1:nN
    norm = max([abs(mean(resps2(n,:))),  abs(mean(resps1(n,:)))]);
    if norm==0 | isnan(norm)
        continue
    end  
    index(n) = (mean(resps2(n,:)) - mean(resps1(n,:)))/(2*norm);
    [p(n), ~, ~] = utils.permutation_test_efficient(resps1(n,:), resps2(n,:), nIter);
end

end