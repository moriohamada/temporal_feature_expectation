function f = visualize_tfunit_loading_on_premotor(projs_iters_aligned, dims_iters_aligned, t_ax_resps, ops)
% 
% construct visualization of F/S unit contribution onto premotor dimension
% 
% --------------------------------------------------------------------------------------------------
% keyboard
%%
nIter = length(projs_iters_aligned);

r_proj = nan(nIter, length(t_ax_resps.tf), 4, 3); % 3rd dim: FexpF, FexpS, SexpF, SexpS; last dim: F/S/null 1

tf_names  = {'FexpF','SexpS'};
dim_names = {'tf_fast', 'tf_slow', 'movement_null1'};

st_inds  = isbetween(t_ax_resps.tf, [-.4 -.1]);
end_inds = isbetween(t_ax_resps.tf, [.7 1]);

for iter = 1:nIter
    for tfi = 1:numel(tf_names)
        tf_name = tf_names{tfi};
        for dd = 1:numel(dim_names)
            dim = dim_names{dd};
            r_proj(iter, :, tfi, dd) = detrend_resp(projs_iters_aligned{iter}.(dim).(tf_name), st_inds, end_inds);
        end
    end
end

%% visualize responses - 1d plots
null_clrs = flipud(cbrewer2('Blues', 4)); 

f = figure('Units', 'normalized', 'OuterPosition', [.3 .1 .3 .18]);
dim_cols = [ops.colors.F; ops.colors.S; [0 0 0]];

for tfi = 1:numel(tf_names)
    tf_name = tf_names{tfi};
    
    subplot(1,2,tfi); hold on
    for dd = 1:numel(dim_names)
        tf_resp = squeeze(r_proj(:,:,tfi, dd));
        if dd==3
            tf_resp = tf_resp - nanmean(tf_resp(:, isbetween(t_ax_resps.tf, [-.5 0])),2);
        end
        shadedErrorBar(t_ax_resps.tf, tf_resp, {@nanmean @nanstd}, ...
                       'lineprops', {'color', dim_cols(dd,:)})
    end
    ylim([-.2 .8])
end

%% visualize with arrows
angles = deg2rad([-45 0 45]);
f = figure('Units', 'normalized', 'OuterPosition', [.3 .1 .3 .18]);
% first draw on arrows

for ii = 1:2 
    subplot(1,2,ii); hold on
    


end
