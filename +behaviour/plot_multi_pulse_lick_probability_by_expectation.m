function [f, f_step] = plot_multi_pulse_lick_probability_by_expectation(p_lick_single, p_lick_double, p_lick_single_FS, p_lick_double_FS, bins, ops)

nA = length(p_lick_single);
[nW, nD] = size(p_lick_double{1}, [1 2]);

min_animals = 3; % only take data where there is data from at least this many animals

[~, zero_ind] = min(abs(bins));

% set smoothing
sigma = length(bins)/10;
kernel_size = 2*sigma;
kernel = fspecial('gaussian', [kernel_size kernel_size], sigma);

delay = 1;
f=figure('Units', 'normalized', 'OuterPosition', [.1 .1 .55 .4]);

outlier_thresh = .25;
bin_S = bins<=-outlier_thresh; %isbetween(bins, [-.5 -.25]);%
bin_F = bins>=outlier_thresh; %isbetween(bins, [.25 .5]);%

% bin_S = isbetween(bins, [-.5 -.25]);%
% bin_F = isbetween(bins, [.25 .5]);%
bin_0 = isbetween(bins, [-.25 .25]);

normalize_rel_lickP = false;
%%
% Full trial
psycho_1           = nan(nA, length(bins));
psycho_2           = nan(nA, length(bins), length(bins));
psycho_1_normed    = nan(nA, length(bins));
psycho_2_normed    = nan(nA, length(bins), length(bins));
psycho_ind  = nan(nA, length(bins), length(bins));
psycho_diff = nan(nA, length(bins), length(bins));
w=1;
for a = 1:nA
    
    % get single pulse psycho
    p_lick_1 = squeeze(p_lick_single{a}(w,:));
    p_lick_1_normed = p_lick_1 - nanmean(p_lick_1(bin_0));
    p_lick_1_normed = smoothdata(p_lick_1_normed, 1,'gaussian', 6*sigma);
    
    % get two-pulse psycho
    p_lick_2 = squeeze(p_lick_double{a}(w,delay,:,:));
    p_lick_2_normed = p_lick_2 - nanmean(p_lick_2(bin_0,bin_0),'all');
    p_lick_2_normed = nanconv(p_lick_2_normed, kernel, 'conv', 'nanout');
    %         p_lick_2 = imgaussfilt(p_lick_2, 6*sigma);
    %         p_lick_2 = imfilter(p_lick_2, kernel,  'same');
    % get independent
    p_lick_ind = 1 - (1-p_lick_1_normed)' * (1-p_lick_1_normed);
    
    % difference
    p_lick_diff = p_lick_2_normed - p_lick_ind;
    p_lick_diff = nanconv(p_lick_diff, kernel, 'conv', 'nanout');
    %         p_lick_diff = imgaussfilt(p_lick_diff, sigma);
    
    psycho_1(a,:) = p_lick_1;
    psycho_2(a,:,:) = p_lick_2;
    psycho_1_normed(a,:) = p_lick_1_normed;
    psycho_2_normed(a,:,:) = p_lick_2_normed;
    psycho_ind(a,:,:) = p_lick_ind;
    psycho_diff(a,:,:) = p_lick_diff;
    
end

% plot single pulse psycho
subplot(2,6,1)
shadedErrorBar(bins, nanmean_min_count(psycho_1_normed, min_animals, 1), ci_95_magnitude(psycho_1_normed,1), ...
    'lineprops', {'Color', 'k', 'linewidth', 2});

% 2 pulse psycho
subplot(2,6,2)
avg = squeeze(nanmean_min_count(psycho_2_normed, min_animals, 1));
imAlpha = ones(size(avg));
imAlpha(isnan(avg))=0;
imagesc(bins, bins, avg, 'AlphaData', imAlpha);
colormap(ops.colors.heatmap)
set(gca, 'Ydir', 'normal', 'box', 'off')
cb=colorbar;
cb.Location = 'east';
cb.YAxisLocation = 'right';
clim = caxis;
cb.Position(1) = cb.Position(1)+.01;
cb.Position(3) = cb.Position(3)*.5;
caxis([clim(1) .4*clim(2)])
%     caxis([0 8]*1e-3);

% ind
subplot(2,6,5)
avg = squeeze(nanmean_min_count(psycho_ind, min_animals, 1));
imAlpha = ones(size(avg));
imAlpha(isnan(avg))=0;
imagesc(bins, bins, avg, 'AlphaData', imAlpha);
set(gca, 'Ydir', 'normal', 'box', 'off')
cb=colorbar;
cb.Location = 'east';
cb.YAxisLocation = 'right';
clim = caxis;
cb.Position(1) = cb.Position(1)+.01;
cb.Position(3) = cb.Position(3)*.5;
cb.TickDirection = 'in'; clim = caxis;
%caxis([-max(abs(clim)) max(abs(clim))])

% diff
subplot(2,6,6)
avg = squeeze(nanmean_min_count(psycho_diff, min_animals, 1));
imAlpha = ones(size(avg));
imAlpha(isnan(avg))=0;
imagesc(bins, bins, avg, 'AlphaData', imAlpha);
set(gca, 'Ydir', 'normal', 'box', 'off')
cb=colorbar;
cb.Location = 'east';
cb.YAxisLocation = 'right';
clim = caxis;
cb.Position(1) = cb.Position(1)+.01;
cb.Position(3) = cb.Position(3)*.5;
cb.TickDirection = 'out';clim = caxis;
caxis([-max(abs(clim)) max(abs(clim))]*.3)
%     caxis([-4 4]*1e-3);
colormap(ops.colors.heatmap)
% keyboard

%% expF, expS
[nW, nD] = size(p_lick_double_FS{1}, [1 2]);
psycho_1_FS ={};
psycho_2_FS ={};
for w = 1:nW
    
    % set smoothing
    sigma = length(bins)/10;
    kernel_size = 2*sigma;
    kernel = fspecial('gaussian', [kernel_size kernel_size], sigma*w);
    
    for a = 1:nA
        
        % get single pulse psycho
        p_lick_1 = squeeze(p_lick_single_FS{a}(w,:));
        p_lick_1 = p_lick_1 - nanmean(p_lick_1(bin_0));
        p_lick_1 = smoothdata(p_lick_1, 1,'gaussian', 6*sigma);
        
        % get two-pulse psycho
        p_lick_2 = squeeze(p_lick_double_FS{a}(w,delay,:,:));
        p_lick_2 = p_lick_2 - nanmean(p_lick_2(bin_0,bin_0),'all');
        p_lick_2 = nanconv(p_lick_2, kernel, 'conv', 'nanout');
        
        psycho_1_FS{w}(a,:) = p_lick_1;
        psycho_2_FS{w}(a,:,:) = p_lick_2;
        
%         psycho_1_FS{w}(a,:) = log(p_lick_1./(1-p_lick_1));
%         psycho_2_FS{w}(a,:,:) = log(p_lick_2./(1-p_lick_2));
        
    end
    
    
    % 2 pulse psycho
    subplot(2,6,2+w)
    avg = squeeze(nanmean_min_count(psycho_2_FS{w}, min_animals, 1));
    imAlpha = ones(size(avg));
    imAlpha(isnan(avg))=0;
    imagesc(bins, bins, avg, 'AlphaData', imAlpha);
    set(gca, 'Ydir', 'normal', 'box', 'off')
    cb=colorbar;
    cb.Location = 'east';
    cb.YAxisLocation = 'right';
    clim = caxis;
    cb.Position(1) = cb.Position(1)+.01;
    cb.Position(3) = cb.Position(3)*.5;
    clim = caxis;
    caxis([clim(1) .8*clim(2)])

end
%% conditional psychometrics
% keyboard

% convert to log-odds
% psycho_1 = log(psycho_1./(1-psycho_1));
% psycho_2 = log(psycho_2./(1-psycho_2));

% psycho_1 = log(psycho_1+1);
% psycho_2 = log(psycho_2+1);

% 
%%


psycho_prev0 = squeeze(nanmean(psycho_2_normed(:, bin_0, :), 2));
psycho_prevS = squeeze(nanmean(psycho_2_normed(:, bin_S, :), 2));
psycho_prevF = squeeze(nanmean(psycho_2_normed(:, bin_F, :), 2));

psycho_prevS_normed = psycho_prevS - psycho_prev0;%nanmean(psycho_prevS(:,bin_0),2);
psycho_prevF_normed = psycho_prevF - psycho_prev0;%nanmean(psycho_prevF(:,bin_0),2);

if normalize_rel_lickP
    % random prev, to get distribution
    nIter = 1000;
    psycho_prevR = nan(size(psycho_prev0,1), size(psycho_prev0,2), nIter);
    for ii = 1:nIter
        bin_rand = bin_S(randperm(length(bin_F)));
        psycho_prevR(:,:,ii) = squeeze(nanmean(psycho_2_normed(:,bin_rand,:),2));
    end
    
    psycho_prevR_normed = psycho_prevR - psycho_prev0;
    
    % normalize S and F scores
    mu_null = nanmean(psycho_prevR_normed,3);
    sd_null = nanstd(psycho_prevR_normed,[],3);
    
    psycho_prevF_normed = (psycho_prevF_normed - mu_null)%./sd_null;
    psycho_prevS_normed = (psycho_prevS_normed - mu_null)%./sd_null;

%     psycho_prevR_normed
    % % rank-normalize S and F scores
%     dataReplicated = repmat(psycho_prevS_normed , [1, 1, nIter]);
%     greaterN = sum(dataReplicated > psycho_prevR_normed, 3);
%     lesserN = sum(dataReplicated < psycho_prevR_normed, 3);
%     psycho_prevS_normed = (greaterN./(greaterN + lesserN))*2 - 1;
%     dataReplicated = repmat(psycho_prevF_normed , [1, 1, nIter]);
%     greaterN = sum(dataReplicated > psycho_prevR_normed, 3);
%     lesserN = sum(dataReplicated < psycho_prevR_normed, 3);
%     psycho_prevF_normed = (greaterN./(greaterN + lesserN))*2 - 1;
end

% f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .2 .25]);
subplot(2,8,9); cla; hold on
% shadedErrorBar(bins, nanmean_min_count(psycho_prev0_normed,1), ci_95_magnitude(psycho_prev0_normed,1), ...
%               'lineprops', {'color', [.4 .4 .4], 'LineWidth', 2});
shadedErrorBar(bins, nanmean_min_count(psycho_prevS_normed, min_animals,1), nanStdError(psycho_prevS_normed,1), ...
              'lineprops', {'color', ops.colors.S, 'LineWidth', 2});
shadedErrorBar(bins, nanmean_min_count(psycho_prevF_normed, min_animals,1), nanStdError(psycho_prevF_normed,1), ...
              'lineprops', {'color', ops.colors.F, 'LineWidth', 2});
% for ii = 1:nIter
%    plot(bins, nanmean_min_count(psycho_prevR_normed(:,:,ii), min_animals,1), 'color', 'k', 'linewidth', .1); 
% end
xl=xlim;
plot(xl, [0 0], '--', 'linewidth', 1, 'color', [.5 .5 .5])
% yticks([-10 0 10]*1e-3)
% ylim([-13 13]*1e-3)
ylabel('Relative P(lick)')

subplot(2,8,10); cla; hold on

% psycho_prevS_normed = psycho_prevS  - nanmean(psycho_prevS(:,bin_0),2);
% psycho_prevF_normed = psycho_prevF - nanmean(psycho_prevF(:,bin_0),2);

% calculate same-same, diff-same
psycho_zero = (nanmean(psycho_prevS_normed(:,bin_0),2) + nanmean(psycho_prevF_normed(:,bin_0),2)) / 2;
psycho_same = (nanmean(psycho_prevS_normed(:,bin_S),2) + nanmean(psycho_prevF_normed(:,bin_F),2)) / 2;
psycho_diff = (nanmean(psycho_prevS_normed(:,bin_F),2) + nanmean(psycho_prevF_normed(:,bin_S),2)) / 2;

% psycho_same = ((nanmean(psycho_prevS_normed(:,bin_S),2)-nanmean(psycho_prevS_normed(:,bin_0),2)) ...
%              + (nanmean(psycho_prevF_normed(:,bin_F),2)- nanmean(psycho_prevF_normed(:,bin_0),2))) / 2;
% psycho_diff = ((nanmean(psycho_prevS_normed(:,bin_S),2)-nanmean(psycho_prevS_normed(:,bin_0),2)) ...
%              + (nanmean(psycho_prevF_normed(:,bin_F),2)- nanmean(psycho_prevF_normed(:,bin_0),2))) / 2;   
% psycho_same = psycho_same - psycho_zero;
% psycho_diff = psycho_diff - psycho_zero;

plot([psycho_same, psycho_diff]', '-', 'color', [.5 .5 .5], 'linewidth', 1, 'MarkerFaceColor', 'k')
plot([.9 3.1], [0 0], '--', 'linewidth', 1, 'color', [.5 .5 .5])

% plot median, 95% ci
plot([1 1], [median(psycho_same)-ci_95_magnitude(psycho_same), median(psycho_same)+ci_95_magnitude(psycho_same)], ...
     'color', 'k', 'linewidth', 2)

plot([2 2], [median(psycho_diff)-ci_95_magnitude(psycho_diff), median(psycho_diff)+ci_95_magnitude(psycho_diff)], ...
     'color', 'k', 'linewidth', 2)

scatter([1 2], [median(psycho_same), median(psycho_diff)], 40, 'o', 'MarkerFaceColor', 'k', 'MarkerEdgeAlpha', 0)


% plot difference
same_minus_diff = psycho_same + psycho_diff;
scatter(3+randn(size(psycho_same,1),1)*.2, same_minus_diff, 20, 'o', 'MarkerFaceColor', 'k', 'MarkerFaceAlpha', .6, 'MarkerEdgeAlpha', 0)
plot([3 3], [median(same_minus_diff)-ci_95_magnitude(same_minus_diff), median(same_minus_diff)+ci_95_magnitude(same_minus_diff)], ...
     'linewidth', 2, 'color', 'k')
scatter(3, median(same_minus_diff), 40, 'MarkerFaceColor', 'k', 'MarkerEdgeAlpha', 0)
 
% sig
y_pos_single =11*1e-3;% 1.15;%
y_pos_double = 12*1e-3 %1.25;%
[~,p] = ttest(psycho_same);
% p = signrank(psycho_same);
txt = get_sig_symbol(p);
text(1, y_pos_single, txt, 'FontSize', 10, 'FontWeight', 'normal', 'horizontalalignment', 'center');

[~,p] = ttest(psycho_diff);
% p = signrank(psycho_diff);
txt = get_sig_symbol(p);
text(2, y_pos_single, txt, 'FontSize', 10, 'FontWeight', 'normal', 'horizontalalignment', 'center');
[~,p] = ttest(psycho_same - psycho_diff);
txt = get_sig_symbol(p);

% p=signrank(psycho_same - psycho_diff);
plot([1 2], repelem((y_pos_single + y_pos_double)/2 +.0005, 1,2), '-k', 'linewidth', 2)
text(1.5, y_pos_double+.001, txt, 'FontSize', 10, 'FontWeight', 'normal', 'horizontalalignment', 'center', 'HorizontalAlignment', 'center');

[~,p] = ttest(same_minus_diff);
% p = signrank(same_minus_diff);
txt = get_sig_symbol(p);
text(3, y_pos_single, txt, 'FontSize', 10, 'FontWeight', 'normal', 'horizontalalignment', 'center');
xlim([.5 3.5])
xticks([1 2 3])
xticklabels({'Same (SS,FF)', 'Diff (FS,SF)', 'Same + Diff'})
xtickangle(45)
% yticks([-10 0 10]*1e-3)
% ylim([-13 13]*1e-3)

%% By expectation

for w = 1:2
    
    psycho_prev0 = squeeze(nanmean(psycho_2_FS{w}(:, bin_0, :), 2));
    psycho_prevS = squeeze(nanmean(psycho_2_FS{w}(:, bin_S, :), 2));
    psycho_prevF = squeeze(nanmean(psycho_2_FS{w}(:, bin_F, :), 2));
    
    psycho_prevS = psycho_prevS - psycho_prev0;
    psycho_prevF = psycho_prevF - psycho_prev0;
    
    psycho_prevS_normed = psycho_prevS;% - nanmean(psycho_prevS(:,bin_0),2);
    psycho_prevF_normed = psycho_prevF;% - nanmean(psycho_prevF(:,bin_0),2);
    psycho_prev0_normed = psycho_prev0 - nanmean(psycho_prev0(:,bin_0),2);
    
    
    if normalize_rel_lickP
        % random prev, to get distribution
        nIter = 1000;
        psycho_prevR = nan(size(psycho_prev0,1), size(psycho_prev0,2), nIter);
        for ii = 1:nIter
            bin_rand = bin_S(randperm(length(bin_F)));
            psycho_prevR(:,:,ii) = squeeze(nanmean(psycho_2_FS{w}(:,bin_rand,:),2));
        end
        
        psycho_prevR_normed = psycho_prevR - psycho_prev0;
        
        % normalize S and F scores
            mu_null = nanmean(psycho_prevR_normed,3);
            sd_null = nanstd(psycho_prevR_normed,[],3);
        
            psycho_prevF_normed = (psycho_prevF_normed - mu_null)./sd_null;
            psycho_prevS_normed = (psycho_prevS_normed - mu_null)./sd_null;
        
%             psycho_prevR_normed
        % rank-normalize S and F scores
%         dataReplicated = repmat(psycho_prevS_normed , [1, 1, nIter]);
%         greaterN = sum(dataReplicated > psycho_prevR_normed, 3);
%         lesserN = sum(dataReplicated < psycho_prevR_normed, 3);
%         psycho_prevS_normed = (greaterN./(greaterN + lesserN))*2 - 1;
%         dataReplicated = repmat(psycho_prevF_normed , [1, 1, nIter]);
%         greaterN = sum(dataReplicated > psycho_prevR_normed, 3);
%         lesserN = sum(dataReplicated < psycho_prevR_normed, 3);
%         psycho_prevF_normed = (greaterN./(greaterN + lesserN))*2 - 1;
    end
    
    % psycho_prev0_normed = psycho_prev0 - nanmean(psycho_prev0(:,bin_0),2);
    
    % f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .2 .25]);
    subplot(2,8,11+(w-1)*3);
    shadedErrorBar(bins, nanmean_min_count(psycho_prev0_normed, min_animals,1), nanStdError(psycho_prev0_normed,1), ...
        'lineprops', {'color', 'k', 'LineWidth', 2});
%     ylim([-.01 .01])
    subplot(2,8,12+(w-1)*3); cla; hold on
    % shadedErrorBar(bins, nanmean_min_count(psycho_prev0_normed,1), ci_95_magnitude(psycho_prev0_normed,1), ...
    %               'lineprops', {'color', [.4 .4 .4], 'LineWidth', 2});
    shadedErrorBar(bins, nanmean_min_count(psycho_prevS_normed, min_animals,1), nanStdError(psycho_prevS_normed,1), ...
        'lineprops', {'color', ops.colors.S, 'LineWidth', 2});
    shadedErrorBar(bins, nanmean_min_count(psycho_prevF_normed, min_animals,1), nanStdError(psycho_prevF_normed,1), ...
        'lineprops', {'color', ops.colors.F, 'LineWidth', 2});
    xl=xlim;
    plot(xl, [0 0], '--', 'linewidth', 1, 'color', [.5 .5 .5])
    ylabel('Relative P(lick)')
%     yticks([-10 0 10]*1e-3)
%     ylim([-13 13]*1e-3)
    
    % inset - plot psycho prev 0
    
    subplot(2,8,13+(w-1)*3); cla; hold on
    % calculate same-same, diff-same - only for expecting
%     psycho_0S = (nanmean(psycho_prevS_normed(:,bin_0),2) + nanmean(psycho_prevF_normed(:,bin_0),2)) / 2;
    psycho_SS = nanmean(psycho_prevS_normed(:,bin_S),2); 
    psycho_SF = nanmean(psycho_prevS_normed(:,bin_F),2);
    psycho_FS = nanmean(psycho_prevF_normed(:,bin_S),2); 
    psycho_FF = nanmean(psycho_prevF_normed(:,bin_F),2);
    
%     psycho_SS = psycho_SS - psycho_0;
%     psycho_SF = psycho_SF - psycho_0;
%     psycho_FS = psycho_FS - psycho_0;
%     psycho_FF = psycho_FF - psycho_0;
    
    
    plot([.9 3.1], [0 0], '--', 'linewidth', 1, 'color', [.5 .5 .5])
    
    % plot median, 95% ci
    if w==1
        plot([psycho_FF, psycho_SF]', '-', 'color', [.5 .5 .5], 'linewidth', 1, 'MarkerFaceColor', 'k')
        plot([2 2], [nanmean(psycho_SF)-ci_95_magnitude(psycho_SF), nanmean(psycho_SF)+ci_95_magnitude(psycho_SF)], ...
            'color', 'k', 'linewidth', 2)
        plot([1 1], [nanmean(psycho_FF)-ci_95_magnitude(psycho_FF), nanmean(psycho_FF)+ci_95_magnitude(psycho_FF)], ...
            'color', 'k', 'linewidth', 2)
        scatter([1 2], [nanmean(psycho_FF), nanmean(psycho_SF)], ...
            40, 'o', 'MarkerFaceColor', 'k', 'MarkerEdgeAlpha', 0)
        
        [~,p] = ttest(psycho_SF);
        txt = get_sig_symbol(p);
        text(2, y_pos_single, txt, 'FontSize', 10, 'FontWeight', 'normal', 'horizontalalignment', 'center');
        [~,p] = ttest(psycho_FF);
        txt = get_sig_symbol(p);
        text(1, y_pos_single, txt, 'FontSize', 10, 'FontWeight', 'normal', 'horizontalalignment', 'center');

        % plot diff
        same_minus_diff = psycho_FF + psycho_SF;
        scatter(3+randn(size(psycho_same,1),1)*.1, same_minus_diff, 20, 'o', 'MarkerFaceColor', 'k', 'MarkerFaceAlpha', .6, 'MarkerEdgeAlpha', 0)
        plot([3 3], [nanmean(same_minus_diff)-ci_95_magnitude(same_minus_diff), nanmean(same_minus_diff)+ci_95_magnitude(same_minus_diff)], ...
            'linewidth', 2, 'color', 'k')
        scatter(3, nanmean(same_minus_diff), 40, 'MarkerFaceColor', 'k', 'MarkerEdgeAlpha', 0)
        % sig
        [~,p] = ttest(same_minus_diff, 0);
        txt = get_sig_symbol(p);
        text(3, y_pos_single, txt, 'FontSize', 10, 'FontWeight', 'normal', 'horizontalalignment', 'center');
    elseif w==2
        plot([psycho_FS, psycho_SS]', '-', 'color', [.5 .5 .5], 'linewidth', 1, 'MarkerFaceColor', 'k')
        plot([1 1], [nanmean(psycho_FS)-ci_95_magnitude(psycho_FS), nanmean(psycho_FS)+ci_95_magnitude(psycho_FS)], ...
            'color', 'k', 'linewidth', 2)
        plot([2 2], [nanmean(psycho_SS)-ci_95_magnitude(psycho_SS), nanmean(psycho_SS)+ci_95_magnitude(psycho_SS)], ...
            'color', 'k', 'linewidth', 2)
        scatter([1 2], [nanmean(psycho_FS), nanmean(psycho_SS)], ...
            40, 'o', 'MarkerFaceColor', 'k', 'MarkerEdgeAlpha', 0)
        
        [~,p] = ttest(psycho_FS);
        txt = get_sig_symbol(p);
        text(1, y_pos_single, txt, 'FontSize', 10, 'FontWeight', 'normal', 'horizontalalignment', 'center');
        [~,p] = ttest(psycho_SS);
        txt = get_sig_symbol(p);
        text(2, y_pos_single, txt, 'FontSize', 10, 'FontWeight', 'normal', 'horizontalalignment', 'center');
        same_minus_diff = psycho_FS + psycho_SS;
        scatter(3+randn(size(psycho_same,1),1)*.1, same_minus_diff, 20, 'o', 'MarkerFaceColor', 'k', 'MarkerFaceAlpha', .6, 'MarkerEdgeAlpha', 0)
        plot([3 3], [nanmean(same_minus_diff)-ci_95_magnitude(same_minus_diff), nanmean(same_minus_diff)+ci_95_magnitude(same_minus_diff)], ...
            'linewidth', 2, 'color', 'k')
        scatter(3, nanmean(same_minus_diff), 40, 'MarkerFaceColor', 'k', 'MarkerEdgeAlpha', 0)
        % sig
        
        [~,p] = ttest(same_minus_diff, 0);
        txt = get_sig_symbol(p);
        text(3, y_pos_single, txt, 'FontSize', 10, 'FontWeight', 'normal', 'horizontalalignment', 'center');
    end
%     scatter([1 2 3 4], [nanmean(psycho_FF), nanmean(psycho_SF), nanmean(psycho_FS), nanmean(psycho_SS)], ...
%             40, 'o', 'MarkerFaceColor', 'k', 'MarkerEdgeAlpha', 0)
    

    xlim([.5 3.5])
    xticks([1:3])
    
    if w==1
        xticklabels({'FF', 'SF', 'SF+FF'})
    elseif w==2
        xticklabels({'FS', 'SS', 'FS+SS'})
    end
    xtickangle(45)
    %ylabel('Relative P(lick)')
%     yticks([-10 0 10]*1e-3)
%     ylim([-13 13]*1e-3)
    
end

%% Plot stepping lick probability schematics

% Visualize lick probability stepping: 0F/SF/FF for expF, 0S/FS/SS for expS
pulse_combs = {'00', '0S', '0F', 'SF', 'FS', 'FF', 'SS'; ...
               '00', '0S', '0F', 'SF', 'FS', 'FF', 'SS'};
psychos = nan(nA, size(pulse_combs, 1), size(pulse_combs, 2));

for w = 1:2 % expF, expS
    for ii = 1:size(pulse_combs, 2)
        pulse_comb = pulse_combs{w, ii};
        prev = pulse_comb(1);
        curr = pulse_comb(2);
        eval(['hit_p = squeeze(nanmean(psycho_2_FS{w}(:, bin_' prev ', bin_' curr '), [2 3]));'])
        psychos(:, w, ii) = hit_p;
    end    
    psychos(:, w, :) = psychos(:, w, :) - psychos(:, w, 1);
end

% plot steps
% actual steps to plot to calculate how lick prob changes with each pulse
steps = {{'00', '0F'}, {'0S', 'SF'}, {'0F', 'FF'}; ...
         {'00', '0S'}, {'0F', 'FS'}, {'0S', 'SS'}};
t = [0 1 1 2 2 3 3 4];
% t = [0 1 2 3];
f=figure('Units', 'normalized', 'OuterPosition', [.1 .1 .2 .2]);
cnt = 0;
yl = [-.0015 .012]; 
yl_col = [-.002 .01];
tmp = ops.colors.heatmap;
% cmap = create_custom_colormap(tmp(1,:), [.6 .6 .6], tmp(end,:));
cmap = customColormapAssym(tmp(1,:), [.6 .6 .6], tmp(end,:), yl_col);

for w = 1:2 % expF, expS
    for ii = 1:size(steps,2)
        step = steps{w,ii};
        idx1 = find(strcmp(pulse_combs(w,:), step{1}));
        idx2 = find(strcmp(pulse_combs(w,:), step{2}));
        
        paths = [zeros(nA,1), zeros(nA,1), ...
                 squeeze(psychos(:, w, idx1)), squeeze(psychos(:, w, idx1)), ...
                 squeeze(psychos(:, w, idx2)), squeeze(psychos(:, w, idx2)), ...
                 zeros(nA,1), zeros(nA,1)];
%         paths = [zeros(nA,1), ...
%                  squeeze(psychos(:, w, idx1)),  ...
%                  squeeze(psychos(:, w, idx2)), ...
%                  zeros(nA,1)];     
        paths(any(isnan(paths),2),:) = nan;
        cnt = cnt + 1;
        subplot(1, 6, cnt); 
        
        hold on;
%         shadedErrorBar(t, nanmean(paths,1), nanStdError(paths,1)*1.96)
        plot_coloured_values(t, nanmean(paths,1), cmap, yl_col, 'linewidth', 2)
%         plot_pos_neg_colours_err(t, nanmean(paths,1), cmap, yl_col, 1.96*nanStdError(paths,1), 'linewidth', 2)

%         for aa = 1:nA
%             hold on
%             scatter(1.5, paths(aa,3), 10, paths(aa,3), 'filled', 'markeredgealpha', 0)
%             scatter(2.5, paths(aa,5), 10, paths(aa,5), 'filled', 'markeredgealpha', 0)
%         end
        % add signficance
%         [~,p1] = ttest(paths(:,3)); sig1 = get_sig_symbol(p1);
%         [~,p2] = ttest(paths(:,5)); sig2 = get_sig_symbol(p2);
%         [~,pd] = ttest(paths(:,5) - paths(:,3))
%         sigd = get_sig_symbol(pd);
%         text(1.5, yl(1)*.7, sig1, 'fontsize', 10, 'fontweight', 'normal', 'HorizontalAlignment', 'center')
%         text(2.5, yl(1)*.7, sig2, 'fontsize', 10, 'fontweight', 'normal', 'HorizontalAlignment', 'center')
%         plot([1.5 2.5], [yl(1)*.85 yl(1)*.85], '-k', 'linewidth', 1)
%         text(2,   yl(1), sigd, 'fontsize', 10, 'fontweight', 'normal', 'HorizontalAlignment', 'center')
%         keyboard
        caxis(yl_col);
        ylim(yl)
        ax = gca;
%         addYAxisBreak(ax, yl(1), yl(2))
        set(gca, 'xcolor', 'none')
        if cnt>1
            set(gca, 'ycolor', 'none')
        end
    end
end


end
