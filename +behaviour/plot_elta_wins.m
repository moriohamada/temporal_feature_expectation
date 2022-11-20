function f = plot_elta_wins(eltas_win, conts, ops)
%%
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .1 .4]); hold on;

n_win = size(eltas_win{1},1);
win_col = [linspace(ops.colors.F_light(1), ops.colors.S_light(1), n_win)', ...
           linspace(ops.colors.F_light(2), ops.colors.S_light(2), n_win)', ...
           linspace(ops.colors.F_light(3), ops.colors.S_light(3), n_win)'];
n_mice = length(eltas_win);
% c_f = hot(n_mice+10);
% c_s = cool(n_mice+10);

t = linspace(-ops.tHistory, 0, 20*ops.tHistory);
t_scale = .25;
tf_scale = .05;
conts = conts(:,1);
eltas_wins_all = nan(n_win, n_mice, length(t));

for a = 1:n_mice
       
    for w = 1:n_win
       
        if w < median(1:n_win)
            per = 'E';
            pk_dir = 'F';
        elseif w > median(1:n_win)
            per = 'L';
            pk_dir = 'S';
        else
            pk_dir = '';
        end
        
        elta = smoothdata(eltas_win{a}(w,:), 'movmean',5);
        if pk_dir == 'F'
            [~, peak] = max(elta(10:end));
        elseif pk_dir == 'S'
            [~, peak] = min(elta(10:end));
        else 
            peak = 20;
        end
        col = win_col(w,:);
        if peak > 20 | peak < 11, peak = 20; end
        elta = elta - nanmean(elta(5:20));
        elta = elta(peak-10:peak+19);
        elta = smoothdata(elta, 'movmean', 2);
%         elta = elta(end-29:end);
        plot(t+(w-1)*t_scale, elta+(w-1)*tf_scale, 'Color', col);
        plot(t+(w-1)*t_scale, zeros(1,length(t))+(w-1)*tf_scale, 'Color', [.5 .5 .5], 'LineWidth', .5)
        
        eltas_wins_all(w, a, :) = elta;

    end
    
end

%% avg
win_col = [linspace(ops.colors.F(1), ops.colors.S(1), n_win)', ...
           linspace(ops.colors.F(2), ops.colors.S(2), n_win)', ...
           linspace(ops.colors.F(3), ops.colors.S(3), n_win)'];
       
for w = 1:n_win
   
    plot(t+(w-1)*t_scale, nanmean(squeeze(eltas_wins_all(w,:,:)),1)+(w-1)*tf_scale, ...
         'Color', win_col(w,:), 'LineWidth', 1.5)
     
end


set(gca, 'YColor', 'none', 'Xcolor', 'none')
xlim([-1.5 0+(w-1)*t_scale])
ylim([-.05 .1+(w-1)*tf_scale])
offsetAxes

end