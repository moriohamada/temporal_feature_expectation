function resps = match_FS_sds(resps, indexes)


% match F/S sd per roi
[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);

fast = tf_pref>0 & tf_sensitive;
slow = tf_pref<0 & tf_sensitive;
multi = utils.get_multi(resps, indexes);
rois = utils.group_rois;

for r = 1:height(rois)
    
    in_roi = utils.get_units_in_area(resps.loc, rois{r,2});
    
    respsF = resps(fast & ~multi & in_roi,:);
    respsS = resps(slow & ~multi & in_roi,:); 

    psthF = nanmean((respsF.FexpF - respsF.SexpS)./respsF.FRsd, 1);
    psthS = nanmean((respsS.SexpS - respsS.FexpF)./respsS.FRsd, 1);
    
    gainF = range(psthF)/range(psthS);
    
    resps.FRsd(fast & ~multi & in_roi)= resps.FRsd(fast & ~multi & in_roi) * mean([gainF]);
    
end

end

