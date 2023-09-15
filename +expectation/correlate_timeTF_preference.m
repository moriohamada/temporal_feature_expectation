function plot_example_timeTF_correlated_units(sessions,  trials_all, daq_all, sp_all, neuron_info, ops)
% 
% Select units with strongest time/TF correlation, and plot PSTHs (baseline firing + raster and TF
% pulse responses).
% 
% --------------------------------------------------------------------------------------------------

%% Load indexes and average responses

[indexes, avg_resps, t_ax, ~, ~]  = load_indexes_avgResps(sessions, neuron_info, ops);


%% Get ROIs of interest

rois = {'MOs', 'BG', 'mPFC', 'Motor thalamus'};
allen_areas = area_names_in_roi(rois);

while any(cellfun(@iscell, allen_areas))
    allen_areas = [allen_areas{cellfun(@iscell,allen_areas)} allen_areas(~cellfun(@iscell,allen_areas))];
end

in_area = contains(neuron_info.loc, allen_areas);

multi = (indexes.cg==0) | avg_resps.FRmu < .25 | avg_resps.FRsd<.5 | isnan(indexes.tf_short) | isnan(indexes.timeBL);

%% Calculate alignment between units in ROI

time_pref = indexes.timeBL .* (indexes.timeBL_p<.05 | indexes.timePreTF < .01) ;
tf_pref   = indexes.tf_short .* (indexes.tf_short_p<.05 & (sign(indexes.tfExpF_short)==sign(indexes.tfExpS_short)));

% flip time pref for ESLF
% time_pref(strcmp(cellstr(neuron_info{:,'cont'}),'ESLF')) = time_pref(strcmp(cellstr(neuron_info{:,'cont'}),'ESLF')) * -1;

% remove ESLF units
time_pref(strcmp(cellstr(neuron_info{:,'cont'}),'ESLF')) = 0;
tf_pref(strcmp(cellstr(neuron_info{:,'cont'}),'ESLF')) = 0;

% select only good units in roi
time_pref = time_pref(in_area & ~multi);
tf_pref   = tf_pref(in_area & ~multi);
neuron_info_roi = neuron_info(in_area & ~multi,:);

% get alignment
alignment = tf_pref .* time_pref;

%% Get picks for F and S units and plot PSTHs

F_pref = tf_pref > 0 & time_pref ~= 0;
S_pref = tf_pref < 0 & time_pref ~= 0;

nTop = 50;

[~, order] = sort(abs(tf_pref), 'descend');

F_pref = F_pref(order);
S_pref = S_pref(order);

% get top F and S pref units
F_ordered = order(F_pref);
S_ordered = order(S_pref);

F_picks = neuron_info_roi(F_ordered(1:nTop),:);
S_picks = neuron_info_roi(S_ordered(1:nTop),:);

% Plot PSTHS
F_to_plot = table2cell(F_picks(:, {'animal', 'session', 'cid'}))
single_unit_select_responses_basic_wrapper(sessions, trials_all, daq_all, sp_all, F_to_plot, ops);
% S_to_plot = table2cell(S_picks(:, {'animal', 'session', 'cid'}))
% single_unit_select_responses_basic_wrapper(sessions, trials_all, daq_all, sp_all, S_to_plot, ops);



end





