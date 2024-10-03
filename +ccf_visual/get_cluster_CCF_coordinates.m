function xyz = get_cluster_CCF_coordinates(sp)
%%
cids = sp.cids;
xyz  = nan(length(cids), 3);
prN  = nan(length(cids), 1);
parfor ii = 1:length(cids)
    cid   = cids(ii);
    probe = floor(cid/10000);
    ch    = sp.clu_locs([sp.clu_locs.cid]==cid).ch;
    
    if max(cids) < 20000 % only one probe
        ch_loc = sp.ch_locs.(sprintf('channel_%d', ch));
    else
        ch_loc = sp.ch_locs{probe}.(sprintf('channel_%d', ch));
    end
    xyz(ii,:) = [ch_loc.x, ch_loc.y, ch_loc.z];
    prN(ii)   = probe;
end
% keyboard

pr1 = find(prN==1);
pr2 = find(prN==2);

if nanmean(xyz(pr1(end-5:end),1)) > 0
    xyz(pr1,1) = -1 * xyz(pr1,1);
end

if ~isempty(pr2)
    if nanmean(xyz(pr2(end-5:end),1)) > 0
        xyz(pr2,1) = -1 * xyz(pr2,1);
    end
end

end
