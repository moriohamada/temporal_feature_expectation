function expectation_analyses(avg_resps, t_ax, indexes, ops)
% 
% Figure 4 & accompanying supplements: expectation-driven modulation of TF responsive units
% 
% --------------------------------------------------------------------------------------------------
if ~exist(fullfile(ops.saveDir, 'expectation')), mkdir(fullfile(ops.saveDir, 'expectation')); end

 
%% Visualize responses

expectation.plot_average_resps_by_tf_pref(avg_resps, t_ax, indexes, ops);
expectation.plot_average_resps_by_tf_pref_by_subj(avg_resps, t_ax, indexes, ops);

expectation.plot_timeTFsensitive_resps(avg_resps, t_ax, indexes, ops);

%% Index alignment

expectation.correlate_timeTF_preference(avg_resps, indexes, ops)

%% Baseline offset and gain change quantification

expectation.quantify_baseline_gain_changes(avg_resps, t_ax, indexes, ops) 
expectation.quantify_baseline_gain_changes_by_mouse(avg_resps, t_ax, indexes, ops);
expectation.quantify_baseline_gain_changes_by_cont(avg_resps, t_ax, indexes, ops);

%% Ramp and gain visuals, split by area

ps_gain = expectation.visualize_tf_sensitive_gain(avg_resps, t_ax, indexes, ops)
ps_ramp = expectation.visualize_tf_sensitive_ramp(avg_resps, t_ax, indexes, ops)

%% Response gain change symmetry

expectation.quantify_gain_symmetry(avg_resps, t_ax, indexes, ops)

%% TDR ax projection

tdr.visualize_responses_2d()

end

%% old
% outliers:

% slow pref, active early: tf_pref = -.642409, neuron id = 10207
% slow pref, active late:  tf_pref = -700882, neuron id = 15291

% fast, active late: tf pref =  0.1840, id: 15344
% fast, acitve early: tf_pref = 0.4766, id: 14705  / .2722

% expectation.plot_average_resps_by_tf_pref(avg_resps([15344 15344],:), t_ax, indexes([15344 15344],:), ops);

%% adaptive - new
% slow/late: 15291
% expectation.plot_average_resps_by_tf_pref(avg_resps([15291 15291],:), t_ax, indexes([15291 15291],:), ops);
% fast/late: 30156
% expectation.plot_average_resps_by_tf_pref(avg_resps([30156 30156],:), t_ax, indexes([30156 30156],:), ops);

%%
% expectation.plot_average_resps_by_tf_pref(avg_resps([686 686],:), t_ax, indexes([686 686],:), ops);





