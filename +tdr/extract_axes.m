function tdr_ax = extract_axes(indexes, avg_resps, glm_kernels, ops)
% 
% Extract TDR axes: TF, pre-lick, F, S 
% 
% --------------------------------------------------------------------------------------------------

rois = utils.group_rois;


%% Get units with a glm fit  

inds_fitted  = glm.keep_glm_fitted_units(indexes, glm_kernels);
resps_fitted = glm.keep_glm_fitted_units(avg_resps, glm_kernels);

multi = utils.get_multi(resps_fitted, inds_fitted);
[tf_sensitive, tf_pref] = utils.get_tf_pref(inds_fitted);

tf_sensitive   = inds_fitted.tf_short_p < 0.05 & ~isnan(inds_fitted.tf_short) ;
 %% Extract axes

% Extract axes - across time
axes.tf = glm_kernels{:, 'TFbl'};
axes.tf = tf_sensitive .* axes.tf(:,2:8);
axes.tf = (axes.tf) ./ resps_fitted.FRsd;

axes.lick = (glm_kernels{:,'PreLick_e'} + glm_kernels{:,'PreLick_l'});
axes.lick = smoothdata(axes.lick,2,'movmean',3) - nanmean(axes.lick(:,1:10),2);

axes.lick = axes.lick(:, 19:end); % constrain to last 500ms before licks
axes.lick = (axes.lick) ./ resps_fitted.FRsd;

ax_names = fields(axes);

% identify axes by roi
tdr_ax = struct();
for r = 3:height(rois)
    in_roi = utils.get_units_in_area(inds_fitted.loc, rois{r, 2}) & ~multi;
    for ax_i = 1:length(ax_names)
        ax = ax_names{ax_i};
        
        % find time that maxmizes euclidean norm
        ax_magnitude = vecnorm(axes.(ax)(in_roi,:),2,1);
        [~,max_norm_id] = max(ax_magnitude)
        tdr_ax.(rois{r,1}).(ax) = axes.(ax)(in_roi, max_norm_id);
    end
    
    % split tf into f/s
    f_pref    = tf_pref(in_roi) > 0;
    s_pref    = tf_pref(in_roi) < 0;
    
    tdr_ax.(rois{r,1}).F = tdr_ax.(rois{r,1}).tf .* f_pref;
    tdr_ax.(rois{r,1}).S = tdr_ax.(rois{r,1}).tf .* s_pref *-1;
    
    % normalize
    tdr_ax.(rois{r,1}).F = tdr_ax.(rois{r,1}).F / norm(tdr_ax.(rois{r,1}).F);
    tdr_ax.(rois{r,1}).S = tdr_ax.(rois{r,1}).S / norm(tdr_ax.(rois{r,1}).S);
    
    tdr_ax.(rois{r,1}).tf = tdr_ax.(rois{r,1}).F - tdr_ax.(rois{r,1}).S;
     
    % orthogonalize
    ax_orig = [tdr_ax.(rois{r,1}).lick, tdr_ax.(rois{r,1}).tf];
    [ax_orth, ~] = qr(ax_orig);
    
    % correct sign flipping
    corrs = corr(ax_orig, ax_orth(:,1:2));
    tdr_ax.(rois{r,1}).lick = ax_orth(:, 1) * corrs(1,1);
    tdr_ax.(rois{r,1}).tf   = ax_orth(:, 2) * corrs(2,2);
    
    % normalize
    tdr_ax.(rois{r,1}).tf = tdr_ax.(rois{r,1}).tf/norm(tdr_ax.(rois{r,1}).tf);
    tdr_ax.(rois{r,1}).lick   = tdr_ax.(rois{r,1}).lick/norm(tdr_ax.(rois{r,1}).lick);
    
    
end
 
end