function indexes = calculate_tf_preference_zscored(avg_resps, t_ax, indexes, ops)
% 
% Calculate TF preference based on z-scored average activity
% 
% --------------------------------------------------------------------------------------------------
%%
nN = height(avg_resps);

% get normalized psths
ev_types = {'FexpF', 'FexpS', 'SexpF', 'SexpS'};

norm_win = isbetween(t_ax.tf, ops.respWin.tfContext);

for evi = 1:length(ev_types)
    ev = ev_types{evi};
    psth = avg_resps.(ev);
    psth = smoothdata(psth, 2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);
    % store z-scored responses
    norm = nanstd(psth(:, norm_win),[],2); norm(norm==0) = inf;
    psths.(ev) = (psth - nanmean(psth(:,norm_win), 2))./norm;
end 
psths.F = (psths.FexpF + psths.FexpS)/2; % just simple mean
psths.S = (psths.SexpF + psths.SexpS)/2;

% define comparison types
comps = {'F', 'S', ''; ...
         'FexpF', 'SexpF', 'ExpF'; ...
         'FexpS', 'SexpS', 'ExpS'};
     
resp_win = isbetween(t_ax.tf, [0.05 .35]);
rel_tax = t_ax.tf(resp_win);

prefs = table();

for c = 1:height(comps)
    
    resp_f = psths.(comps{c,1})(:, resp_win);
    resp_s = psths.(comps{c,2})(:, resp_win);
    resp_d = resp_f - resp_s; % difference
     
    % get absolute maxes
    [abspeak_f, abspeak_time_f] = absoluteMax(resp_f);
    [abspeak_s, abspeak_time_s] = absoluteMax(resp_s);
    [abspeak_d, abspeak_time_d] = absoluteMax(resp_d); 
 
    prefs.(sprintf('tf%s_z_absPeakF', comps{c,3})) = abspeak_f;
    prefs.(sprintf('tf%s_z_absPeakS', comps{c,3})) = abspeak_s;
    prefs.(sprintf('tf%s_z_absPeakD', comps{c,3})) = abspeak_d;
    prefs.(sprintf('tf%s_z_absPeakTimeF', comps{c,3})) = abspeak_time_f;
    prefs.(sprintf('tf%s_z_absPeakTimeS', comps{c,3})) = abspeak_time_s;
    prefs.(sprintf('tf%s_z_absPeakTimeD', comps{c,3})) = abspeak_time_d;

    [peak_f, peak_time_f] = utils.findFirstAbsPeaks(resp_f);
    [peak_s, peak_time_s] = utils.findFirstAbsPeaks(resp_s);
    [peak_d, peak_time_d] = utils.findFirstAbsPeaks(resp_d); 

    prefs.(sprintf('tf%s_z_peakF', comps{c,3})) = peak_f;
    prefs.(sprintf('tf%s_z_peakS', comps{c,3})) = peak_s;
    prefs.(sprintf('tf%s_z_peakD', comps{c,3})) = peak_d;
    prefs.(sprintf('tf%s_z_peakTimeF', comps{c,3})) = peak_time_f;
    prefs.(sprintf('tf%s_z_peakTimeS', comps{c,3})) = peak_time_s;
    prefs.(sprintf('tf%s_z_peakTimeD', comps{c,3})) = peak_time_d;
    
end

% overwrite existing fields if already calculate
existing_fields = contains(fields(indexes), '_z_');


if sum(existing_fields)~=0 
    indexes = indexes(:, ~existing_fields(1:end-3)); % skip properties in last three cols
end

indexes = horzcat(indexes, prefs);
    
    
end