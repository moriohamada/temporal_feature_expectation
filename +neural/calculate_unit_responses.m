function [resps, time_axes] = calculate_average_responses_to_events_basics(sessions, trials_all, daq_all, sp_all, ops)
% 
% Calculate mean, median, + std dev and n events, for events of interest.
% Also saves raw PSTHs for each event
% 
fprintf('Getting average responses for every unit\n')
flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');
animals = unique({sessions.animal});

%%
%% Classify early licks

% get all lick-triggered stim

% for each session
n_sess = length(sessions);
a_idx = 0;
s_idx = 0;
last_animal = '';
elts = {};
elt = {};
for s = 1:n_sess
   animal  = sessions(s).animal;
   if ~strcmp(last_animal, animal)
       last_animal = animal;
       a_idx  = a_idx + 1;
       s_idx = 1;
   else
       s_idx = s_idx + 1;
   end
   
   session = sessions(s).session;
   cont    = sessions(s).contingency;
   
   [elts{a_idx, s_idx}, elt{a_idx, s_idx}] = get_lick_triggered_stimuli(trials_all{s}, ops);
   elt{a_idx, s_idx} = elt{a_idx, s_idx} - flip_times(a_idx);
   if strcmp(sessions(s).contingency, 'ESLF')
       elt{a_idx, s_idx} = -1*elt{a_idx, s_idx};
   end
   conts{a_idx, s_idx} = sessions(s).contingency;
   
end
animals = unique({sessions.animal});
for a = 1:length(animals)    
    % collapse psycho/chrono across sessions, per mouse
    elts_by_mouse{a} = vertcat(elts{a,:});
    elt_by_mouse{a}  = vertcat(elt{a,:});
end
% and all lts across all mice
elts_all = vertcat(elts_by_mouse{:});
elt_all  = vertcat(elt_by_mouse{:});

% unsupervised - k means
elts_all = elts_all(:, 21:40);
elts_all(isnan(elts_all)) = 0;
[clusters, ids, D] = cluster_early_licks(elts_all);

% label stim not clearly in either cluster as 'uncertain'
min_dist  = abs((D(:,1) - D(:,2)));
thresh    = prctile(min_dist, 67);
uncertain = min_dist < thresh;
ids(uncertain) = 0;

% make cluster 1 slow, 2 fast
if sum(clusters(1,:)) > clusters(2,:)
    tmp = clusters;
    clusters(1,:) = tmp(2,:);
    clusters(2,:) = tmp(1,:);
    ids(ids==2) = -1;
else
    ids(ids==1) = -1;
    ids(ids==2) = 1;
end

clusters(1,:) = nanmean(elts_all(ids==-1 & ~uncertain,:),1);
clusters(2,:) = nanmean(elts_all(ids==1  & ~uncertain,:),1);

clearvars -except sessions trials_all daq_all sp_all ops clusters flip_times animals thresh
%%
resps = table;
time_axes = struct;
mkdir(ops.eventPSTHdir)
for s =1:length(sessions)
%     try
   fprintf('session %d/%d\n', s, length(sessions))
   if isempty(sp_all{s}) % not recording session
        continue
   end
   animal = sessions(s).animal;
   sess   = sessions(s).session;

   event_psth_file = fullfile(ops.eventPSTHdir, sprintf('%s_%s.mat', animal, sess));

   % get flip time
   animal_id = strcmp(animals, sessions(s).animal);
   flip_time = flip_times(animal_id);
   
   % create FR matrix
   sp = sp_all{s};
   nN = length(sp.cids);
   daq = daq_all{s};
   % get times around trial only
   
   [fr, t_ax] = spike_times_to_fr(sp, ops.spBinWidth);
   [fr, t_ax] = remove_out_of_trial_fr(fr, t_ax, daq);
   [fr_bl, ~] = remove_non_baseline_fr(fr,t_ax,daq,ops);
   fr = fr/(ops.spBinWidth/1000);
   fr_bl = fr_bl/(ops.spBinWidth/1000);
   fr_mu = mean(fr_bl,2);
   fr_sd = std(fr_bl,[],2);
   clear fr_bl
   
   fr = smoothdata(fr,2, 'movmean', ops.spSmoothSize/ops.spBinWidth);
   %[fr, t_ax, unit_info] = loadVariables(fullfile(ops.frDir, sprintf('%s_%s.mat', animal, sess)), ...
   %                                     'fr', 't_ax', 'unit_info');
                                     
   %fr_z = (fr - mean(fr,2)) ./ std(fr,[],2);
   
   % also get only in baseline fr
%    [fr_bl, ~] = remove_non_baseline_fr(fr, t_ax, daq, ops);
%    
%    fr_mu = mean(fr_bl,2);
%    fr_sd = std(fr_bl,[],2);
%    keyboard
   save(event_psth_file, 'fr_mu', 'fr_sd', '-v7.3');

   %% BL onset (short)
% 
   mintrdur = ops.minTrialDur;
   ops.minTrialDur = 2;
%    [t, ~, blOn_info] = get_times_of_events(trials_all{s}, daq_all{s}, ops, 'baseline onset');
%    ops.minTrialDur = mintrdur;
%    [blOn_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t, [-1 2]);
%    psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
%    mean_resp_blon = squeeze(nanmean(psth,2));
%    sd_resp_blon   = squeeze(nanstd(psth,[],2));
%    n_resp_blon    = size(psth,2);
%    
%    if ~isfield(time_axes, 'blOn')
%        time_axes.blOn = blOn_tax;
%    end
%    %over ti
%    % save to file
%    blOn_psth = psth;
%    save(event_psth_file, 'blOn_psth', 'blOn_tax', 'blOn_info', '-append');
%    clear psth blOn_psth
   
   %% BL onset (long)

   % temporarily change min trial dur
   
   ops.minTrialDur = 11;
   [t, ~, bl_info] = get_times_of_events(trials_all{s}, daq_all{s}, ops, 'baseline onset');
   ops.minTrialDur = mintrdur;
   
   [bl_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t, [-2 11]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth*4,0]);
   mean_resp_bl = squeeze(nanmean(psth,2));
   sd_resp_bl   = squeeze(nanstd(psth,[],2));
   n_resp_bl    = size(psth,2);
   if ~isfield(time_axes, 'bl')
       time_axes.bl = bl_tax;
   end
   bl_psth = psth;
   save(event_psth_file, 'bl_psth', 'bl_tax', 'bl_info', '-append');
   clear psth bl_psth
   
   %% TF (F/S, E/L)
   
   [t, tr_t, tf_info] = get_times_of_events(trials_all{s}, daq_all{s}, ops, 'tf');
   
   fast   = tf_info(:,1)>0;
   slow   = tf_info(:,1)<0;
%    keyboard
   early  = tr_t' < flip_time-.5 & tr_t' > ops.rmvTimeAround;
   late   = tr_t' > flip_time+.5;
   licked = tf_info(:,2)==1;
   
   % fast, early, no lick
   [tf_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(fast&early&~licked), [-.5 1.5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_fe   = squeeze(nanmean(psth,2));
   sd_resp_fe     = squeeze(nanstd(psth,[],2));
   n_resp_fe      = size(psth,2);
   
   switch sessions(s).contingency
       case 'EFLS'
           psth_FexpF = psth;
           save(event_psth_file, 'psth_FexpF', 'tf_tax', '-append');
           clear psth_FexpF
       case 'ESLF'
           psth_FexpS = psth;
           save(event_psth_file, 'psth_FexpS', 'tf_tax','-append');
           clear psth_FexpS
   end
   clear psth
   
   % slow, early, no lick
   [~, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(~fast&early&~licked), [-.5 1.5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_se   = squeeze(nanmean(psth,2));
   sd_resp_se     = squeeze(nanstd(psth,[],2));
   n_resp_se      = size(psth,2);
   
   switch sessions(s).contingency
       case 'EFLS'
           psth_SexpF = psth;
           save(event_psth_file, 'psth_SexpF', '-append');
           clear psth_SexpF
       case 'ESLF'
           psth_SexpS = psth;
           save(event_psth_file, 'psth_SexpS', '-append');
           clear psth_SexpS
   end
   clear psth
   
   % fast, late, no lick
   [tf_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(fast&late&~licked), [-.5 1.5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_fl   = squeeze(nanmean(psth,2));
   sd_resp_fl     = squeeze(nanstd(psth,[],2));
   n_resp_fl      = size(psth,2);
   
   switch sessions(s).contingency
       case 'EFLS'
           psth_FexpS = psth;
           save(event_psth_file, 'psth_FexpS', '-append');
           clear psth_FexpS
       case 'ESLF'
           psth_FexpF = psth;
           save(event_psth_file, 'psth_FexpF', '-append');
           clear psth_FexpF
   end
   clear psth
   
   % slow, late, no lick
   [~, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(~fast&late&~licked), [-.5 1.5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_sl   = squeeze(nanmean(psth,2));
   sd_resp_sl     = squeeze(nanstd(psth,[],2));
   n_resp_sl      = size(psth,2);
   switch sessions(s).contingency
       case 'EFLS'
           psth_SexpS = psth;
           save(event_psth_file, 'psth_SexpS', '-append');
           clear psth_SexpS
       case 'ESLF'
           psth_SexpF = psth;
           save(event_psth_file, 'psth_SexpF', '-append');
           clear psth_SexpF
   end
   clear psth
   
   %% FA (E/L)
   
   [t, tr_t, ~] = get_times_of_events(trials_all{s}, daq_all{s}, ops, 'FA');
   [elts, elt] = get_lick_triggered_stimuli(trials_all{s}, ops);
   elts(elt<ops.minTrialDur,:) = [];
   if size(elts,1) ~= length(t)
       keyboard
   end
      
   % cluster lick-triggered stim
   [dist, idx] = pdist2(clusters, smoothdata(elts(:,21:40), 2, 'movmean', 3), 'euclidean', 'smallest', 2);
   idx = idx(1,:); % nearest
   diff_dist = dist(2,:) - dist(1,:);
   uncertain = diff_dist < thresh;
   idx(idx==1) =-1;
   idx(idx==2) = 1;
   idx(uncertain) = 0;
   
   
   % early, F
   [lick_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(tr_t<flip_time & idx==1), [-1.5 .5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_faEF = squeeze(nanmean(psth,2));
   sd_resp_faEF   = squeeze(nanstd(psth,[],2));
   n_resp_faEF    = size(psth,2);
   switch sessions(s).contingency
       case 'EFLS'
           psth_FAFexpF = psth;
           save(event_psth_file, 'psth_FAFexpF', '-append');
           clear psth_FAFexpF
       case 'ESLF'
           psth_FAFexpS = psth;
           save(event_psth_file, 'psth_FAFexpS', '-append');
           clear psth_FAFexpS
   end
   clear psth
   
   % early, S
   [lick_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(tr_t<flip_time & idx==-1), [-1.5 .5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_faES = squeeze(nanmean(psth,2));
   sd_resp_faES   = squeeze(nanstd(psth,[],2));
   n_resp_faES    = size(psth,2);
   switch sessions(s).contingency
       case 'EFLS'
           psth_FASexpF = psth;
           save(event_psth_file, 'psth_FASexpF', '-append');
           clear psth_FASexpF
       case 'ESLF'
           psth_FASexpS = psth;
           save(event_psth_file, 'psth_FASexpS', '-append');
           clear psth_FASexpS
   end
   clear psth
   
   % early, 0
   [lick_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(tr_t<flip_time & idx==0), [-1.5 .5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_faEM = squeeze(nanmean(psth,2));
   sd_resp_faEM   = squeeze(nanstd(psth,[],2));
   n_resp_faEM    = size(psth,2);
   switch sessions(s).contingency
       case 'EFLS'
           psth_FAMexpF = psth;
           save(event_psth_file, 'psth_FAMexpF', '-append');
           clear psth_FAFMexpF
       case 'ESLF'
           psth_FAMexpS = psth;
           save(event_psth_file, 'psth_FAMexpS', '-append');
           clear psth_FAMexpS
   end
   clear psth
   
   % late, F
   [~, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(tr_t>flip_time & idx==1), [-1.5 .5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_faLF = squeeze(nanmean(psth,2));
   sd_resp_faLF   = squeeze(nanstd(psth,[],2));
   n_resp_faLF    = size(psth,2);
   
   switch sessions(s).contingency
       case 'EFLS'
           psth_FAFexpS = psth;
           save(event_psth_file, 'psth_FAFexpS', 'lick_tax', '-append');
           clear psth_FAFexpS
       case 'ESLF'
           psth_FAFexpF = psth;
           save(event_psth_file, 'psth_FAFexpF', 'lick_tax', '-append');
           clear psth_FAFexpF
   end
   clear psth
      
   % late, S
   [~, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(tr_t>flip_time & idx==-1), [-1.5 .5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_faLS = squeeze(nanmean(psth,2));
   sd_resp_faLS   = squeeze(nanstd(psth,[],2));
   n_resp_faLS    = size(psth,2);
   
   switch sessions(s).contingency
       case 'EFLS'
           psth_FASexpS = psth;
           save(event_psth_file, 'psth_FASexpS', 'lick_tax', '-append');
           clear psth_FASexpS
       case 'ESLF'
           psth_FASexpF = psth;
           save(event_psth_file, 'psth_FASexpF', 'lick_tax', '-append');
           clear psth_FASexpF
   end
   clear psth
   
   % late, M
   [~, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(tr_t>flip_time & idx==0), [-1.5 .5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_faLM = squeeze(nanmean(psth,2));
   sd_resp_faLM   = squeeze(nanstd(psth,[],2));
   n_resp_faLM    = size(psth,2);
   
   switch sessions(s).contingency
       case 'EFLS'
           psth_FAMexpS = psth;
           save(event_psth_file, 'psth_FAMexpS', 'lick_tax', '-append');
           clear psth_FAMexpS
       case 'ESLF'
           psth_FAMexpF = psth;
           save(event_psth_file, 'psth_FAMexpF', 'lick_tax', '-append');
           clear psth_FAMexpF
   end
   clear psth
   
   if ~isfield(time_axes, 'fa')
       time_axes.fa = lick_tax;
   end
   
   %% Changes; hit/miss, exp/U
   
   
   [t, tr_t, info] = get_times_of_events(trials_all{s}, daq_all{s}, ops, 'change');
   
   ch_tfs = info(:,1);
   hit    = info(:,2);
   exp    = info(:,3);
   rts    = info(:,4);
   ch_vals = [.25 1 1.5 2 2.5 3 3.75]-2;
   
   
   for ii = 1:length(ch_vals)
       ch_tf = ch_vals(ii);
       
       % hit, expected
       [ch_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(ch_tfs==ch_tf&hit&exp), [-1 2]);
       psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
       mean_resp_ch(ii).hitE = squeeze(nanmean(psth,2));
       sd_resp_ch(ii).hitE   = squeeze(nanstd(psth,[],2));
       n_resp_ch(ii).hitE    = size(psth,2);
       
       ch_psths.(sprintf('psth_chHE%d', ii)) = psth;
       
       clear psth
       
       % hit, expected, short RT
       mid_rt_range= prctile(rts(ch_tfs==ch_tf&hit&exp), [33 67]);

%        med_RT = median(rts(ch_tfs==ch_tf&hit&exp));
       fast_rt = rts<mid_rt_range(1);
       [ch_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(ch_tfs==ch_tf&hit&exp&fast_rt), [-1 2]);
       psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
       mean_resp_ch(ii).hitEshortRT = squeeze(nanmean(psth,2));
       sd_resp_ch(ii).hitEshortRT   = squeeze(nanstd(psth,[],2));
       n_resp_ch(ii).hitEshortRT    = size(psth,2);
       tr_t_ch(ii).hitEshortRT    = tr_t(ch_tfs==ch_tf&hit&exp&fast_rt);
       ch_psths.(sprintf('psth_chHEshortRT%d', ii)) = psth;
       
       clear psth
       
       % hit, expected, medium RT
       med_rt = isbetween(rts, mid_rt_range);
       [ch_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(ch_tfs==ch_tf&hit&exp&med_rt), [-1 2]);
       psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
       mean_resp_ch(ii).hitEmedRT = squeeze(nanmean(psth,2));
       sd_resp_ch(ii).hitEmedRT   = squeeze(nanstd(psth,[],2));
       n_resp_ch(ii).hitEmedRT    = size(psth,2);
       tr_t_ch(ii).hitEmedRT    = tr_t(ch_tfs==ch_tf&hit&exp&med_rt);
       ch_psths.(sprintf('psth_chHEmedRT%d', ii)) = psth;
       
       clear psth
      
       
       % hit, expected, long RT
       %med_RT = median(rts(ch_tfs==ch_tf&hit&exp));
       long_rt = rts>mid_rt_range(2);
       [ch_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(ch_tfs==ch_tf&hit&exp&long_rt), [-1 2]);
       psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
       mean_resp_ch(ii).hitElongRT = squeeze(nanmean(psth,2));
       sd_resp_ch(ii).hitElongRT   = squeeze(nanstd(psth,[],2));
       n_resp_ch(ii).hitElongRT    = size(psth,2);
       tr_t_ch(ii).hitElongRT   = tr_t(ch_tfs==ch_tf&hit&exp&long_rt);
       ch_psths.(sprintf('psth_chHElongRT%d', ii)) = psth;
       
       clear psth
       
       % hit unexpected
       [~, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(ch_tfs==ch_tf&hit&~exp), [-1 2]);
       psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
       mean_resp_ch(ii).hitU = squeeze(nanmean(psth,2));
       sd_resp_ch(ii).hitU   = squeeze(nanstd(psth,[],2));
       n_resp_ch(ii).hitU    = size(psth,2);
       ch_psths.(sprintf('psth_chHU%d', ii)) = psth;
       clear psth
       
       % miss, expected
       [ch_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(ch_tfs==ch_tf&~hit&exp), [-1 2]);
       psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
       mean_resp_ch(ii).missE = squeeze(nanmean(psth,2));
       sd_resp_ch(ii).missE   = squeeze(nanstd(psth,[],2));
       n_resp_ch(ii).missE    = size(psth,2);
       
       ch_psths.(sprintf('psth_chME%d', ii)) = psth;
       clear psth
       
       % miss unexpected
       [~, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(ch_tfs==ch_tf&~hit&~exp), [-1 2]);
       psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
       mean_resp_ch(ii).missU = squeeze(nanmean(psth,2));
       sd_resp_ch(ii).missU   = squeeze(nanstd(psth,[],2));
       n_resp_ch(ii).missU    = size(psth,2);
       ch_psths.(sprintf('psth_chMU%d', ii)) = psth;
       clear psth
   end
   
   if ~isfield(time_axes, 'ch')
       time_axes.ch = ch_tax;
   end
  save(event_psth_file, '-struct', 'ch_psths', '-append');
  save(event_psth_file,  'ch_tax', '-append');    
  
  %% Hit licks by magnitude
%   keyboard
  [t, tr_t, info] = get_times_of_events(trials_all{s}, daq_all{s}, ops, 'hit');
  ch_tfs = info(:,1);
  exp    = info(:,2);
  %rts    = info(:,3);
  ch_vals = [.25 1 1.5 2 2.5 3 3.75]-2;
  
   for ii = 1:length(ch_vals)
       ch_tf = ch_vals(ii);
       [hit_tax, psth] = get_response_to_event_from_FR_matrix(fr, t_ax, t(ch_tfs==ch_tf&exp), [-2 1]);
       psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
       mean_resp_hit(ii).hitE = squeeze(nanmean(psth,2));
       sd_resp_hit(ii).hitE   = squeeze(nanstd(psth,[],2));
       n_resp_hit(ii).hitE    = size(psth,2);
       
       hit_psths.(sprintf('psth_hitE%d', ii)) = psth;
    
       clear psth
   end
   if ~isfield(time_axes, 'hit')
       time_axes.hit = hit_tax;
   end
  save(event_psth_file, '-struct', 'hit_psths', '-append');
  save(event_psth_file,  'hit_tax', '-append');
   
   %% save to struct, depending on contingency!
   switch sessions(s).contingency
       
       case 'EFLS'
           var_names = {'animal', 'session', 'cid', 'loc', 'FRmu', 'FRsd', ...
                        'bl', 'bl_sd', 'bl_n', ...
                        ... % TF, no lick
                        'FexpF', 'FexpF_sd', 'FexpF_n', ...
                        'SexpF', 'SexpF_sd', 'SexpF_n', ...
                        'FexpS', 'FexpS_sd', 'FexpS_n', ...
                        'SexpS', 'SexpS_sd', 'SexpS_n', ...
                        ... % FA
                        'FAFexpF', 'FAFexpF_sd', 'FAFexpF_n', ...
                        'FASexpF', 'FASexpF_sd', 'FASexpF_n', ...
                        'FAMexpF', 'FAMexpF_sd', 'FAMexpF_n', ...
                        'FAFexpS', 'FAFexpS_sd', 'FAFexpS_n', ...
                        'FASexpS', 'FASexpS_sd', 'FASexpS_n', ...
                        'FAMexpS', 'FAMexpS_sd', 'FAMexpS_n', ...
                        ... % changes, hitE
                        'hitE1', 'hitE1_sd', 'hitE1_n', ...
                        'hitE2', 'hitE2_sd', 'hitE2_n', ...
                        'hitE3', 'hitE3_sd', 'hitE3_n', ...
                        'hitE4', 'hitE4_sd', 'hitE4_n', ...
                        'hitE5', 'hitE5_sd', 'hitE5_n', ...
                        'hitE6', 'hitE6_sd', 'hitE6_n', ...
                        'hitE7', 'hitE7_sd', 'hitE7_n', ...
                        ...% changes, missE 
                        'missE1','missE1_sd','missE1_n', ...
                        'missE2','missE2_sd','missE2_n', ...
                        'missE3','missE3_sd','missE3_n', ...
                        'missE4','missE4_sd','missE4_n', ...
                        'missE5','missE5_sd','missE5_n', ...
                        'missE6','missE6_sd','missE6_n', ...
                        'missE7','missE7_sd','missE7_n', ...
                        ... % changes, hitE - short RT
                        'hitEshort1', 'hitEshort1_sd', 'hitEshort1_n', 'hitEshort1_tr_t', ...
                        'hitEshort2', 'hitEshort2_sd', 'hitEshort2_n', 'hitEshort2_tr_t', ...
                        'hitEshort3', 'hitEshort3_sd', 'hitEshort3_n', 'hitEshort3_tr_t', ...
                        'hitEshort4', 'hitEshort4_sd', 'hitEshort4_n', 'hitEshort4_tr_t', ...
                        'hitEshort5', 'hitEshort5_sd', 'hitEshort5_n', 'hitEshort5_tr_t', ...
                        'hitEshort6', 'hitEshort6_sd', 'hitEshort6_n', 'hitEshort6_tr_t', ...
                        'hitEshort7', 'hitEshort7_sd', 'hitEshort7_n', 'hitEshort7_tr_t', ...
                        ... % changes, hitE - med RT
                        'hitEmed1', 'hitEmed1_sd', 'hitEmed1_n', 'hitEmed1_tr_t', ...
                        'hitEmed2', 'hitEmed2_sd', 'hitEmed2_n', 'hitEmed2_tr_t', ...
                        'hitEmed3', 'hitEmed3_sd', 'hitEmed3_n', 'hitEmed3_tr_t', ...
                        'hitEmed4', 'hitEmed4_sd', 'hitEmed4_n', 'hitEmed4_tr_t', ...
                        'hitEmed5', 'hitEmed5_sd', 'hitEmed5_n', 'hitEmed5_tr_t', ...
                        'hitEmed6', 'hitEmed6_sd', 'hitEmed6_n', 'hitEmed6_tr_t', ...
                        'hitEmed7', 'hitEmed7_sd', 'hitEmed7_n', 'hitEmed7_tr_t', ...
                        ... % changes, hitE - long RT
                        'hitElong1', 'hitElong1_sd', 'hitElong1_n', 'hitElong1_tr_t', ...
                        'hitElong2', 'hitElong2_sd', 'hitElong2_n', 'hitElong2_tr_t', ...
                        'hitElong3', 'hitElong3_sd', 'hitElong3_n', 'hitElong3_tr_t', ...
                        'hitElong4', 'hitElong4_sd', 'hitElong4_n', 'hitElong4_tr_t', ...
                        'hitElong5', 'hitElong5_sd', 'hitElong5_n', 'hitElong5_tr_t', ...
                        'hitElong6', 'hitElong6_sd', 'hitElong6_n', 'hitElong6_tr_t', ...
                        'hitElong7', 'hitElong7_sd', 'hitElong7_n', 'hitElong7_tr_t', ...
                        ... % hit licks
                        'hitLickE1', 'hitLickE1_sd', 'hitLickE1_n', ...
                        'hitLickE2', 'hitLickE2_sd', 'hitLickE2_n', ...
                        'hitLickE3', 'hitLickE3_sd', 'hitLickE3_n', ...
                        'hitLickE4', 'hitLickE4_sd', 'hitLickE4_n', ...
                        'hitLickE5', 'hitLickE5_sd', 'hitLickE5_n', ...
                        'hitLickE6', 'hitLickE6_sd', 'hitLickE6_n', ...
                        'hitLickE7', 'hitLickE7_sd', 'hitLickE7_n'};
       case 'ESLF'
           var_names = {'animal', 'session', 'cid', 'loc', 'FRmu', 'FRsd', ...
                        'bl', 'bl_sd', 'bl_n', ...
                        ... % TF, no lick
                        'FexpS', 'FexpS_sd', 'FexpS_n', ...
                        'SexpS', 'SexpS_sd', 'SexpS_n', ...
                        'FexpF', 'FexpF_sd', 'FexpF_n', ...
                        'SexpF', 'SexpF_sd', 'SexpF_n', ...
                        ... % FA
                        'FAFexpS', 'FAFexpS_sd', 'FAFexpS_n', ...
                        'FASexpS', 'FASexpS_sd', 'FASexpS_n', ...
                        'FAMexpS', 'FAMexpS_sd', 'FAMexpS_n', ...
                        'FAFexpF', 'FAFexpF_sd', 'FAFexpF_n', ...
                        'FASexpF', 'FASexpF_sd', 'FASexpF_n', ...
                        'FAMexpF', 'FAMexpF_sd', 'FAMexpF_n', ...
                        ... % changes, hitE
                        'hitE1', 'hitE1_sd', 'hitE1_n', ...
                        'hitE2', 'hitE2_sd', 'hitE2_n', ...
                        'hitE3', 'hitE3_sd', 'hitE3_n', ...
                        'hitE4', 'hitE4_sd', 'hitE4_n', ...
                        'hitE5', 'hitE5_sd', 'hitE5_n', ...
                        'hitE6', 'hitE6_sd', 'hitE6_n', ...
                        'hitE7', 'hitE7_sd', 'hitE7_n', ...
                        ...% changes, missE 
                        'missE1','missE1_sd','missE1_n', ...
                        'missE2','missE2_sd','missE2_n', ...
                        'missE3','missE3_sd','missE3_n', ...
                        'missE4','missE4_sd','missE4_n', ...
                        'missE5','missE5_sd','missE5_n', ...
                        'missE6','missE6_sd','missE6_n', ...
                        'missE7','missE7_sd','missE7_n', ...
                        ... % changes, hitE - short RT
                        'hitEshort1', 'hitEshort1_sd', 'hitEshort1_n', 'hitEshort1_tr_t', ...
                        'hitEshort2', 'hitEshort2_sd', 'hitEshort2_n', 'hitEshort2_tr_t', ...
                        'hitEshort3', 'hitEshort3_sd', 'hitEshort3_n', 'hitEshort3_tr_t', ...
                        'hitEshort4', 'hitEshort4_sd', 'hitEshort4_n', 'hitEshort4_tr_t', ...
                        'hitEshort5', 'hitEshort5_sd', 'hitEshort5_n', 'hitEshort5_tr_t', ...
                        'hitEshort6', 'hitEshort6_sd', 'hitEshort6_n', 'hitEshort6_tr_t', ...
                        'hitEshort7', 'hitEshort7_sd', 'hitEshort7_n', 'hitEshort7_tr_t', ...
                        ... % changes, hitE - med RT
                        'hitEmed1', 'hitEmed1_sd', 'hitEmed1_n', 'hitEmed1_tr_t', ...
                        'hitEmed2', 'hitEmed2_sd', 'hitEmed2_n', 'hitEmed2_tr_t', ...
                        'hitEmed3', 'hitEmed3_sd', 'hitEmed3_n', 'hitEmed3_tr_t', ...
                        'hitEmed4', 'hitEmed4_sd', 'hitEmed4_n', 'hitEmed4_tr_t', ...
                        'hitEmed5', 'hitEmed5_sd', 'hitEmed5_n', 'hitEmed5_tr_t', ...
                        'hitEmed6', 'hitEmed6_sd', 'hitEmed6_n', 'hitEmed6_tr_t', ...
                        'hitEmed7', 'hitEmed7_sd', 'hitEmed7_n', 'hitEmed7_tr_t', ...
                        ... % changes, hitE - long RT
                        'hitElong1', 'hitElong1_sd', 'hitElong1_n', 'hitElong1_tr_t', ...
                        'hitElong2', 'hitElong2_sd', 'hitElong2_n', 'hitElong2_tr_t', ...
                        'hitElong3', 'hitElong3_sd', 'hitElong3_n', 'hitElong3_tr_t', ...
                        'hitElong4', 'hitElong4_sd', 'hitElong4_n', 'hitElong4_tr_t', ...
                        'hitElong5', 'hitElong5_sd', 'hitElong5_n', 'hitElong5_tr_t', ...
                        'hitElong6', 'hitElong6_sd', 'hitElong6_n', 'hitElong6_tr_t', ...
                        'hitElong7', 'hitElong7_sd', 'hitElong7_n', 'hitElong7_tr_t', ...
                        ... % hit licks
                        'hitLickE1', 'hitLickE1_sd', 'hitLickE1_n', ...
                        'hitLickE2', 'hitLickE2_sd', 'hitLickE2_n', ...
                        'hitLickE3', 'hitLickE3_sd', 'hitLickE3_n', ...
                        'hitLickE4', 'hitLickE4_sd', 'hitLickE4_n', ...
                        'hitLickE5', 'hitLickE5_sd', 'hitLickE5_n', ...
                        'hitLickE6', 'hitLickE6_sd', 'hitLickE6_n', ...
                        'hitLickE7', 'hitLickE7_sd', 'hitLickE7_n'};
           
   end
   
   r = table(repelem(animal,nN,1), repelem(sess,nN,1), sp.cids, sp.clu_locs', fr_mu, fr_sd, ...
             mean_resp_bl,   sd_resp_bl,   repelem(n_resp_bl,nN,1), ...
             ... % TF, no lick
             mean_resp_fe,   sd_resp_fe,   repelem(n_resp_fe,nN,1), ...
             mean_resp_se,   sd_resp_se,   repelem(n_resp_se,nN,1), ...
             mean_resp_fl,   sd_resp_fl,   repelem(n_resp_fl,nN,1), ...
             mean_resp_sl,   sd_resp_sl,   repelem(n_resp_sl,nN,1), ...
             ... %FA
             mean_resp_faEF,   sd_resp_faEF,   repelem(n_resp_faEF,nN,1), ...
             mean_resp_faES,   sd_resp_faES,   repelem(n_resp_faES,nN,1), ...
             mean_resp_faEM,   sd_resp_faEM,   repelem(n_resp_faEM,nN,1), ...
             mean_resp_faLF,   sd_resp_faLF,   repelem(n_resp_faLF,nN,1), ...
             mean_resp_faLS,   sd_resp_faLS,   repelem(n_resp_faLS,nN,1), ...
             mean_resp_faLM,   sd_resp_faLM,   repelem(n_resp_faLM,nN,1), ...
             ... % changes, hitE
             mean_resp_ch(1).hitE, sd_resp_ch(1).hitE, repelem(n_resp_ch(1).hitE,nN,1), ...
             mean_resp_ch(2).hitE, sd_resp_ch(2).hitE, repelem(n_resp_ch(2).hitE,nN,1), ...
             mean_resp_ch(3).hitE, sd_resp_ch(3).hitE, repelem(n_resp_ch(3).hitE,nN,1), ...
             mean_resp_ch(4).hitE, sd_resp_ch(4).hitE, repelem(n_resp_ch(4).hitE,nN,1), ...
             mean_resp_ch(5).hitE, sd_resp_ch(5).hitE, repelem(n_resp_ch(5).hitE,nN,1), ...
             mean_resp_ch(6).hitE, sd_resp_ch(6).hitE, repelem(n_resp_ch(6).hitE,nN,1), ...
             mean_resp_ch(7).hitE, sd_resp_ch(7).hitE, repelem(n_resp_ch(7).hitE,nN,1), ...
             ... % changes, missE
             mean_resp_ch(1).missE, sd_resp_ch(1).missE, repelem(n_resp_ch(1).missE,nN,1), ...
             mean_resp_ch(2).missE, sd_resp_ch(2).missE, repelem(n_resp_ch(2).missE,nN,1), ...
             mean_resp_ch(3).missE, sd_resp_ch(3).missE, repelem(n_resp_ch(3).missE,nN,1), ...
             mean_resp_ch(4).missE, sd_resp_ch(4).missE, repelem(n_resp_ch(4).missE,nN,1), ...
             mean_resp_ch(5).missE, sd_resp_ch(5).missE, repelem(n_resp_ch(5).missE,nN,1), ...
             mean_resp_ch(6).missE, sd_resp_ch(6).missE, repelem(n_resp_ch(6).missE,nN,1), ...
             mean_resp_ch(7).missE, sd_resp_ch(7).missE, repelem(n_resp_ch(7).missE,nN,1), ...
             ... % changes, hitE -short RT
             mean_resp_ch(1).hitEshortRT, sd_resp_ch(1).hitEshortRT, repelem(n_resp_ch(1).hitEshortRT,nN,1), repmat(tr_t_ch(1).hitEshortRT,nN,1), ...
             mean_resp_ch(2).hitEshortRT, sd_resp_ch(2).hitEshortRT, repelem(n_resp_ch(2).hitEshortRT,nN,1), repmat(tr_t_ch(2).hitEshortRT,nN,1), ...
             mean_resp_ch(3).hitEshortRT, sd_resp_ch(3).hitEshortRT, repelem(n_resp_ch(3).hitEshortRT,nN,1), repmat(tr_t_ch(3).hitEshortRT,nN,1), ...
             mean_resp_ch(4).hitEshortRT, sd_resp_ch(4).hitEshortRT, repelem(n_resp_ch(4).hitEshortRT,nN,1), repmat(tr_t_ch(4).hitEshortRT,nN,1), ...
             mean_resp_ch(5).hitEshortRT, sd_resp_ch(5).hitEshortRT, repelem(n_resp_ch(5).hitEshortRT,nN,1), repmat(tr_t_ch(5).hitEshortRT,nN,1), ...
             mean_resp_ch(6).hitEshortRT, sd_resp_ch(6).hitEshortRT, repelem(n_resp_ch(6).hitEshortRT,nN,1), repmat(tr_t_ch(6).hitEshortRT,nN,1), ...
             mean_resp_ch(7).hitEshortRT, sd_resp_ch(7).hitEshortRT, repelem(n_resp_ch(7).hitEshortRT,nN,1), repmat(tr_t_ch(7).hitEshortRT,nN,1), ...
             ... % changes, hitE -med RT
             mean_resp_ch(1).hitEmedRT, sd_resp_ch(1).hitEmedRT, repelem(n_resp_ch(1).hitEmedRT,nN,1), repmat(tr_t_ch(1).hitEmedRT,nN,1), ...
             mean_resp_ch(2).hitEmedRT, sd_resp_ch(2).hitEmedRT, repelem(n_resp_ch(2).hitEmedRT,nN,1), repmat(tr_t_ch(2).hitEmedRT,nN,1), ...
             mean_resp_ch(3).hitEmedRT, sd_resp_ch(3).hitEmedRT, repelem(n_resp_ch(3).hitEmedRT,nN,1), repmat(tr_t_ch(3).hitEmedRT,nN,1), ...
             mean_resp_ch(4).hitEmedRT, sd_resp_ch(4).hitEmedRT, repelem(n_resp_ch(4).hitEmedRT,nN,1), repmat(tr_t_ch(4).hitEmedRT,nN,1), ...
             mean_resp_ch(5).hitEmedRT, sd_resp_ch(5).hitEmedRT, repelem(n_resp_ch(5).hitEmedRT,nN,1), repmat(tr_t_ch(5).hitEmedRT,nN,1), ...
             mean_resp_ch(6).hitEmedRT, sd_resp_ch(6).hitEmedRT, repelem(n_resp_ch(6).hitEmedRT,nN,1), repmat(tr_t_ch(6).hitEmedRT,nN,1), ...
             mean_resp_ch(7).hitEmedRT, sd_resp_ch(7).hitEmedRT, repelem(n_resp_ch(7).hitEmedRT,nN,1), repmat(tr_t_ch(7).hitEmedRT,nN,1), ...
            ... % changes, hitE -long RT
             mean_resp_ch(1).hitElongRT, sd_resp_ch(1).hitElongRT, repelem(n_resp_ch(1).hitElongRT,nN,1), repmat(tr_t_ch(1).hitElongRT,nN,1), ...
             mean_resp_ch(2).hitElongRT, sd_resp_ch(2).hitElongRT, repelem(n_resp_ch(2).hitElongRT,nN,1), repmat(tr_t_ch(2).hitElongRT,nN,1), ...
             mean_resp_ch(3).hitElongRT, sd_resp_ch(3).hitElongRT, repelem(n_resp_ch(3).hitElongRT,nN,1), repmat(tr_t_ch(3).hitElongRT,nN,1), ...
             mean_resp_ch(4).hitElongRT, sd_resp_ch(4).hitElongRT, repelem(n_resp_ch(4).hitElongRT,nN,1), repmat(tr_t_ch(4).hitElongRT,nN,1), ...
             mean_resp_ch(5).hitElongRT, sd_resp_ch(5).hitElongRT, repelem(n_resp_ch(5).hitElongRT,nN,1), repmat(tr_t_ch(5).hitElongRT,nN,1), ...
             mean_resp_ch(6).hitElongRT, sd_resp_ch(6).hitElongRT, repelem(n_resp_ch(6).hitElongRT,nN,1), repmat(tr_t_ch(6).hitElongRT,nN,1), ...
             mean_resp_ch(7).hitElongRT, sd_resp_ch(7).hitElongRT, repelem(n_resp_ch(7).hitElongRT,nN,1), repmat(tr_t_ch(7).hitElongRT,nN,1), ...
            ... % hit licks
             mean_resp_hit(1).hitE, sd_resp_hit(1).hitE, repelem(n_resp_hit(1).hitE,nN,1), ...
             mean_resp_hit(2).hitE, sd_resp_hit(2).hitE, repelem(n_resp_hit(2).hitE,nN,1), ...
             mean_resp_hit(3).hitE, sd_resp_hit(3).hitE, repelem(n_resp_hit(3).hitE,nN,1), ...
             mean_resp_hit(4).hitE, sd_resp_hit(4).hitE, repelem(n_resp_hit(4).hitE,nN,1), ...
             mean_resp_hit(5).hitE, sd_resp_hit(5).hitE, repelem(n_resp_hit(5).hitE,nN,1), ...
             mean_resp_hit(6).hitE, sd_resp_hit(6).hitE, repelem(n_resp_hit(6).hitE,nN,1), ...
             mean_resp_hit(7).hitE, sd_resp_hit(7).hitE, repelem(n_resp_hit(7).hitE,nN,1), ...
             ...
             'VariableNames', var_names);
%    if s==17
%        keyboard
%    end
   
   % save session data
   save(fullfile(strrep(ops.eventPSTHdir, 'event_responses', 'avg_responses'), sprintf('%s_%s.mat', animal, sess)),...
        'r', 'time_axes', 'ops', '-v7.3');
    
   clearvars -except sessions trials_all sp_all daq_all ops s clusters flip_times animals thresh time_axes

%    resps = vertcat(resps,r); 
%     catch
%         fprintf('Failed for session %d.\n', s)
%     end
end



end








