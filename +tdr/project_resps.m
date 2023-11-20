function proj = project_resps_onto_ax(resps, axes, normalize)
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
resp_names = fields(resps);

if nargin<3 | isempty(normalize)
    normalize = false;
end

for ax_i = 1:length(ax_names)
    ax_name = ax_names{ax_i};
    
    for r_i = 1:width(resps)
        if length(resps{1,r_i}) == 1 | ~strcmp(class(resps{1,r_i}), 'double')
            continue
        end
        this_resp = resps{:,r_i};
        
        if normalize
            this_resp = (this_resp - [resps.FRmu]) ./ [resps.FRsd];
%             this_resp = (this_resp - [resps.FRmu]) ;
%             this_resp = (this_resp) ./ [resps.FRsd];
        end
        
        this_resp(isnan(this_resp)) = 0;
        resp_name = resps.Properties.VariableNames{r_i};
        ax = axes.(ax_name)'/norm(axes.(ax_name)');
%         ax = axes.(ax_name)';
        
        proj.(ax_name).(resp_name) = ax * this_resp;
        
        if contains(resp_name, {'FexpF', 'FexpS', 'SexpF', 'SexpS', 'F', 'S'})
            t = linspace(-.5, 1.5, 200);
            proj.(ax_name).(resp_name) = detrend_resp(proj.(ax_name).(resp_name), ...
                                                      isbetween(t, [-.4 -.05]), ...
                                                      isbetween(t, [.7 1.2]));
        end
        proj.(ax_name).(resp_name) = smoothdata(proj.(ax_name).(resp_name), 'gaussian', 5*5);
    end
    

end

end