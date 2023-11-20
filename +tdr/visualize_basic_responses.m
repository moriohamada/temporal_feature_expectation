function f = visualize_2d_activity(proj, t_ax, axes, evs, ops)
% Visualize activity projected along dimensions specified in 'axes'.
% keyboard
%%
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .05*size(evs,1) .25]);

%% Make 1D plots
for ii = 1:length(axes)
    
    ax_name = axes{ii};
    
    % Plot projs
    for jj = 1:size(evs,1)
        
        subplot(4, size(evs,1), jj + size(evs,1)*(ii-1)); 
        hold on
        for kk = 1:numel(evs{jj, 1})
            sm = smoothdata(proj.(ax_name).(evs{jj,1}{kk}), 'movmean', evs{jj,5}{1});
            plot(t_ax.(evs{jj, 2}{1}), sm, 'linewidth', 1.5, 'color', evs{jj, 3}{1}(kk,:))
        end
        xlim(evs{jj,4}{1});
        
    end

end
% keyboard

%% 2D plots

ax1 = axes{1};
ax2 = axes{2};

for ii = 1:size(evs,1)
    subplot(4, size(evs,1), ii + [size(evs,1)*2 size(evs,1)*3]); cla;
    for jj = 1:numel(evs{ii,1})
        hold on
        proj1 = smoothdata(proj.(ax1).(evs{ii,1}{jj}), 'movmean', evs{ii,8}{1});
        proj1 = proj1(isbetween(t_ax.(evs{ii, 2}{1}), evs{ii,6}{1}));
        proj2 = smoothdata(proj.(ax2).(evs{ii,1}{jj}), 'movmean', evs{ii,8}{1});
        proj2 = proj2(isbetween(t_ax.(evs{ii, 2}{1}), evs{ii,6}{1}));
        crop_t = t_ax.(evs{ii, 2}{1})(isbetween(t_ax.(evs{ii, 2}{1}), evs{ii,6}{1}));
        
        if isempty(evs{ii, 9})
            plot(proj1, proj2, 'linewidth', 2, 'color', evs{ii, 3}{1}(jj,:))
        else
            cmap = evs{ii,9}{1};
            for tt = 1:numel(crop_t)-1
                plot(proj1(tt:tt+1), proj2(tt:tt+1), 'color', cmap(tt,:), 'linewidth', 2);
            end
        end
        % scatter specified time points
        if isempty(evs{ii, 7})
            continue
        end
        tms = evs{ii, 7}{1};
        for tt = 1:length(tms)
            [~, tm] = min(abs(crop_t - tms(tt)));
            proj1_tm = proj1(tm);
            proj2_tm = proj2(tm);
            scatter(proj1_tm, proj2_tm, 25, 'o', 'filled', ...
                    'MarkerFaceColor', evs{ii, 3}{1}(jj,:))
        end
        
        
        % scatter zero point
        [~, t0] = min(abs(crop_t));
        proj1_t0 = proj1(t0);
        proj2_t0 = proj2(t0);
        if isempty(evs{ii, 9})
            scatter(proj1_t0, proj2_t0, 75, 'o', 'filled', ...
                    'MarkerFaceColor', evs{ii, 3}{1}(jj,:), 'MarkerEdgeColor', 'k')
        else
            continue
        end
        
        
        
    end
end
%%
% keyboard

end






