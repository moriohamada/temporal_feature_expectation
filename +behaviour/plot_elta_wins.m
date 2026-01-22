function f = plot_elta_wins(eltas_win,  ops)
%%

%%
n_win = size(eltas_win{1},1);

f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .08*n_win .2]); 

win_col = [linspace(ops.colors.F_light(1), ops.colors.S_light(1), n_win)', ...
           linspace(ops.colors.F_light(2), ops.colors.S_light(2), n_win)', ...
           linspace(ops.colors.F_light(3), ops.colors.S_light(3), n_win)'];
n_mice = length(eltas_win);

t = linspace(-ops.tHistory, 0, 20*ops.tHistory);

eltas_wins_all = nan(n_win, n_mice, length(t));

for a = 1:n_mice
       
    for w = 1:n_win
        
        subplot(1,n_win,w); hold on;
        
        elta = smoothdata(eltas_win{a}(w,:), 'movmean',5);
        [~, peak] = max(abs(elta(10:end)));
        col = win_col(w,:);
        if peak > 20 | peak < 10, peak = 20; end
        elta = elta - nanmean(elta(1:20));
        elta = elta(peak-10:peak+19);
        elta = smoothdata(elta, 'movmean', 2);
        eltas_wins_all(w, a, :) = elta;
        

    end
    
end

%% avg
win_col = [linspace(ops.colors.F(1), ops.colors.S(1), n_win)', ...
           linspace(ops.colors.F(2), ops.colors.S(2), n_win)', ...
           linspace(ops.colors.F(3), ops.colors.S(3), n_win)'];
       
for w = 1:n_win
    subplot(1,n_win,w); hold on; 
    plot(t, squeeze(eltas_wins_all(w,:,:)), 'color', win_col(w,:), 'linewidth', .5);
    plot(t, nanmean(squeeze(eltas_wins_all(w,:,:)),1), 'color', win_col(w,:), 'linewidth', 2);
    
    xlim([-1.5 0])
    ylim([-.06 .1])
    yticks([-.05 0 .05 .1])
    offsetAxes

end


end