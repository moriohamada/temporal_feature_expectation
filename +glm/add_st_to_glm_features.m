function features = add_st_to_glm_features(features, trStarts, st, ops)

for tr = 1:length(trStarts)
    tr_start = trStarts(tr);
    dur = features(tr).duration;
    
    t_ax = tr_start:ops.tBin:(tr_start+ops.tBin*dur-ops.tBin);
    
    if length(t_ax)~=dur, keyboard; end
     
    % spike counts
    this_tr_st = (st(tr_start < st & st < t_ax(end)) - tr_start) / ops.tBin;
    features(tr).SpTrain = this_tr_st;
    
    
end

end