function analyse_IO_effects(sessions, trials_all, sp_all, daq_all, neuron_info, ops)
% 
% Plot responses to fast/slow outliers as a function of baseline activity level; see if this alone
% explains increased gain to attended stim.
% 
% --------------------------------------------------------------------------------------------------

%%
flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');
animals = unique({sessions.animal});
 
% roi_titles = {'MOs_CP', 'PPC', 'Vis'};
allen_areas = {};
for r = 1:length(rois)
    areas = area_names_in_roi(rois{r});
    
    while any(cellfun(@iscell, areas))
        areas = [areas{cellfun(@iscell,areas)} areas(~cellfun(@iscell,areas))];
    end
    allen_areas{r} = areas;
end

subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_010', 'MH_011','MH_015'};
good_subj = ismember(neuron_info.animal,subjects);


%% load indexes

indexes = table;
% load in indexes
for s = 1:length(sessions)
    animal  = sessions(s).animal;
    session = sessions(s).session;

    if strcmp(session(1), 'h') % not recording session
        continue
    end
    
    inds = loadVariable(fullfile(ops.indexesDir, sprintf('%s_%s.mat', animal, session)), 'indexes');
    
    indexes = vertcat(indexes, inds);
end

%% load in responses, reclassify as high/low pre-tf activity

% get average responses for every unit
resps = [];
% resp_dir = strrep(ops.dataDir, 'session_data', 'avg_responses_v4');
% resp_dir = ops.eventPSTHdir;

tf_resp_names = {'FexpF', 'FexpS', 'SexpF', 'SexpS'};
ops.tfOutlier = 1.5;
for s = 1:length(sessions)
    fprintf('session %d/%d\n', s, length(sessions))
    animal  = sessions(s).animal;
    session = sessions(s).session;

    if strcmp(session(1), 'h') % not recording session
        continue
    end
    
    [fr, t_ax] = spike_times_to_fr_in_trial(sp_all{s}, daq_all{s}, trials_all{s}, ops.spBinWidth);
    fr = fr/(ops.spBinWidth/1000);
    fr_mu = nanmean(fr, 2);
    fr_sd = nanstd(fr, [], 2);

    fr = (fr - fr_mu) ./ fr_sd;
    % smooth firing
    fr = smoothdata(fr, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);
    % get flip time
    animal_id = strcmp(animals, sessions(s).animal);
    flip_time = flip_times(animal_id);
    
    % get amps, times of every tf pulse
   [ampsF, timesF, tr_timesF, lickedF] = ...
       get_tf_outliers_time_amp(trials_all{s}, daq_all{s}, 2, .25, ops.tfOutlier, 1, ops.rmvTimeAround, [0 ops.rmvTimeAround]);
   [ampsS, timesS, tr_timesS, lickedS] = ...
       get_tf_outliers_time_amp(trials_all{s}, daq_all{s}, 2, .25, ops.tfOutlier, -1, ops.rmvTimeAround, [0 ops.rmvTimeAround]);

   for tf_i = 1:length(tf_resp_names)
       tf_resp = tf_resp_names{tf_i};
       if strcmp(tf_resp(1), 'F')
           dir = 'F';
       else
           dir = 'S';
       end
       
       eval(['times = times' dir ';']);
       eval(['tr_times = tr_times' dir ';']);
       eval(['licked = licked' dir ';']);
       
       if strcmp(tf_resp(end), 'F') % expecting fast
           switch sessions(s).contingency
               case 'EFLS'
                   exp = tr_times < flip_time & tr_times > ops.rmvTimeAround+1;
               case 'ESLF'
                   exp = tr_times > flip_time;
           end
       elseif strcmp(tf_resp(end), 'S') % expecting slow
           switch sessions(s).contingency
               case 'EFLS'
                   exp = tr_times > flip_time;
               case 'ESLF'
                   exp = tr_times < flip_time & tr_times > ops.rmvTimeAround+1;
           end
       end
       
       times = times(exp & ~licked);
       
       % get times of different tf outliers at different times, 
       [tf_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, times, [-1 1]); 
       
       resp_pre  = nanmean(psth(:, :, isbetween(tf_tax, [-1 0])),3);
       resp_post = nanmean(psth(:, :, isbetween(tf_tax, ops.respWin.tfShort)),3);
       resp_post = resp_post - resp_pre;
       eval([lower(tf_resp) '_pre = resp_pre;']);
       eval([lower(tf_resp) '_post = resp_post;']);
   end
   
   r  = table2struct(table(fr_mu, fr_sd, fexpf_pre, fexpf_post, fexps_pre, fexps_post, sexpf_pre, sexpf_post, sexps_pre, sexps_post));
   
    if isempty(resps)
        resps = r;
    else
        resps = [resps; r];
    end
end

%% save temporarily

save(fullfile(ops.saveDir, 'tmp_resps_IO_smoothedFR_noBLON_20250219.mat'), 'resps', '-v7.3')
fprintf('Responses saved to %s\n', ops.saveDir);

%% remove some unnecessary units
multi = indexes.cg==0 | [resps.fr_sd]'<0.1 | [resps.fr_mu]' < 0.1;

tf_sensitive =  indexes.tf_short_p<.01 & (sign(indexes.tfExpF_short)==sign(indexes.tfExpS_short));
good_inds    = indexes(good_subj & ~multi & tf_sensitive, :);
good_resps   = resps(good_subj & ~multi & tf_sensitive);

fast_pref = [good_inds.tf_short]>0;
slow_pref = [good_inds.tf_short]<0;

%% for every unit, find IO curves 

nN = height(good_resps);
n_activity_bins = 5; % number of bins for binning pre-pulse activity levels

gain_curves = cell(nN, 4, n_activity_bins); %fexpf, fexps, sexpf, sexps

for n = 1:nN
   
    % get bins for activity levels
    pre_lvls = [good_resps(n).fexpf_pre, good_resps(n).fexps_pre, good_resps(n).sexpf_pre, good_resps(n).sexps_pre];
 
    edges = prctile(unique(pre_lvls), linspace(0, 100, n_activity_bins+1));
    
    for tf_i = 1:length(tf_resp_names)
       tf_resp = tf_resp_names{tf_i};
       
       pre_lvls  = good_resps(n).(sprintf('%s_pre', lower(tf_resp)));
       resp_lvls = good_resps(n).(sprintf('%s_post', lower(tf_resp)));
       
       pre_lvls_disc = discretize(pre_lvls, edges);
       
       for ii = 1:n_activity_bins 
           gain_curves{n, tf_i, ii} = resp_lvls(pre_lvls_disc==ii);
       end
       
    end
    
end

% calculate mean, median, 95%ci
mean_gains   = cellfun(@nanmean, gain_curves);
median_gains = cellfun(@nanmedian, gain_curves);
ci95_gains   = cellfun(@(x) std(x)/sqrt(length(x))*1.96, gain_curves);

%% Visualize response gain as function of pre-pulse activity & expectation (simplified)

% close all
% 
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .15 .35]);
sm = 3;

mus = nanmean(mean_gains, [2 3])
sds = nanstd(mean_gains, [], [2 3]);

mean_gains = (mean_gains - mus)./sds;

for r = 1:length(roi_titles)
    
    this_roi_areas = allen_areas{r};
    in_area = contains(good_inds.loc, this_roi_areas);
    
    resps_mean_F = mean_gains(in_area & fast_pref, :, :); % fast preferring
    resps_mean_S = mean_gains(in_area & slow_pref, :, :); % slow preferring
    
    gain_mean_F_expF = squeeze(resps_mean_F(:, 1, :) - resps_mean_F(:, 3, :)); % fexpf-sexpf
    gain_mean_F_expS = squeeze(resps_mean_F(:, 2, :) - resps_mean_F(:, 4, :)); % fexps-sexps
    
    gain_mean_S_expF = squeeze(resps_mean_S(:, 3, :) - resps_mean_S(:, 1, :)); % sexpf - fexpf
    gain_mean_S_expS = squeeze(resps_mean_S(:, 4, :) - resps_mean_S(:, 2, :)); % sexps - fexps
    
    % combine S and F pref
    gain_expPref  = cat(1, gain_mean_F_expF, gain_mean_S_expS);
    gain_expUpref = cat(1, gain_mean_F_expS, gain_mean_S_expF);
    
    % plot IO curves
    subplot(3,2,r); hold on;

    shadedErrorBar(0:n_activity_bins-1, ...
                   smoothdata(gain_expPref, 2, 'movmean', sm), ...
                   {@nanmean, @nanStdError}, ...
                   'lineprops', {'color', [196 146 186]/255, 'linewidth', 1.5})
    
    shadedErrorBar(0:n_activity_bins-1, ...
                   smoothdata(gain_expUpref, 2, 'movmean', sm), ...
                   {@nanmean, @nanStdError}, ...
                   'lineprops', {'--', 'color', [.3 .3 .3], 'linewidth', 1.5})
     ylim([0 .45]); yticks([0 .2 .4])
     offsetAxes
     % difference
     subplot(3,2,r+2); hold on;
     shadedErrorBar(0:n_activity_bins-1, ...
                   smoothdata(gain_expPref-gain_expUpref, 2, 'movmean', sm), ...
                   {@nanmean, @nanStdError}, ...
                   'lineprops', {'color', [196 146 186]/255, 'linewidth', 1.5})
     plot([0, n_activity_bins-1], [0 0], '--k', 'linewidth',.5)
     ylim([-.05 .3]); yticks([-0:.1:.3])
     offsetAxes
end

 
%% Fit linear models to each unit 

% for every neuron, figure out how context-dependent IO effects are

% create 'unsigned gain': pref-unpref resp, expecting pref vs expecting unpef
gains_by_pref = gain_curves;
gains_by_pref(slow_pref,:,:) = gain_curves(slow_pref, end:-1:1, :);

% normalize
gains_mu = cellfun(@nanmean, gains_by_pref);
normalizer = squeeze(nanmean(gains_mu, 2));

for ii = 1:size(gains_by_pref,1)
    for jj = 1:size(gains_by_pref,2)
        for kk = 1:size(gains_by_pref,3)
            gains_by_pref{ii,jj,kk} = gains_by_pref{ii,jj,kk} - normalizer(ii,kk);
        end
    end
end

coeffs = nan(nN, 3); % context (expectation), pre-pulse level, interaction
p_vals = nan(nN, 3);

for n = 1:nN
    
    unit_gain_curve = squeeze(gains_by_pref(n,:,:));
    
    if any(cellfun(@isempty, unit_gain_curve)), continue; end
    for ii = 1:n_activity_bins
        unit_gain_curve{1,ii} = [unit_gain_curve{1,ii}, -1*unit_gain_curve{3,ii}];
        unit_gain_curve{2,ii} = [unit_gain_curve{2,ii}, -1*unit_gain_curve{4,ii}]; 
    end
    unit_gain_curve(3:end,:) = [];
    
    % normalize
        
    % two-way ANOVA - get effect size
    
    % first create three vectors: containing obs, and factor levels (context/expectation and
    % pre-pulse activity levels)
    obs = [];
    context = [];
    pre_pulse_lvl = [];
    
    for context_i = 1:size(unit_gain_curve,1)
        for lvl_i = 1:size(unit_gain_curve,2)
            obs = [obs; unit_gain_curve{context_i, lvl_i}'];
            context = [context; repelem(context_i, length(unit_gain_curve{context_i, lvl_i}),1)];
            pre_pulse_lvl = [pre_pulse_lvl; repelem(lvl_i, length(unit_gain_curve{context_i, lvl_i}), 1)];
        end
    end
    context(context==2)=-1; 
    pre_pulse_lvl = pre_pulse_lvl - 3;
    
    % moderation analysis
    lm = fitlm([context, pre_pulse_lvl, context.*pre_pulse_lvl, ones(size(context))], zscore(obs), 'intercept', false); 
     
    % store coeffs
    coeffs(n,:) = lm.Coefficients.Estimate(1:3);
    p_vals(n,:) = lm.Coefficients.pValue(1:3);
     
    
end
%

%% Visualization

% close all
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .2 .3]);
cols = {ops.colors.MOs, ops.colors.Vis};
coeff_labels = {'expectation', 'activity', 'interaction'};

sig = double(p_vals<.05);
sig(sig==0)=nan;
% sig_coeffs = coeffs .* sig;

for r = 1:length(roi_titles)
    this_roi_areas = allen_areas{r};
    in_area = contains(good_inds.loc, this_roi_areas);
    for ii = 1:3
        subplot(2,3,(r-1)*3+ii); hold on
        plot([.25 1.5], [0 0], '--', 'color', [.5 .5 .5])

        coeff_range = prctile(coeffs(in_area,ii),[1 99]);
        vals = coeffs(in_area,ii);
%         vals(~isbetween(vals, coeff_range)) = [];
        vals(vals>coeff_range(2)) = 0 + rand(sum(vals>coeff_range(2)),1)*coeff_range(2);
        vals(vals<coeff_range(1)) = 0 + rand(sum(vals<coeff_range(1)),1)*coeff_range(1);
        % violin
        h = violinPlot(vals, 'histOri', 'left', 'widthDiv', [2 1], 'showMM', 0, 'xValues', 1, ...
                   'distwidth', .5, 'color', mat2cell(cols{r},1));
        set(h{1}, 'FaceAlpha', 0.5) % where 0.5 is 50% transparent       
        ylim([-10 15]*1e-2)
        yticks([-10 0 10]*1e-2)
        % scatter
        scatter(1.05 + .03*randn(size(vals)), vals, 5, 'MarkerFaceColor', cols{r}*.8, 'MarkerFaceAlpha',.8, 'MarkerEdgeColor', cols{r}*.6)
        
        % mean +/- error
        ci95 = ci_95_magnitude(vals);
        plot([1 1]-.3, nanmean(vals) + [-ci95 ci95], 'k', 'linewidth', 1);
        scatter(1-.3, nanmean(vals), 50, '>', 'MarkerFaceColor', cols{r}, 'MarkerEdgeColor', 'k');
        
        [~,p] = ttest(sig_coeffs(in_area,ii));
         yl = ylim;
        mysigstar(gca, 1, yl(2)+.1*range(yl), p)
        xticklabels(coeff_labels{ii});
        if ii>1
            set(gca, 'Ycolor', 'none')
        end
        xlim([.5 1.3])
     end 
    
end
%% Visualize coefficients for context, gain, interaction
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .2 .25]);
cols = {ops.colors.MOs, ops.colors.Vis};
coeff_labels = {'context', 'activity', 'interaction'};

for r = 1:length(roi_titles)
    this_roi_areas = allen_areas{r};
    in_area = contains(good_inds.loc, this_roi_areas);
    
    for ii = 1:3
        subplot(2,3,(r-1)*3 + ii); hold on
        edges = prctile(coeffs(:,ii), [1 99.5]);
        edges = linspace(edges(1),edges(2),12);
         h=histogram(coeffs(in_area,ii), edges, 'Normalization', 'probability', 'FaceColor', cols{r}, 'edgealpha', 0);
        
        % test signf
         p = signrank(coeffs(in_area,ii));
        % plot median and sign
        med  = mean(coeffs(in_area,ii));
        ci_95 = ci_95_magnitude(coeffs(in_area,ii));

        yl = ylim;
        plot(med+[-ci_95 ci_95], [yl(2)+.1*range(yl) yl(2)+.1*range(yl)], 'k', 'LineWidth', 2);
        scatter(med, yl(2)+.1*range(yl), 40, 'v', 'MarkerEdgeAlpha', 1, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', cols{r});
        plot([0 0], [yl(1) yl(2)+.05*range(yl)], '--', 'color', 'k')
        %set(gca, 'yscale', 'log')
        if p < 1e-3
            sig_sign = '***';
            sz=10;
        elseif p < 1e-2
            sig_sign = '**';
            sz=10;
        elseif p<.05
            sig_sign = '*';
            sz=10;
        else
            sig_sign = 'n.s.';
            sz=8;
        end
        
        text(med, yl(2)+range(yl)*.21, sig_sign, 'FontSize', sz, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
         
        % add scatter
        yvals = rand(size(coeffs(in_area,ii))) * range(yl)*.2 + diff(yl)/3;
 
        title(coeff_labels{ii}) 
    end
    
end


%%



%% visualize for single units, and grouped by area

cols = {ops.colors.F, ops.colors.F_light, ops.colors.S_light, ops.colors.S};

avg_gains_normed = mean_gains - nanmean(mean_gains,2);
for n = 1:nN
    f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .1 .15]);
    hold on
    for tf_i = 1:size(mean_gains,2)
        shadedErrorBar(1:n_activity_bins, avg_gains_normed(n,tf_i,:), ci95_gains(n,tf_i,:), ...
                       'lineprops', {'color', cols{tf_i}, 'linewidth', 2});
    end
    keyboard
    close(f)
    
end



end








