function visualize_basic_responses(tdr_ax, avg_resps, t_ax, glm_kernels, ops)
% 
% Visualize TF pulse responses, changes, and hit-aligned activity projected onto TDR axes
% 
% --------------------------------------------------------------------------------------------------

%% Get average responses of units with glm fits
resps_fitted = glm.keep_glm_fitted_units(avg_resps, glm_kernels);
multi = utils.get_multi(resps_fitted);

%% Plot activity by area
close all
rois = utils.group_rois;
ax2plot = {'tf', 'lick'};

for r = 3:height(rois)   
    roi = rois{r,1};
    in_roi = utils.get_units_in_area(resps_fitted.loc, rois{r,2}) & ~multi;
    in_roi_resps = resps_fitted(in_roi,:);
    proj = tdr.project_resps(tdr_ax.(roi), in_roi_resps, ax2plot);
    
    f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .2 .1*length(ax2plot)]);
    
    for axi = 1:length(ax2plot)
        
        ylmax = [inf -inf];
        
        ax = ax2plot{axi};
        
        %% tf pulses
        subplot(length(ax2plot), 3, 1 + (axi-1)*3); hold on;
        
        % Fast pulses
        Rf = (proj.(ax).FexpF + proj.(ax).FexpS)/2;
        Rf = utils.detrend_resp(Rf, isbetween(t_ax.tf, [-.5 -.2]), isbetween(t_ax.tf, [.7 1.2]));
        Rf = utils.remove_baseline(Rf, isbetween(t_ax.tf, ops.respWin.tfContext));
        plot(t_ax.tf, Rf, ...
             'linewidth', 2, 'color', ops.colors.F)
         
        % slow pulses
        Rs =  (proj.(ax).SexpF + proj.(ax).SexpS)/2;
        Rs = utils.detrend_resp(Rs, isbetween(t_ax.tf, [-.5 -.2]), isbetween(t_ax.tf, [.7 1.2]));
        Rs = utils.remove_baseline(Rs, isbetween(t_ax.tf, ops.respWin.tfContext));
        plot(t_ax.tf, Rs, ...
             'linewidth', 2, 'color', ops.colors.S)
        xlim([-.25 1])
        
        yl = ylim;
        ylmax = [min([yl(1), ylmax(1)]), max([yl(2), ylmax(2)])];
        
        %% changes
        subplot(length(ax2plot), 3, 2 + (axi-1)*3); hold on;
        
        clrs = create_custom_colormap(ops.colors.S, [.5 .5 .5], ops.colors.F, 7);
        
        for chi = [1 2 3 5 6 7]
           Rch = smoothdata(proj.(ax).(sprintf('hitE%d', chi)), 'movmean', 25);
           Rch = utils.remove_baseline(Rch, isbetween(t_ax.ch, [-1 0]));
           plot(t_ax.ch, Rch, 'linewidth', 1.5, 'color', clrs(chi,:));
        end
        
        xlim([-.5 1])
        yl = ylim;
        ylmax = [min([yl(1), ylmax(1)]), max([yl(2), ylmax(2)])];
        
        
        %% Hits
        subplot(length(ax2plot), 3, 3 + (axi-1)*3); hold on;
                
        for chi = [1 2 3 4 5 6 7]
           Rch = smoothdata(proj.(ax).(sprintf('hitLickE%d', chi)), 'movmean', 25);
           Rch = utils.remove_baseline(Rch, isbetween(t_ax.hit, [-2 -1]));
           plot(t_ax.hit, Rch, 'linewidth', 1.5, 'color', clrs(chi,:));
        end
        
        xlim([-1 .5])
        yl = ylim;
        ylmax = [min([yl(1), ylmax(1)]), max([yl(2), ylmax(2)])];
        
        %% Scale by max ylim
        
        subplot(length(ax2plot), 3, 1 + (axi-1)*3); 
        yl = ylim;
        ylim(mean(yl) + [-1, 1] * range(ylmax/20));
        
        for ii = 2:3
            subplot(length(ax2plot), 3, ii + (axi-1)*3);
            ylim( ylmax);
        end
    end
    
    
end



end
