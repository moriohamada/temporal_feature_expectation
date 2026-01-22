function calculate_unit_responses(sessions, trials_all, daq_all, sp_all, ops)

%%
fprintf('Getting event-aligned responses for every unit\n')

%  get flip times  
flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');

resps = table;
time_axes = struct;
mkdir(ops.eventPSTHdir)

%% Iterate through every session to store event responses, and get responses for every unit.
animals = unique({sessions.animal});

for s =  1:length(sessions)
    
   fprintf('session %d/%d\n', s, length(sessions))

   if s > length(sp_all)
       continue
   end
   if isempty(sp_all{s}) % not recording session
        continue
   end
   
   animal = sessions(s).animal;
   sess   = sessions(s).session;
   
   % get flip time
   animal_id = strcmp(animals, animal);
   flip_time = flip_times(animal_id);
   
   event_psth_file = fullfile(ops.eventPSTHdir, sprintf('%s_%s.mat', animal, sess));
    
   % create FR matrix
   sp = sp_all{s};
   nN = length(sp.cids);
   daq = daq_all{s};
   
   [fr, t_ax] = utils.spike_times_to_fr(sp, ops.spBinWidth);
   [fr, t_ax] = utils.remove_out_of_trial_fr(fr, t_ax, daq);
   % [fr_bl, ~] = utils.remove_non_baseline_fr(fr, t_ax, daq, ops);
   fr = fr/(ops.spBinWidth/1000);
   % fr_bl = fr_bl/(ops.spBinWidth/1000);
   
   % smooth FR
   fr = smoothdata(fr, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);
   fr_mu = mean(fr,2);
   fr_sd = std(fr,[],2);
   
   % clear fr_bl
   
   % save FR mu, sd
   save(event_psth_file, 'fr_mu', 'fr_sd', '-v7.3');
   
   %% Baseline activity

   % temporarily change min trial dur
   mintrdur = ops.minTrialDur;
   ops.minTrialDur = 10 + ops.rmvTimeAround;
   [t, ~, bl_info] = utils.get_times_of_events(trials_all{s}, daq_all{s}, ops, 'baseline onset');
   ops.minTrialDur = mintrdur;
   
   [bl_tax, psth] = utils.get_response_to_event_from_FR_matrix(fr, t_ax, t, [-2 11]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth*5,0]);
   mean_resp_bl = squeeze(nanmean(psth,2));
   sd_resp_bl   = squeeze(nanstd(psth,[],2));
   n_resp_bl    = size(psth,2);
   if ~isfield(time_axes, 'bl')
       time_axes.bl = bl_tax;
   end
   bl_psth = psth;
   save(event_psth_file, 'bl_psth', 'bl_tax', 'bl_info', '-append');
   clear psth bl_psth   
   
   %% TF pulses
    
   [t, tr_t, tf_info] = utils.get_times_of_events(trials_all{s}, daq_all{s}, ops, 'tf');
   
   fast   = tf_info(:,1)>0;
   slow   = tf_info(:,1)<0;

   early  = tr_t' < flip_time  & tr_t' > ops.rmvTimeAround;
   late   = tr_t' > flip_time;
   licked = tf_info(:,2)==1;
   
   if strcmp(sessions(s).contingency, 'ESLF') % swap early and late definitions
       early_true = early; 
       late_true  = late;
       early = late_true; 
       late = early_true;
       clear early_true late_true
   end
   
   % fast, expf
   [tf_tax, psth] = utils.get_response_to_event_from_FR_matrix(fr, t_ax, t(fast&early&~licked), [-.5 1.5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_fexpf   = squeeze(nanmean(psth,2));
   sd_resp_fexpf     = squeeze(nanstd(psth,[],2));
   n_resp_fexpf      = size(psth,2);
   
   psth_FexpF = psth;
   save(event_psth_file, 'psth_FexpF', 'tf_tax', '-append');
   clear psth_FexpF
   clear psth
   
   % slow, expf
   [~, psth] = utils.get_response_to_event_from_FR_matrix(fr, t_ax, t(slow&early&~licked), [-.5 1.5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_sexpf   = squeeze(nanmean(psth,2));
   sd_resp_sexpf     = squeeze(nanstd(psth,[],2));
   n_resp_sexpf      = size(psth,2);
 
   psth_SexpF = psth;
   save(event_psth_file, 'psth_SexpF', '-append');
   clear psth_SexpF
   clear psth
   
   % fast, exps
   [~, psth] = utils.get_response_to_event_from_FR_matrix(fr, t_ax, t(fast&late&~licked), [-.5 1.5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_fexps   = squeeze(nanmean(psth,2));
   sd_resp_fexps     = squeeze(nanstd(psth,[],2));
   n_resp_fexps      = size(psth,2);
    
   psth_FexpS = psth;
   save(event_psth_file, 'psth_FexpS', '-append');
   clear psth_FexpS
   clear psth
   
   % slow, exps
   [~, psth] = utils.get_response_to_event_from_FR_matrix(fr, t_ax, t(slow&late&~licked), [-.5 1.5]);
   psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
   mean_resp_sexps   = squeeze(nanmean(psth,2));
   sd_resp_sexps     = squeeze(nanstd(psth,[],2));
   n_resp_sexps      = size(psth,2); 
   
   psth_SexpS = psth;
   save(event_psth_file, 'psth_SexpS', '-append');
   clear psth_SexpS
   clear psth
   
   
   if ~isfield(time_axes, 'tf')
       time_axes.tf = tf_tax;
   end
   
   %% False alarms
   
   [t, tr_t, ~] = utils.get_times_of_events(trials_all{s}, daq_all{s}, ops, 'FA');
   
   switch sessions(s).contingency
       case 'EFLS'
           expf = tr_t<flip_time;
           exps = tr_t>flip_time;
       case 'ESLF'
           exps = tr_t<flip_time;
           expf = tr_t>flip_time;
   end
   
   
   % expf
   [lick_tax, psth] = utils.get_response_to_event_from_FR_matrix(fr, t_ax, t(expf), [-1.5 .5]);
   mean_resp_expf = squeeze(nanmean(psth,2));
   sd_resp_expf   = squeeze(nanstd(psth,[],2));
   n_resp_expf    = size(psth,2);
 
   psth_FAexpF = psth;
   save(event_psth_file, 'lick_tax', 'psth_FAexpF', '-append')
    
   % late
   
   [~, psth] = utils.get_response_to_event_from_FR_matrix(fr, t_ax, t(exps), [-1.5 .5]);
   mean_resp_exps = squeeze(nanmean(psth,2));
   sd_resp_exps   = squeeze(nanstd(psth,[],2));
   n_resp_exps    = size(psth,2);
    
   psth_FAexpS = psth;
   save(event_psth_file, 'psth_FAexpS', '-append')
   clear psth psth_FAexpF psth_FAexpS
   
   
   if ~isfield(time_axes, 'lick')
       time_axes.lick = lick_tax;
   end
   
   %% Changes
   
   
   [t, tr_t, info] = utils.get_times_of_events(trials_all{s}, daq_all{s}, ops, 'change');
   
   ch_tfs = info(:,1);
   hit    = info(:,2);
   exp    = info(:,3);
   rts    = info(:,4);
   ch_vals = [.25 1 1.5 2 2.5 3 3.75]-2;
   
   for ii = 1:length(ch_vals)
       
       ch_tf = ch_vals(ii);
       
       % expected hits - all
       [ch_tax, psth] = utils.get_response_to_event_from_FR_matrix(fr, t_ax, t(ch_tfs==ch_tf&hit&exp), [-1 2]);
       psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
       mean_resp_ch(ii).hitE = squeeze(nanmean(psth,2));
       sd_resp_ch(ii).hitE   = squeeze(nanstd(psth,[],2));
       n_resp_ch(ii).hitE    = size(psth,2);
       
       ch_psths.(sprintf('psth_chHE%d', ii)) = psth;
       
       clear psth
       
       % split RT into 3
       mid_rt_range= prctile(rts(ch_tfs==ch_tf&hit&exp), [33 67]);
       
       % expected hits, short RT
       fast_rt = rts<mid_rt_range(1);
       [ch_tax, psth] = utils.get_response_to_event_from_FR_matrix(fr, t_ax, t(ch_tfs==ch_tf&hit&exp&fast_rt), [-1 2]);
       psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
       mean_resp_ch(ii).hitEshortRT = squeeze(nanmean(psth,2));
       sd_resp_ch(ii).hitEshortRT   = squeeze(nanstd(psth,[],2));
       n_resp_ch(ii).hitEshortRT    = size(psth,2);
       tr_t_ch(ii).hitEshortRT    = tr_t(ch_tfs==ch_tf&hit&exp&fast_rt);
       ch_psths.(sprintf('psth_chHEshortRT%d', ii)) = psth;
       
       clear psth
       
       % expected hits, long RT
       long_rt = rts>mid_rt_range(2);
       [ch_tax, psth] = utils.get_response_to_event_from_FR_matrix(fr, t_ax, t(ch_tfs==ch_tf&hit&exp&long_rt), [-1 2]);
       psth = smoothdata(psth,3,'movmean',[ops.spSmoothSize/ops.spBinWidth,0]);
       mean_resp_ch(ii).hitElongRT = squeeze(nanmean(psth,2));
       sd_resp_ch(ii).hitElongRT   = squeeze(nanstd(psth,[],2));
       n_resp_ch(ii).hitElongRT    = size(psth,2);
       tr_t_ch(ii).hitElongRT      = tr_t(ch_tfs==ch_tf&hit&exp&long_rt);
       ch_psths.(sprintf('psth_chHElongRT%d', ii)) = psth;
       
       clear psth
       
   end
   
   if ~isfield(time_axes, 'ch')
       time_axes.ch = ch_tax;
   end
   save(event_psth_file, '-struct', 'ch_psths', '-append');
   save(event_psth_file,  'ch_tax', '-append');
   
   
   %% Hit licks
   
   [t, tr_t, info] = utils.get_times_of_events(trials_all{s}, daq_all{s}, ops, 'hit');
   ch_tfs = info(:,1);
   exp    = info(:,2);
   ch_vals = [.25 1 1.5 2 2.5 3 3.75]-2;
   
   for ii = 1:length(ch_vals)
       ch_tf = ch_vals(ii);
       [hit_tax, psth] = utils.get_response_to_event_from_FR_matrix(fr, t_ax, t(ch_tfs==ch_tf&exp), [-2 1]);
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
   
   %% save averages
   var_names = {'animal', 'session', 'cid', 'loc', 'FRmu', 'FRsd', ...
                'bl', 'bl_sd', 'bl_n', ...
                ... % TF, no lick
                'FexpF', 'FexpF_sd', 'FexpF_n', ...
                'SexpF', 'SexpF_sd', 'SexpF_n', ...
                'FexpS', 'FexpS_sd', 'FexpS_n', ...
                'SexpS', 'SexpS_sd', 'SexpS_n', ...
                ... % FA
                'FAexpF', 'FAexpF_sd', 'FAexpF_n', ...
                'FAexpS', 'FAexpS_sd', 'FAexpS_n', ...
                ... % changes, hitE
                'hitE1', 'hitE1_sd', 'hitE1_n', ...
                'hitE2', 'hitE2_sd', 'hitE2_n', ...
                'hitE3', 'hitE3_sd', 'hitE3_n', ...
                'hitE4', 'hitE4_sd', 'hitE4_n', ...
                'hitE5', 'hitE5_sd', 'hitE5_n', ...
                'hitE6', 'hitE6_sd', 'hitE6_n', ...
                'hitE7', 'hitE7_sd', 'hitE7_n', ...
                ... % changes, hitE - short RT
                'hitEshort1', 'hitEshort1_sd', 'hitEshort1_n', 'hitEshort1_tr_t', ...
                'hitEshort2', 'hitEshort2_sd', 'hitEshort2_n', 'hitEshort2_tr_t', ...
                'hitEshort3', 'hitEshort3_sd', 'hitEshort3_n', 'hitEshort3_tr_t', ...
                'hitEshort4', 'hitEshort4_sd', 'hitEshort4_n', 'hitEshort4_tr_t', ...
                'hitEshort5', 'hitEshort5_sd', 'hitEshort5_n', 'hitEshort5_tr_t', ...
                'hitEshort6', 'hitEshort6_sd', 'hitEshort6_n', 'hitEshort6_tr_t', ...
                'hitEshort7', 'hitEshort7_sd', 'hitEshort7_n', 'hitEshort7_tr_t', ...
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
             
    r = table(repelem(animal,nN,1), repelem(sess,nN,1), sp.cids, sp.clu_locs', fr_mu, fr_sd, ...
              mean_resp_bl, sd_resp_bl, repelem(n_resp_bl,nN,1), ...
              ... % TF, no lick
              mean_resp_fexpf,   sd_resp_fexpf,   repelem(n_resp_fexpf,nN,1), ...
              mean_resp_sexpf,   sd_resp_sexpf,   repelem(n_resp_sexpf,nN,1), ...
              mean_resp_fexps,   sd_resp_fexps,   repelem(n_resp_fexps,nN,1), ...
              mean_resp_sexps,   sd_resp_sexps,   repelem(n_resp_sexps,nN,1), ...
              ... % FAs
              mean_resp_expf, sd_resp_expf, repelem(n_resp_expf, nN, 1), ...
              mean_resp_exps, sd_resp_exps, repelem(n_resp_exps, nN, 1), ...
              ... % changes, hitE
              mean_resp_ch(1).hitE, sd_resp_ch(1).hitE, repelem(n_resp_ch(1).hitE,nN,1), ...
              mean_resp_ch(2).hitE, sd_resp_ch(2).hitE, repelem(n_resp_ch(2).hitE,nN,1), ...
              mean_resp_ch(3).hitE, sd_resp_ch(3).hitE, repelem(n_resp_ch(3).hitE,nN,1), ...
              mean_resp_ch(4).hitE, sd_resp_ch(4).hitE, repelem(n_resp_ch(4).hitE,nN,1), ...
              mean_resp_ch(5).hitE, sd_resp_ch(5).hitE, repelem(n_resp_ch(5).hitE,nN,1), ...
              mean_resp_ch(6).hitE, sd_resp_ch(6).hitE, repelem(n_resp_ch(6).hitE,nN,1), ...
              mean_resp_ch(7).hitE, sd_resp_ch(7).hitE, repelem(n_resp_ch(7).hitE,nN,1), ...
              ... % changes, hitE -short RT
             mean_resp_ch(1).hitEshortRT, sd_resp_ch(1).hitEshortRT, repelem(n_resp_ch(1).hitEshortRT,nN,1), repmat(tr_t_ch(1).hitEshortRT,nN,1), ...
             mean_resp_ch(2).hitEshortRT, sd_resp_ch(2).hitEshortRT, repelem(n_resp_ch(2).hitEshortRT,nN,1), repmat(tr_t_ch(2).hitEshortRT,nN,1), ...
             mean_resp_ch(3).hitEshortRT, sd_resp_ch(3).hitEshortRT, repelem(n_resp_ch(3).hitEshortRT,nN,1), repmat(tr_t_ch(3).hitEshortRT,nN,1), ...
             mean_resp_ch(4).hitEshortRT, sd_resp_ch(4).hitEshortRT, repelem(n_resp_ch(4).hitEshortRT,nN,1), repmat(tr_t_ch(4).hitEshortRT,nN,1), ...
             mean_resp_ch(5).hitEshortRT, sd_resp_ch(5).hitEshortRT, repelem(n_resp_ch(5).hitEshortRT,nN,1), repmat(tr_t_ch(5).hitEshortRT,nN,1), ...
             mean_resp_ch(6).hitEshortRT, sd_resp_ch(6).hitEshortRT, repelem(n_resp_ch(6).hitEshortRT,nN,1), repmat(tr_t_ch(6).hitEshortRT,nN,1), ...
             mean_resp_ch(7).hitEshortRT, sd_resp_ch(7).hitEshortRT, repelem(n_resp_ch(7).hitEshortRT,nN,1), repmat(tr_t_ch(7).hitEshortRT,nN,1), ...
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
 
         
    
   % save session data
   save(fullfile(ops.avgPSTHdir, sprintf('%s_%s.mat', animal, sess)),...
        'r', 'time_axes', 'ops', '-v7.3');
   clearvars -except sessions trials_all sp_all daq_all ops s flip_times animals time_axes

end


