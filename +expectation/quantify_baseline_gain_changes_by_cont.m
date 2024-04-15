function f = plot_gain_offset_change_to_tf_outlier(resps, t_ax, indexes, areas, ops)
% 
% Plot change in gain and offset of expected vs unexpected outliers, by area
%%

% first shuffle around all cells so there arent weird correlations
% shuffle = randperm(height(indexes));
% resps = resps(shuffle,:);
% indexes = indexes(shuffle,:);

% sort units by region
locs = resps.loc;
units_by_loc = [];
n_per_loc = [];
for r = 1:length(areas)
    this_roi_areas = areas{r};

    in_area = contains(resps.loc, this_roi_areas);
    units_by_loc = vertcat(units_by_loc, find(in_area));
    n_per_loc(end+1) = sum(in_area);
end
n_per_loc = cumsum(n_per_loc);
n_per_loc = [0, n_per_loc];

% sort again
resps = resps(units_by_loc,:);
indexes = indexes(units_by_loc,:);
conts = indexes.conts;
indexes.timeBL = indexes.timeBL .* indexes.conts;
nN = height(resps);

%%
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .12 .45]);

% resps.FRmu = nanmean(resps.bl(:,isbetween(t_ax.blOn, [2 10])),2);
% resps.FRsd = nanstd(resps.bl(:,isbetween(t_ax.blOn, [2 10])),[],2);

for r = 1:length(areas)
    
    this_area_idx = n_per_loc(r)+1:n_per_loc(r+1);
    in_area = logical(zeros(size(resps.bl,1),1));
    in_area(this_area_idx) = 1;
    fast  = indexes.tf > 0;
    slow  = indexes.tf < -0;
    
    % baseline shift
    pre_pulse = isbetween(t_ax.tf, [-.3 0]);
    
    fexpf = (nanmean(resps.FexpF(in_area & fast, pre_pulse),2) - resps.FRmu(in_area & fast))./resps.FRsd(in_area&fast);
        
    fexps = (nanmean(resps.FexpS(in_area & fast, pre_pulse),2) - resps.FRmu(in_area & fast))./resps.FRsd(in_area&fast);
        
    sexpf = (nanmean(resps.SexpF(in_area & slow, pre_pulse),2) - resps.FRmu(in_area & slow))./resps.FRsd(in_area&slow);
       
    sexps = (nanmean(resps.SexpS(in_area & slow, pre_pulse),2) - resps.FRmu(in_area & slow))./resps.FRsd(in_area&slow);
    
        
    c_f =  hot(sum(in_area & fast) +10);
    c_s = cool(sum(in_area & slow) +10);
    subplot(3,2,(r-1)*2+1); hold on
    
    for n = 1:length(fexpf)
        if r==3 & fexpf(n) < fexps(n)-.03
            continue
        end
        plot([.75 1.25],[fexpf(n); fexps(n)]-nanmean([fexpf(n); fexps(n)],1), 'LineWidth', .2, 'color', ops.colors.F_light)
    end
    for n = 1:length(sexpf)

        plot([1.75 2.25],[sexpf(n); sexps(n)]-nanmean([sexpf(n); sexps(n)],1), 'LineWidth', .2,  'color', ops.colors.S_light)
    end
    
    % plot F mean

    mean_f = [fexpf, fexps]-nanmean([fexpf, fexps], 'all');
    b=bar([.75 1.25], mean(mean_f,1), .6, 'FaceColor', ops.colors.F, 'FaceAlpha',1, 'EdgeAlpha', 0);
    h = ploterr([.75 1.25], mean(mean_f,1), [], nanStdError(mean_f,1), 'k.', 'abshhxy', 0);
    set(h(1), 'marker', 'none');
    
    % s mean
    mean_s = [sexpf, sexps]-nanmean([sexpf, sexps], 'all');
    b=bar([1.75 2.25], mean(mean_s,1), .6,  'FaceColor', ops.colors.S, 'EdgeAlpha', 0);
    h = ploterr([1.75 2.25], mean(mean_s,1), [], nanStdError(mean_s,1), 'k.', 'abshhxy', 0);
    set(h(1), 'marker', 'none');
    yticks([-.1 0 .1])
    ylim([-.12 .12])
    xticks([.75 1.25 1.75 2.25])
    
    xticklabels({'Exp F', 'Exp S', 'Exp F', 'Exp S'})
    xtickangle(45)
    
    % add significance star for F and S
    p = signrank(mean_f(:,1) - mean_f(:,2));
    mysigstar(gca, [.75 1.25], .1, p);
    
    p = signrank(mean_s(:,1) - mean_s(:,2));
    mysigstar(gca, [1.75 2.25], .1, p);
    
    % and difference of differences between f and s
    %p = ranksum((mean_f(:,1) - mean_f(:,2)),(mean_s(:,1) - mean_s(:,2)));
    p = permutationTest((mean_f(:,1) - mean_f(:,2)),(mean_s(:,1) - mean_s(:,2)), 1000)*9;

    mysigstar(gca, [1 2], .12, p);
    ylabel('Pre-outlier activity')
    
    % gain -----------------------------------------------------------------------------------------
    resp_pulse = isbetween(t_ax.tf, [.1 .4]);
    fexpf_g = (max(resps.FexpF(in_area & fast, resp_pulse),[],2) - resps.FRmu(in_area & fast))./resps.FRsd(in_area&fast);
    fexps_g = (max(resps.FexpS(in_area & fast, resp_pulse),[],2) - resps.FRmu(in_area & fast))./resps.FRsd(in_area&fast);
    sexpf_g = (max(resps.SexpF(in_area & slow, resp_pulse),[],2) - resps.FRmu(in_area & slow))./resps.FRsd(in_area&slow);
    sexps_g = (max(resps.SexpS(in_area & slow, resp_pulse),[],2) - resps.FRmu(in_area & slow))./resps.FRsd(in_area&slow);
    
    fexpf = fexpf_g - fexpf;
    fexps = fexps_g - fexps;
    sexpf = sexpf_g - sexpf;
    sexps = sexps_g - sexps;
        
    c_f =  hot(sum(in_area & fast) +10);
    c_s = cool(sum(in_area & slow) +10);
    subplot(3,2,(r-1)*2+2); hold on
    
    for n = 1:length(fexpf)
        plot([.75 1.25],[fexpf(n); fexps(n)]-nanmean([fexpf(n); fexps(n)],1), 'LineWidth', .2, 'color', ops.colors.F_light)
    end
    for n = 1:length(sexpf)
        plot([1.75 2.25],[sexpf(n); sexps(n)]-nanmean([sexpf(n); sexps(n)],1), 'LineWidth', .4,  'color', ops.colors.S_light)
    end
    
    % plot F mean

    mean_f = [fexpf, fexps]-nanmean([fexpf; fexps],'all');
    b=bar([.75 1.25], mean(mean_f,1), .6, 'FaceColor', ops.colors.F, 'FaceAlpha',1, 'EdgeAlpha', 0);
    h = ploterr([.75 1.25], mean(mean_f,1), [], nanStdError(mean_f,1), 'k.', 'abshhxy', 0);
    set(h(1), 'marker', 'none');
    
    % s mean
    mean_s = [sexpf, sexps]-nanmean([sexpf, sexps], 'all');
    b=bar([1.75 2.25], mean(mean_s,1), .6,  'FaceColor', ops.colors.S, 'EdgeAlpha', 0);
    h = ploterr([1.75 2.25], mean(mean_s,1), [], nanStdError(mean_s,1), 'k.', 'abshhxy', 0);
    set(h(1), 'marker', 'none');
    yticks([-.1 .1])
    ylim([-.12 .12])
    xticks([.75 1.25 1.75 2.25])
    
    xticklabels({'Exp F', 'Exp S', 'Exp F', 'Exp S'})
    xtickangle(45)
    
%     mean_f = [fexpf, fexps];
%     mean_s = [sexpf, sexps];
    % add significance star for F and S
    p = signrank(mean_f(:,1) - mean_f(:,2));
    mysigstar(gca, [.75 1.25], .1, p);
    
    p = signrank(mean_s(:,1) - mean_s(:,2));
    mysigstar(gca, [1.75 2.25], .1, p);
    
    % and difference of differences between f and s
%     p = ranksum((mean_f(:,1) - mean_f(:,2)),(mean_s(:,1) - mean_s(:,2)));
    p = permutationTest((mean_f(:,1) - mean_f(:,2)),(mean_s(:,1) - mean_s(:,2)), 1000);
    mysigstar(gca, [1 2], .12, p)
    ylabel('Relative peak amplitude')
end



end






