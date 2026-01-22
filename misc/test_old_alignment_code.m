function f = test_old_alignment_code(indexes,  ops, flip_time)

% index combinations
% idx_combs = {'tfExpF', 'tfExpS'; ...
%              'timeBL', 'timePreTF'; ...
%              'timeBL', 'tfExpF'; ...
%              'timeBL', 'tfExpS'; ...
%              'timeBL', 'tf'};
% idx_combs = {'timeBL', 'tf_short'};
idx_combs = {'timeBL', 'tf_short'};
% idx_combs = {'timePreTF', 'tf_short'};

% define colours to indicate significant units:
% for each combination: sig negative, sig positive, sig negative, sig positive
% colours = {ops.colors.S_pref, ops.colors.F_pref, ops.colors.S_pref, ops.colors.F_pref; ...
%            ops.colors.E, ops.colors.L, ops.colors.E, ops.colors.L; ...
%            ops.colors.E, ops.colors.L, ops.colors.S_pref, ops.colors.F_pref; ...
%            ops.colors.E, ops.colors.L, ops.colors.S_pref, ops.colors.F_pref; ...
%            ops.colors.E, ops.colors.L, ops.colors.S_pref, ops.colors.F_pref};
colours = {ops.colors.E, ops.colors.L, ops.colors.S_pref, ops.colors.F_pref};

f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .07*size(idx_combs,1) .15]); hold on;

% get sig time and tf units
sig_tf = indexes.tf_short_p<.01; 
% sig_tf = indexes.tf_short_p<.01 & sign(indexes.tfExpF_short)==sign(indexes.tfExpS_short);% & indexes.tf_short_p<.05;% (indexes.tfExpF_p<.05|indexes.tfExpS_p<.05);
fprintf('%d\n', sum(sig_tf));
% sig_tf = sign(indexes.tfExpF)==sign(indexes.tfExpS) & (indexes.tfExpF_p<sqrt(.05)&indexes.tfExpS_p<sqrt(.05));
% sig_time3 = sign(indexes.timeBL)==sign(indexes.timePreTF) & (indexes.timeBL_p<sqrt(.05)&indexes.timePreTF_p<sqrt(.05));
% sig_time3 =(indexes.timeBL_p<.05 & indexes.timePreTF_p<.01);
sig_time3 =(indexes.timePreTF_p<.01);
% 
% sig_time3 = indexes.timePreTF_p<.01;
% sig_time3 = sign(indexes.timeBL)==sign(indexes.timePreTF) & (indexes.timeBL_p<.05|indexes.timePreTF_p<.01);
% sig_tf = glm_kernels.TFbl_p<.05;
% sig_time2 = sign(indexes.timeBL)==sign(indexes.timePreTF) & (indexes.timeBL_p<.05|indexes.timePreTF_p<.05);
sig_time1 = ones(size(sig_tf));
sz= 60;

if flip_time
    conts = indexes.conts;
else
    conts = ones(height(indexes),1);
end

for ii = 1:size(idx_combs,1)
    
    ind1 = idx_combs{ii,1};
    ind2 = idx_combs{ii,2};
    
    
    idx1 = (table2array(indexes(:,ind1))); %idx1(idx1>1)=1; idx1(idx1<-1)=-1;
    idx2 = (table2array(indexes(:,ind2))); %idx2(idx2>1)=1; idx2(idx2<-1)=-1;
    
    
    idx1 = idx1.*conts;
    idx2 = idx2.*conts;
%     scatter(idx1, idx2, sz/3, 'filled', 'MarkerFaceColor', [.5 .5 .5], 'MarkerEdgeAlpha',0, 'MarkerFaceAlpha', .15);
    
%     keyboard
    
    % plot significant
    
    ind_tf = indexes.tf_short .* conts;
    slow_pref = sig_tf & ind_tf<0 & sig_time1;
    fast_pref = sig_tf & ind_tf>0 & sig_time1;
    
    
    % significance test
    [tau,p] = corr(idx1(slow_pref | fast_pref), idx2(slow_pref|fast_pref), 'Type','Kendall' );
    % slope = mean(idx2(slow_pref | fast_pref) ./ idx1(slow_pref | fast_pref))
%     coefs = polyfit(idx1(slow_pref | fast_pref), idx2(slow_pref | fast_pref), 1);
    
%     plot([-.5 .5], [-.5 .5]*coefs(1) + coefs(2), '--', 'color', ops.colors.L*1.1, 'LineWidth', 1.5)
    
    scatter(idx1(slow_pref), idx2(slow_pref), sz, 'filled', 'MarkerFaceColor', ops.colors.S_pref_light, 'MarkerEdgeAlpha',0, 'MarkerFaceAlpha', .6);
    scatter(idx1(fast_pref), idx2(fast_pref), sz, 'filled', 'MarkerFaceColor', ops.colors.F_pref_light, 'MarkerEdgeAlpha',0, 'MarkerFaceAlpha', .6);
    xlabel(ind1);
    ylabel(ind2);
    set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin')
    xlim([-.5 .5]); xticks([-.4 .4]); xticklabels([-.5 .5])
    ylim([-.5 .5]); yticks([-.4 .4]); yticklabels([-.5 .5])
    
    %%
    % plot significant
    slow_pref = sig_tf & ind_tf<0 & sig_time3;
    fast_pref = sig_tf & ind_tf>0 & sig_time3;
    
    
    % significance test
    [tau,p] = corr(idx1(slow_pref | fast_pref), idx2(slow_pref|fast_pref), 'Type','Kendall' );
    % slope = mean(idx2(slow_pref | fast_pref) ./ idx1(slow_pref | fast_pref));
%     coefs = polyfit(idx1(slow_pref | fast_pref), idx2(slow_pref | fast_pref), 1);

%     plot([-.5 .5], [-.5 .5]*coefs(1) + coefs(2), 'color', ops.colors.L*.8, 'LineWidth', 1.5)
    
    scatter(idx1(slow_pref), idx2(slow_pref), sz, 'filled', 'MarkerFaceColor', ops.colors.S_pref_light, 'MarkerEdgeColor','k', 'MarkerFaceAlpha', 0);
    scatter(idx1(fast_pref), idx2(fast_pref), sz, 'filled', 'MarkerFaceColor', ops.colors.F_pref_light, 'MarkerEdgeColor','k', 'MarkerFaceAlpha', 0);
    xlabel(ind1);
    ylabel(ind2);
    set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin')
    xlim([-.5 .5]); xticks([-.4 .4]); xticklabels([-.5 .5])
    ylim([-.5 .5]); yticks([-.4 .4]); yticklabels([-.5 .5])
    title(sprintf('\\tau = %.2f, p = %.3f', tau, p), 'FontWeight', 'normal', 'HorizontalAlignment', 'center')
  
end

end