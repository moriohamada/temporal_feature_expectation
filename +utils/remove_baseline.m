function X = remove_baseline(X, inds, norm)

if nargin<3
    norm=0;
end
if norm
    X = (X - nanmean(X(:, inds),2))./nanstd(X(:, inds),[],2);
else
    X = X - nanmean(X(:, inds),2);
end

end