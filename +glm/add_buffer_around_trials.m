function features = add_buffer_around_trials(features, glm_ops)
%
% Offset event times by glm_ops.aroundTrial * glm_ops.tBin, and add
% zeros before and after continuous signals/spike trains.



offset = glm_ops.preTrial / glm_ops.tBin;  % time to add

% Extend duration 
temp = num2cell([features.duration] + offset);
[features.duration] = temp{:};

% Get all fields except duration
vars = fieldnames(features);
vars = vars(~strcmp(vars, 'duration'));
% vars = vars(~contains(vars, 'outcome'));

for v = 1:numel(vars)
    varName = vars{v};
    for i = 1:numel(features)
        val = features(i).(varName);
        
        if isscalar(val)
            % Timestamp: shift forward by offset
            features(i).(varName) = val + offset;
        elseif length(val)>1
            % Continuous signal: pad with zeros
            if isrow(val)
                features(i).(varName) = [zeros(1, offset), val];
            else
                features(i).(varName) = [zeros(offset, 1); val];
            end
        end
    end
end


end