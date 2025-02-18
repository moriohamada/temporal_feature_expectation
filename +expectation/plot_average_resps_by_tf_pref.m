function plot_average_resps_by_tf_pref(avg_resps, t_ax, indexes, ops)

% select only good units
multi = utils.get_multi(avg_resps, indexes);

rois = utils.group_rois;

[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);
[time_sensitive, time_pref] = utils.get_time_pref(indexes); 
% get units from eslf contingency animals
eslf =  indexes.conts==-1;
avg_resps = utils.match_FS_sds(avg_resps, indexes);

%% Plot TF pulse and baseline firing by area

clrs = [ops.colors.S_pref; ops.colors.F_pref]; % slow, fast
 
flip_time = [0 0 0]; % set to 1 to flip time, or 0 to flip TF

evs = {'FexpF', 'FexpS', 'SexpF', 'SexpS'};

% set ylims
yls = [-.3 .3; -.15 .25;  -.6 .7];  

for r = 1:height(rois)
    
    in_roi = utils.get_units_in_area(indexes.loc, rois{r,2}) & ~multi;
    
    fast    = tf_pref>0 & tf_sensitive & in_roi;
    slow    = tf_pref<0 & tf_sensitive & in_roi;
    
    % label preferences: -1, 0, 1
    prefs = zeros(size(fast));
    prefs(fast) = 1;
    prefs(slow) = -1; 
    
    % flip TF preference as needed if not flipping time
    % if ~flip_time(r)
    %     prefs(eslf) = -1*prefs(eslf);
    % end
     
    f = figure('Units', 'normalized', 'OuterPosition', [.1+r*.05 .1 .07 .25]);
    
    % loop through pref types
    for pref_i = [1, 2]
        
        sel = prefs == sign(pref_i-1.5);

        %% Baseline activity
        
        subplot(3, 2, [1 2]); hold on
        R = (avg_resps{sel, 'bl'} - avg_resps{sel, 'FRmu'}) ./ avg_resps{sel, 'FRsd'};
        % R = (R - mean(R(:, isbetween(t_ax.bl, [2 10])),2)) ;
        R = R(:, isbetween(t_ax.bl, [-1 11]));

        if flip_time(r)
            R(eslf(sel), :) = -(R(eslf(sel), :));
        end
        R = smoothdata(R, 2, 'movmean', 5*ops.spSmoothSize/ops.spBinWidth);
        shadedErrorBar(t_ax.bl(isbetween(t_ax.bl, [-1 11])), R, {@nanmean @ci_95_magnitude}, ...
                       'lineprops', {'color', clrs(pref_i,:), 'linewidth', 1.5});
                   
        xlim([0 10])
        
        %% TF pulse responses
          
        for evi = 1:4
            ev = evs{evi};
            subplot(3,2,2+evi); hold on
        
            R = (avg_resps{sel, ev} - avg_resps{sel, 'FRmu'}) ./ avg_resps{sel, 'FRsd'}; 
            R = smoothdata(R, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth]);
            R = utils.detrend_resp(R, isbetween(t_ax.tf, [-.5 -.1]), isbetween(t_ax.tf, [.7 1.2])); 

            % if ~flip_time(r)
            %     R(eslf(sel),:) = -1*R(eslf(sel),:);
            % end
            shadedErrorBar(t_ax.tf, R, {@nanmean @ci_95_magnitude}, ...
                           'lineprops', {'color', clrs(pref_i,:), 'linewidth', 1.5}); 
%             plot(t_ax.tf, R','color', clrs(pref_i,:));
            xlim([-.2 1])          
            ylim(yls(r,:))
        end 
    end 
    if ops.saveFigs
        save_figures_multi_format(f, fullfile(ops.saveDir, 'expectation', ['avg_tf_responses_', rois{r,1}]), {'fig', 'svg', 'png'})
    end
end

end





