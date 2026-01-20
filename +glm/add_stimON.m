function features = add_stimON(features)
% Add baseline and change on regressors (TF-independent features
% indicating when baseline stimulus/change stimulus are on).


for tr = 1:length(features)
    features(tr).BaselineStimOn = ...
        double(logical(features(tr).TFbl_f + features(tr).TFbl_s));
    features(tr).ChangeStimOn = ...
        double(~features(tr).BaselineStimOn);

end