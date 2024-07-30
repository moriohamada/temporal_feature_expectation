function proj = project_resps_onto_ax_nullSpace(resps, axes, mu, sd)
% 
% Create {n_ax x n_resp_field} table containing responses to every event projected onto axes in
% axes.
% 
% INPUTS
% 
%   resps
%       (nN x n_resp_field) table containing average responses to different events
% 
%   axes
%       (1 x 1) struct with n_ax fields - each a [nN x 1] vector
% 
% --------------------------------------------------------------------------------------------------
%%

ax_names = fields(axes)';
proj = struct;

for ax_i = 1:length(ax_names)
    ax_name = ax_names{ax_i};
    
    for r_i = 1:width(resps)
        if length(resps{1,r_i}) == 1 | ~strcmp(class(resps{1,r_i}), 'double')
            continue
        end
        this_resp = resps{:,r_i};
        this_resp = (this_resp - mu) ./ sd;
        this_resp(isnan(this_resp)) = 0;
        resp_name = resps.Properties.VariableNames{r_i};
        ax = axes.(ax_name)'/norm(axes.(ax_name)');
%         ax = axes.(ax_name)';
        
        proj.(ax_name).(resp_name) = smoothdata(ax * this_resp, 'movmean', 3*[5 0]);
    end

end

end