function quanitfy_gain_symmetry(avg_resps, t_ax, indexes, ops)
% 
% For TF responsive units: quantify how gain changes to preferred vs unpreferred stimuli (in MOs/CP)
% 
% --------------------------------------------------------------------------------------------------

rois = utils.group_rois;
in_roi = utils.get_units_in_area(indexes.loc, rois{3,2});

[tf_sensitive, tf_pref] = utils.get_tf_pref(indexes);

multi = utils.get_multi(avg_resps);

sel = in_roi & tf_sensitive & ~multi;

% get responses
pulse_types = {'FexpF', 'FexpS', 'SexpF', 'SexpS'};
for pt = 1:length(pulse_types)
    pulse = pulse_types{pt};
    pulse_resps.(pulse) = smoothdata(...
                         (avg_resps{sel, pulse} - avg_resps{sel, 'FRmu'})./avg_resps{sel, 'FRsd'}, ...
                         2, 'movmean', [ops.spSmoothSize/ops.spBinWidth 0]);;
end

% calculate response gain to preferred and unpreferred
resp_t = isbetween(t_ax.tf, ops.respWin.tfShort);
pre_t  = isbetween(t_ax.tf, ops.respWin.tfContext);
fast   = tf_pref(sel)>0;
slow   = tf_pref(sel)<0;
inds   = indexes(sel,:);

gain.Fpref  = inds.tfExpF_z_peakF(fast) - inds.tfExpS_z_peakF(fast);
gain.Fupref = inds.tfExpF_z_peakS(fast) - inds.tfExpS_z_peakS(fast);

gain.Ftotal = gain.Fpref - gain.Fupref;
gain.Fsym   = gain.Fpref + gain.Fupref;

gain.Spref  = inds.tfExpS_z_peakS(slow) - inds.tfExpF_z_peakS(slow);
gain.Supref = inds.tfExpS_z_peakF(slow) - inds.tfExpF_z_peakF(slow);
gain.Stotal = gain.Spref - gain.Supref;
gain.Ssym   = gain.Spref + gain.Supref;
% 
% gain.Fpref   = (absoluteMax(pulse_resps.FexpF(fast, resp_t),2) - nanmean(pulse_resps.FexpF(fast, pre_t),2)) - ...
%                (absoluteMax(pulse_resps.FexpS(fast, resp_t),2) - nanmean(pulse_resps.FexpS(fast, pre_t),2));
% gain.Fupref  = (absoluteMax(pulse_resps.SexpF(fast, resp_t),2) - nanmean(pulse_resps.SexpF(fast, pre_t),2)) - ...
%                (absoluteMax(pulse_resps.SexpS(fast, resp_t),2) - nanmean(pulse_resps.SexpS(fast, pre_t),2));
% gain.F_total = (absoluteMax(pulse_resps.FexpF(fast, resp_t) - pulse_resps.SexpF(fast, resp_t),2)) - ...
%                (absoluteMax(pulse_resps.SexpF(fast, resp_t) - pulse_resps.SexpS(fast, resp_t),2))
%           
% gain.Spref  = (absoluteMax(pulse_resps.SexpS(slow, resp_t),2) - nanmean(pulse_resps.SexpS(slow, pre_t),2)) - ...
%               (absoluteMax(pulse_resps.SexpF(slow, resp_t),2) - nanmean(pulse_resps.SexpF(slow, pre_t),2));
% gain.Supref = (absoluteMax(pulse_resps.FexpS(slow, resp_t),2) - nanmean(pulse_resps.FexpS(slow, pre_t),2)) - ...
%               (absoluteMax(pulse_resps.FexpF(slow, resp_t),2) - nanmean(pulse_resps.FexpF(slow, pre_t),2));
%           
% gain.S_total = (absoluteMax(pulse_resps.SexpS(fast, resp_t) - pulse_resps.FexpS(fast, resp_t),2)) - ...
%                (absoluteMax(pulse_resps.FexpS(fast, resp_t) - pulse_resps.SexpS(fast, resp_t),2))

gains_pref  = [gain.Fpref; gain.Spref];
gains_upref = [gain.Fupref; gain.Supref];
gains_total = [gain.Ftotal; gain.Stotal];
gains_sym   = [gain.Fsym; gain.Ssym];
%% Plot

f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .11 .12]);
hold on;
nN = length(gains_pref);
jitter = .05;

plot([0.2 4.3], [0 0], '-k')
gains_all = [gains_pref, gains_upref, gains_total, gains_sym];
clrs = [ops.colors.F; ops.colors.S; [196 146 186]/255; [238 181 120]/255];
for ii = 1:4
    data = gains_all(:,ii);
    [data, rmv] = rmoutliers(data);
    scatter(ii*ones(nN-sum(rmv),1)+randn(nN-sum(rmv),1)*jitter, data, 10, 'filled', ...
            'MarkerFaceColor', clrs(ii,:), 'MarkerFaceAlpha', .5, ...
            'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', .2);
    gains_all(rmv, ii) = nan;
end
% plot(gains_all', 'color', [.5 .5 .5 .2], 'linewidth', .1);

% violin plots & mean/ci
for ii=1:4
     violinPlot(gains_all(:,ii),  'histori', 'left', 'widthDiv', [2 1], 'showMM', 0, 'xValues', ii-.1, ...
                  'color', clrs(ii,:));
     mu = nanmean(gains_all(:,ii));
     ci = ci_95_magnitude(gains_all(:,ii));
     scatter(ii+.2, mu, 50, '<', ...
             'MarkerFaceColor', clrs(ii,:), 'MarkerFaceAlpha', 1, ...
             'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', 1);
     plot([ii ii]+.2, [-ci ci]+mu, '-k', 'linewidth', 1);   
end
ylim([-20 20])

% get p values
[~, ps] = ttest(gains_all);

for ii=1:4
    p = ps(ii);
    symbol = get_sig_symbol(p);
    text(ii-.1, 20, symbol, 'HorizontalAlignment', 'center', 'FontName', 'arial', 'FontSmoothing', 8)
end

set(gca, 'xcolor', 'none')

if ops.saveFigs
save_figures_multi_format(f, fullfile(ops.saveDir, 'expectation', 'ramp_symmetry'), {'fig', 'svg' });
end
end

