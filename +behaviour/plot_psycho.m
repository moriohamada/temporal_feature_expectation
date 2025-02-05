function f=plot_psycho(psycho, chrono, ops)
%% 

f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .21 .3]);

exp_c = [0 0 0];
uex_c = [.5 .5 .5];

psycho = psycho(~cellfun('isempty', psycho)); 

% grand avg
psychos_all = cell2mat(vertcat(psycho'));
psychos_all_exp = psychos_all(2:3:end,:);
psychos_all_uex = psychos_all(3:3:end,:);

chronos_all = cell2mat(vertcat(chrono'));
chronos_all_exp = chronos_all(2:3:end,:);
chronos_all_uex = chronos_all(3:3:end,:);

% psycho
h_p = subplot(2,4,[1 2]); hold on;
errorbar(psychos_all(1,:)-2, nanmean(psychos_all_exp,1), nanStdError(psychos_all_exp,1), 'Color', exp_c, 'CapSize', 0)
plot(psychos_all(1,:)-2, nanmean(psychos_all_exp,1),  '-o', 'MarkerFaceColor', exp_c, 'Color', exp_c, 'LineWidth', 1.5, 'MarkerSize', 5);
errorbar(psychos_all(1,:)-2, nanmean(psychos_all_uex,1), nanStdError(psychos_all_uex,1), 'Color', uex_c, 'CapSize', 0)
plot(psychos_all(1,:)-2, nanmean(psychos_all_uex,1),  '-o', 'MarkerFaceColor', uex_c, 'Color', uex_c, 'LineWidth', 1.5, 'MarkerSize', 5);
xlabel('Change magnitude (Hz)')
ylabel('P(Hit)')
offsetAxes(h_p)
xlim([-2 2]); xticks([-2:2]); xticklabels({'-2','','0','','2'});

% chrono_s
h_c = subplot(2,4,[3 4]); hold on;
errorbar(chronos_all(1,:)-2, nanmean(chronos_all_exp,1), nanStdError(chronos_all_exp,1), 'Color', exp_c, 'CapSize', 0)
plot(chronos_all(1,:)-2, nanmean(chronos_all_exp,1),  '-o', 'MarkerFaceColor', exp_c, 'Color', exp_c, 'LineWidth', 1.5, 'MarkerSize', 5);
errorbar(chronos_all(1,:)-2, nanmean(chronos_all_uex,1), nanStdError(chronos_all_uex,1), 'Color', uex_c, 'CapSize', 0)
plot(chronos_all(1,:)-2, nanmean(chronos_all_uex,1),  '-o', 'MarkerFaceColor', uex_c, 'Color', uex_c, 'LineWidth', 1.5, 'MarkerSize', 5);
xlabel('Change magnitude (Hz)')
ylabel('Reaction time (s)')

offsetAxes(h_c)
xlim([-2 2]); xticks([-2:2]); xticklabels({'-2','','0','','2'});
 

%% insets for ex vs uex
psycho_small_S = [psychos_all_exp(:,3), psychos_all_uex(:,3)]; 
psycho_small_F = [psychos_all_exp(:,5), psychos_all_uex(:,5)]; 
psycho_small = (psycho_small_S + psycho_small_F) / 2;

subplot(2,4,5); cla; hold on
% for a = 1:size(psycho_small,1)
    plot([1 2], psycho_small', 'LineWidth', .5);
% end
plot([1 2], nanmean(psycho_small,1), 'color', 'k', 'LineWidth', 2)
ylim([0 1])

[h,p] = ttest(psycho_small(:,1) - psycho_small(:,2));
sym = get_sig_symbol(p);
plot_diff_sig(gca, sym, [1 2]);
xticks([1 2])
ylim([0 1.05])
xticklabels({'Exp', 'Uex'})
set(gca, 'box', 'off')
offsetAxes

chrono_small_S = [chronos_all_exp(:,3), chronos_all_uex(:,3)]; 
chrono_small_F = [chronos_all_exp(:,5), chronos_all_uex(:,5)]; 
% keyboard
chrono_small = nanmean(cat(3,chrono_small_S, chrono_small_F),3);
subplot(2,4,7); 
hold on
% for a = 1:size(chrono_small,1)
    plot([1 2], chrono_small', 'LineWidth', .5);
% end
plot([1 2], nanmean(chrono_small,1), 'color', 'k', 'LineWidth', 2)
ylim([0 1])

[h,p] = ttest(chrono_small(:,1) - chrono_small(:,2));
sym = get_sig_symbol(p);
ylim([.5 1.5])
plot_diff_sig(gca, sym, [1 2]);
xticks([1 2])
ylim([.5 1.55])
xticklabels({'Exp', 'Uex'})
set(gca, 'box', 'off')

offsetAxes
 
end