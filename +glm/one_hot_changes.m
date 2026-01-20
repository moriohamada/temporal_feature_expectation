function features = one_hot_changes(features)
    tfch_vals = [features.TFch];
    unique_changes = unique(tfch_vals);
    
    for tr = 1:length(features)
        change_idx = features(tr).TFchOnset;
        trial_length = features(tr).duration;
        
        for ch_i = 1:length(unique_changes)
            field_name = sprintf('TFch_%d', (unique_changes(ch_i)+2)*100);
            
            if tfch_vals(tr) == unique_changes(ch_i) && ~isempty(change_idx) && change_idx <= trial_length
                features(tr).(field_name) = change_idx;  % scalar onset time
            else
                features(tr).(field_name) = [];  % empty = no event this trial
            end
        end
    end
    
    features = rmfield(features, 'TFch');
    features = rmfield(features, 'TFchOnset');
end