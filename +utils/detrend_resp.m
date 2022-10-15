function X_detrended = detrend_resp(X, start_inds, end_inds)
%  remove linear baseline change

X_start = nanmean(X(:,start_inds),2);
X_end   = nanmean(X(:,end_inds),2);

delta = X_end - X_start;
slope = delta/(mean(find(end_inds)) - mean(find(start_inds)));

steps = 0:size(X,2)-1;
X_trend = slope * steps; 

X_detrended = X - X_trend;

end