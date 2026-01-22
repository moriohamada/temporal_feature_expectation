function plot_average_resps_by_tf_pref_by_subj(avg_resps, t_ax, indexes, ops)

% select only good units
multi = utils.get_multi(avg_resps, indexes);

rois = utils.group_rois;

[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);
[time_sensitive, time_pref] = utils.get_time_pref(indexes); 
% get units from eslf contingency animals
 avg_resps = utils.match_FS_sds(avg_resps, indexes);

%% Plot TF pulse and baseline firing by area

clrs = [ops.colors.S_pref; ops.colors.F_pref]; % slow, fast
 
evs = {'FexpF', 'FexpS', 'SexpF', 'SexpS'};
% set ylims
yls = [-.3 .3; -.3 .3;  -.6 .7];  

% loop through subjects
animals = {'MH_001', 'MH_002', 'MH_004', 'MH_006',  'MH_010', 'MH_011', ...
           'MH_015', 'MH_100', 'MH_103', 'MH_105', 'MH_111'};
for a = 5%:length(animals)
    this_animal = strcmp(indexes.animal, animals{a});
    for r = 2%1:height(rois)
        
        in_roi = utils.get_units_in_area(indexes.loc, rois{r,2}) & this_animal & ~multi;
        
        fast    = tf_pref>0 & tf_sensitive & in_roi ;
        slow    = tf_pref<0 & tf_sensitive & in_roi ;

        if sum(fast)<5 || sum(slow)<5

            continue
        end
        
        % label preferences: -1, 0, 1
        prefs = zeros(size(fast));
        prefs(fast) = 1;
        prefs(slow) = -1; 
         
        f = figure('Units', 'normalized', 'OuterPosition', [.1+r*.05 .1 .07 .25]);
        
        % loop through pref types
        for pref_i = [1, 2]
            
            sel = prefs == sign(pref_i-1.5);
            
            %% TF pulse responses
              
            for evi = 1:4
                ev = evs{evi};
                subplot(2,2,evi); hold on
            
                R = (avg_resps{sel, ev} - avg_resps{sel, 'FRmu'}) ./ avg_resps{sel, 'FRsd'}; 
                % R = utils.detrend_resp(R, isbetween(t_ax.tf, [-.5 -.1]), isbetween(t_ax.tf, [.7 1.2])); 
                R = smoothdata(R, 2, 'movmean', 1*[ops.spSmoothSize/ops.spBinWidth 0]);
     
                shadedErrorBar(t_ax.tf, R, {@mean @ci_95_magnitude}, ...
                               'lineprops', {'color', clrs(pref_i,:), 'linewidth', 1.5}); 
                xlim([-.2 1])
                ylim(yls(r,:))
            end 
        end 
        sgtitle(strrep(animals{a},'_',' '));
    end
    

end

end





