function f = plot_elta(eltas, ops)

%%
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .1 .2]); hold on;
n_mice = length(eltas);
c_f = hot(n_mice+25);
c_s = cool(n_mice+15);
t = linspace(-ops.tHistory, 0, 20*ops.tHistory);
% 
elta_all_F = nan(length(eltas), length(t));
elta_all_S = nan(length(eltas), length(t));

for a = 1:length(eltas)
    
    % peak align
    elta_F  = smoothdata(eltas(a).F, 'movmean', [3 3]);
    elta_S  = smoothdata(eltas(a).S, 'movmean', [3 3]);  

    % normalize to first .5s
    elta_F = elta_F(11:end) - nanmean(elta_F(1:10));
    elta_S = elta_S(11:end) - nanmean(elta_S(1:10));
    
    plot(t,elta_F, 'color', c_f(a+5,:), 'LineWidth', .5);
    plot(t,elta_S, 'color', c_s(a+5,:), 'LineWidth', .5);
    elta_all_F(a,:) = elta_F;
    elta_all_S(a,:) = elta_S;
 end

% grand avg plot
plot(t, nanmean(elta_all_F,1), 'Color', ops.colors.F, 'LineWidth', 2)
plot(t, nanmean(elta_all_S,1), 'Color', ops.colors.S, 'LineWidth', 2)
yticks([-.05 0 .05 .1])
xlabel('Time before early lick (s)')
ylabel('\DeltaBaseline TF (Hz)')
offsetAxes

end