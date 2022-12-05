function f = plot_pref_indexes(indexes, ops)

indexes_to_plot = {'timeBL', 'tf'};
cols = {{ops.colors.E, ops.colors.L}, {ops.colors.S, ops.colors.F}};
sig_tf = sign(indexes.tfExpF)==sign(indexes.tfExpS) & (indexes.tfExpF_p<sqrt(.05) & indexes.tfExpS_p<sqrt(.05));
sig_time = sign(indexes.timeBL)==sign(indexes.timePreTF) & (indexes.timeBL_p<sqrt(.05) & indexes.timePreTF_p<sqrt(.05));
%%
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .2*length(indexes_to_plot)/3 .15]); hold on;

for ii = 1:length(indexes_to_plot)
    
    subplot(1,length(indexes_to_plot), ii)
    hold on
    ind = indexes_to_plot{ii};
    idx = table2array(indexes(:,ind));
    histogram(idx, [-.6:.05:.6], 'EdgeAlpha',0,'FaceColor', [.5 .5 .5]);
    
    % plot sig
    if ii==1, sig = sig_time; elseif ii==2, sig=sig_tf; end
    sig_low  = sig & idx<0;
    sig_high = sig & idx>0;
%     sig_low  = indexes.(strcat(ind, '_p')) < 0.05 & idx<0;
%     sig_high = indexes.(strcat(ind, '_p')) < 0.05 & idx>0;
    histogram(idx(sig_low), [-.6:.05:.6], 'EdgeAlpha',0,'FaceColor', cols{ii}{1});
    histogram(idx(sig_high), [-.6:.05:.6], 'EdgeAlpha',0,'FaceColor', cols{ii}{2});
    
    n_sig = sum(sig_high + sig_low);
    title(sprintf('%d/%d (%.1f%s)', n_sig, length(idx), n_sig/length(idx)*100, '%'), 'FontSize', 8, 'FontWeight', 'normal')
    xlabel(ind);
    set(gca, 'box', 'off')
end


end