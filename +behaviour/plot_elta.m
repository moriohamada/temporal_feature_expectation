function f = plot_elta(eltas, ops)

%%
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .1 .2]); hold on;
n_mice = length(eltas)
c_f = hot(n_mice+15);
c_s = cool(n_mice+10);
t = linspace(-ops.tHistory, 0, 20*ops.tHistory);

elta_all_F = nan(length(eltas), length(t));
elta_all_S = nan(length(eltas), length(t));

test_peak_window_inds = [20:36];

peak_times = [];

for a = 1:length(eltas)
    

    % peak align
    elta_F = smoothdata([eltas(a).F, zeros(1,10)], 'movmean', 5);
    elta_S = smoothdata([eltas(a).S, zeros(1,10)], 'movmean', 5);
    % normalize to first .5s
    elta_F = elta_F - nanmean(elta_F(1:10));
    elta_S = elta_S - nanmean(elta_S(1:10));
    
%     [~, peak_F] = max(abs((elta_F(test_peak_window_inds))));
%     [~, peak_S] = max(abs((elta_S(test_peak_window_inds))));
% 
%     elta_F = elta_F(peak_F-20+test_peak_window_inds(1):peak_F+test_peak_window_inds(1)+9);
%     elta_S = elta_S(peak_S-20+test_peak_window_inds(1):peak_S+test_peak_window_inds(1)+9);
% 
% %     keyboard
%     % normalize to first .5s
%     elta_F = elta_F - nanmean(elta_F(1:10));
%     elta_S = elta_S - nanmean(elta_S(1:10));
% 
% %     elta_F = elta_F - (elta_F+elta_S)/2;
% %     elta_S = elta_S - (elta_F+elta_S)/2;

    plot(t,elta_F(11:end-10), 'color', c_f(a+5,:), 'LineWidth', .5);
    plot(t,elta_S(11:end-10), 'color', c_s(a+5,:), 'LineWidth', .5);
    elta_all_F(a,:) = elta_F(11:end-10);
    elta_all_S(a,:) = elta_S(11:end-10);
    
    % peak_times(end+1) = 40 - (mean([peak_F, peak_S]) + 25);
%     keyboard
    
end

% grand avg plot
plot(t, nanmean(elta_all_F,1), 'Color', ops.colors.F, 'LineWidth', 2)
plot(t, nanmean(elta_all_S,1), 'Color', ops.colors.S, 'LineWidth', 2)
yticks([-.05 0 .05 .1])
xlabel('Time before early lick (s)')
ylabel('\DeltaBaseline TF (Hz)')
offsetAxes
% peak_times
% fprintf('mean/sd peaks: %.5f, %.5f\n', mean(peak_times/20), std(peak_times/20))
end