function f= test_premotor_rotation(rwr_root, rwr_shuffle_root, areas, neuron_info, indexes, ops)
%% Null space analysis - test whether premotor dimension rotates
% 
% --------------------------------------------------------------------------------------------------
%% 
%% Load in kernels

% Get paths of all kernels files
all_files = dir(fullfile(rwr_root, '**/*.*'));
data_ids  = find(contains({all_files.name}, '.mat'));

data_paths = arrayfun(@(idx) [all_files(idx).folder, filesep, all_files(idx).name], data_ids, ...
                      'UniformOutput', false);
data_paths = convertCharsToStrings(data_paths);

neuron_info.animal  = string(neuron_info.animal);
neuron_info.session = string(neuron_info.session);
neuron_info.cid     = string(neuron_info.cid);

sig_thresh =  .05;
%%

prelick_kernels_all = nan(0, 2, 20, 100);
tf_kernels_all = nan(0, 20, 100);
ch_kernels_all = nan(0, 20, 100);
unit_ids    = [];

for ii = 1:length(data_paths)

    progressbar(ii/length(data_paths))
    
    data_path = data_paths{ii};

    % parse animal session, cid - check if in MOs/CP (otherwise ignore)
    path_comps = strsplit(data_path, filesep);
    animal  = path_comps{end-2};
    session = path_comps{end-1};
    cid     = path_comps{end}(4:end-4);

    unit_id = find(...
              (neuron_info.animal==animal) & ...
              (neuron_info.session==session) & ...
              (neuron_info.cid==cid));

    loc = neuron_info.loc{unit_id};
    cg  = neuron_info.cg(unit_id);
    if ~contains(loc, areas)  
        continue
    end
    if cg ~= 2
        continue
    end
    
    tf_responsive = indexes.tf_p(unit_id) < .05;
    pl_responsive = indexes.prelick_p(unit_id) < .05;
    if ~tf_responsive | ~pl_responsive
        continue
    end
    % load data from mat file
    [rmses, prelick_kernels, tf_kernels, ch_kernels] = ...
            loadVariables(data_path, 'rmses', 'prelick_kernels', 'tf_kernels', 'ch_kernels');

    if any(isnan(rmses(:))) | any(isnan(prelick_kernels(:)))
        continue
    end
    

    % first check whether adding pre-lick kernels changed fit
    d_rmse_tf = rmses(:,1) - rmses(:,2);
    p_tf = signrank(d_rmse_tf, [], 'tail', 'right');
    d_rmse_pl = rmses(:,3) - rmses(:,4);
    p_pl = signrank(d_rmse_pl, [], 'tail', 'right');
    
    
    if max([p_tf, p_pl]) >= sig_thresh | any(isnan([p_tf, p_pl]))
        continue
    end
%  
%     if max([ p_pl]) >= sig_thresh | any(isnan([p_tf, p_pl]))
%         continue
%     end
    if max([p_tf, p_pl]) >= sig_thresh | any(isnan([p_tf, p_pl]))
        continue
    end

    % extract kernels if significant
    prelick_kernels_all(end+1,:,:,:) = permute(prelick_kernels, [2 3 1]);
    tf_kernels_all(end+1,:,:)    = permute(tf_kernels, [2 1]);
    ch_kernels_all(end+1,:,:)    = permute(ch_kernels, [2 1]);
    unit_ids(end+1) = unit_id;

end

flipped = false;

%% Flip pre-lick kernels for eslf animals
if ~flipped
    eslf = strcmp(string(neuron_info{unit_ids,'cont'}), 'ESLF');
    tmp = prelick_kernels_all;
    prelick_kernels_all(eslf, 1, :, :) = tmp(eslf, 2, :, :);
    prelick_kernels_all(eslf, 2, :, :) = tmp(eslf, 1, :, :);
    clear tmp
    flipped = true;
end

%% Load control kernels
all_files = dir(fullfile(rwr_shuffle_root, '**/*.*'));
data_ids  = find(contains({all_files.name}, '.mat'));
data_paths = arrayfun(@(idx) [all_files(idx).folder, filesep, all_files(idx).name], data_ids, ...
                      'UniformOutput', false);
data_paths = convertCharsToStrings(data_paths);

prelick_kernels_shuffled = nan(size(prelick_kernels_all));
tf_kernels_shuffled = nan(size(tf_kernels_all));

for n = 1:length(unit_ids)
    unit_info = neuron_info(unit_ids(n),:);
    shuffled_path = fullfile(rwr_shuffle_root, unit_info.animal, unit_info.session, ...
                                   sprintf('cid%s.mat', unit_info.cid)         );
    if exist(shuffled_path, 'file')
        [rmses, prelick_kernels, tf_kernels] = ...
            loadVariables(shuffled_path, 'rmses', 'prelick_kernels', 'tf_kernels');

        prelick_kernels_shuffled(n, :, :, :) = permute(prelick_kernels, [2 3 1]);
        tf_kernels_shuffled(n,:,:)    = permute(tf_kernels, [2 1]);
    end

end
eslf = strcmp(string(neuron_info{unit_ids,'cont'}), 'ESLF');
tmp = prelick_kernels_shuffled;
prelick_kernels_shuffled(eslf, 1, :, :) = tmp(eslf, 2, :, :);
prelick_kernels_shuffled(eslf, 2, :, :) = tmp(eslf, 1, :, :);

% remove nan
nan_units = any(isnan(prelick_kernels_shuffled), [2 3 4]) | any(isnan(tf_kernels_shuffled), [2 3]) | ...
            any(isnan(prelick_kernels_all), [2 3 4])      | any(isnan(tf_kernels_all), [2 3]);
prelick_kernels_shuffled(nan_units,:,:,:)=[];
tf_kernels_shuffled(nan_units,:,:) = [];
prelick_kernels_all(nan_units,:,:,:)=[];
tf_kernels_all(nan_units,:,:) = [];

 
%% Normalize kernels
norm_kernels = 1;
prelick_bl_inds = [1:5];
tf_bl_inds = [1:5];
if norm_kernels
    bl_activity = repmat(median(prelick_kernels_all(:,:,prelick_bl_inds,:),3), [1 1 20 1]);
    prelick_kernels_normed = prelick_kernels_all - bl_activity;
    tf_bl = repmat(median(tf_kernels_all(:,tf_bl_inds,:),2), [1 20 1]);
    tf_normed = tf_kernels_all - tf_bl;

    bl_shuffled = repmat(median(prelick_kernels_shuffled(:,:,prelick_bl_inds,:),3), [1 1 20 1]);
    prelick_kernels_normed_shuffled = prelick_kernels_shuffled - bl_shuffled;
    tf_bl_shuffled = repmat(median(tf_kernels_shuffled(:,tf_bl_inds,:),2), [1 20 1]);
    tf_normed_shuffled = tf_kernels_shuffled - tf_bl_shuffled;
    
else
    prelick_kernels_normed = prelick_kernels_all;
    prelick_kernels_normed_shuffled = prelick_kernels_shuffled;
    tf_normed = tf_kernels_all;
    tf_normed_shuffled = tf_kernels_shuffled;
%     ch_normed = ch_kernels_all;
%     ch_normed_shuffled = ch_kernels_shuffled;
end

%% Calculate alignment between premotor and TF

nN = size(prelick_kernels_normed,1);

% % get times of prelick and tf kernels to use for TDR
prelick_avg = reshape(nanmedian(prelick_kernels_normed, 4), nN*2, 20);
tf_avg      = nanmedian(tf_normed, 3);
% ch_avg      = nanmedian(ch_normed, 3);

[~, max_prelick] = max(vecnorm((prelick_avg(:,1:end-3)),2,1));
[~, max_tf] = max(vecnorm((tf_avg(:, 6:15)),2,1));
max_tf = max_tf+5;

tf_vec = tf_avg(:, max_tf);
% ch_vec = ch_avg(:, max_tf);
pl_vec = prelick_avg(:, max_prelick);

sims = nan(6, 8, 100);
axnames = {'tf', 'prelickExpF', 'prelickExpS', ...
           'tfNull', 'prelickExpFNull', 'prelickExpSNull', ...
           'prelickExpFShifted', 'prelickExpSShifted'};

% only keep units with non-nan fits for both real and shuffled cases
% nan_units = any(isnan(prelick_kernels_all), [2 3 4]) | ...
%             any(isnan(prelick_kernels_shuffled), [2 3 4]);

for iter = 1:100
    

    % Get prelick and tf axes
    ax.tf = (squeeze(tf_normed(:, max_tf, iter)));
%     ax.tf = sign(squeeze(ch_normed(:, max_tf, iter)));
    ax.prelickExpF = squeeze(prelick_kernels_normed(:,1,max_prelick,iter));
    ax.prelickExpS = squeeze(prelick_kernels_normed(:,2,max_prelick,iter));
    
    % Null versions - fit on 
    ax.tfNull = (squeeze(tf_normed_shuffled(:, max_tf, iter)));
%     ax.tfNull = sign(squeeze(ch_normed_shuffled(:, max_tf, iter)));
    ax.prelickExpFNull = squeeze(prelick_kernels_normed_shuffled(:,1,max_prelick,iter));
    ax.prelickExpSNull = squeeze(prelick_kernels_normed_shuffled(:,2,max_prelick,iter));

    % Consistency between iterations
    % if iter <= 99
    %     shift_iter = iter+1;
    % else
    %     shift_iter = 1;
    % end
    % ax.prelickExpFShifted = squeeze(prelick_kernels_normed(:,1,max_prelick,shift_iter));
    % ax.prelickExpSShifted = squeeze(prelick_kernels_normed(:,2,max_prelick,shift_iter));

    % calculate cosine sim between tf and prelick
    for ii = 1:3
        for jj = 1:3
            sims(ii,jj,iter) = cosineSim(ax.(axnames{ii}), ax.(axnames{jj}));
            sims(ii+3,jj+3,iter) = cosineSim(ax.(axnames{ii+3}),ax.(axnames{jj+3}));
%             sims(ii,jj,iter) = corr(ax.(axnames{ii}), ax.(axnames{jj}));
%             sims(ii+3,jj+3,iter) = corr(ax.(axnames{ii+3}),ax.(axnames{jj+3}));
        end
    end
    %for ii = 2:3
    %    sims(ii,ii+5,iter) = cosineSim(ax.(axnames{ii}), ax.(strcat(axnames{ii},'Shifted')));
    %end

        
    % clear ax


end

% normalize to control
mu_control = [median(squeeze(sims(5,4,:))), median(squeeze(sims(6,4,:)))];
sims(5,4,:) = sims(5,4,:) - mu_control(1);
sims(2,1,:) = sims(2,1,:) - mu_control(1);
sims(6,4,:) = sims(6,4,:) - mu_control(2);
sims(3,1,:) = sims(3,1,:) - mu_control(2);


%% Visualization and significance testing
f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .06 .2]);
null_clrs = flipud(cbrewer2('Blues', ops.nDim_N+1));

% plot similarity of pre-lick
subplot(2,1,1); hold on
% Null
histogram(sims(5,6,:), 'BinEdges', [0.7:.01:1], ...
          'EdgeAlpha', 0, 'FaceColor', [.5 .5 .5]);
% True
histogram(sims(2,3,:), 'BinEdges', [0.7:.01:1], ...
          'EdgeAlpha', 0, 'FaceColor',  null_clrs(1,:));

xlabel(sprintf('Pre-lick dim similarity \n(exp F vs exp S)'));
      
% significance test 
% p = permutationTestOneSample(squeeze(sims(5,6,:))-squeeze(sims(2,3,:)), ops.nIter)
p = signrank(squeeze(sims(5,6,:))-squeeze(sims(2,3,:)))
sym = get_sig_symbol(p)

% add sig mark
yl = ylim;
text(.9, yl(2), sym);

% Plot alignment of pre-lick expF and expS
subplot(2,1,2); hold on
xl=[-.2 .2]; yl = [-.2 .2]; 
xl = [-1 1] .* max(abs(xl));
yl = [-1 1] .* max(abs(yl));
plot([0 0], yl, '-k');
plot(xl, [0 0], '-k');
scatter(squeeze(sims(5,4,:)), squeeze(sims(6,4,:)), 20, ...
        'MarkerFaceColor', [.5 .5 .5], 'MarkerFaceAlpha', .5, ...
        'MarkerEdgeAlpha', .5, 'MarkerEdgeColor', [.5 .5 .5]);
scatter(squeeze(sims(2,1,:)), squeeze(sims(3,1,:)), 20, ...
        'MarkerFaceColor', null_clrs(1,:), 'MarkerFaceAlpha', .6, ...
        'MarkerEdgeAlpha', 0);
% add averages
mu1 = mean(squeeze(sims(2,1,:)));
mu2 = mean(squeeze(sims(3,1,:)));
ci1 = prctile(squeeze(sims(2,1,:)), [2.5 97.5]);
ci2 = prctile(squeeze(sims(3,1,:)), [2.5 97.5]);
plot(xl, yl, '--k');

plot([mu1 mu1], ci2, '-k');
plot(ci1, [mu2 mu2], '-k');

% add diagonal CIs
ci_diag = prctile(squeeze(sims(2,1,:)) - squeeze(sims(3,1,:)), [2.5 97.5]);
plot(mu1+ci_diag/sqrt(2)-(mu1-mu2)/sqrt(2), mu2-ci_diag/sqrt(2)-(mu2-mu1)/sqrt(2), '-k')

scatter(mu1, mu2, 50,  'MarkerFaceColor', null_clrs(1,:), 'MarkerFaceAlpha', 1, ...
       'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', 1);

% Null
% histogram(squeeze(sims(5,4,:) - sims(6,4,:)), 'BinEdges', [-.2:.025:.5], ...
%           'EdgeAlpha', 0, 'FaceColor', [.5 .5 .5]);
% % True
% 
% histogram(squeeze(sims(2,1,:) - sims(3,1,:)), 'BinEdges', [-.2:.025:.5], ...
%           'EdgeAlpha', 0, 'FaceColor', ops.colors.MOs);

xlabel(sprintf('Alignment between pre-lick and TF \n(expF)'));
ylabel(sprintf('Alignment between pre-lick and TF \n(expS)'));

% p = permutationTest(squeeze(sims(5,4,:))-squeeze(sims(6,4,:)), ...
%                     squeeze(sims(2,1,:))-squeeze(sims(3,1,:)), ...
%                     ops.nIter)

% p = permutationTestOneSample(squeeze(sims(5,4,:))-squeeze(sims(6,4,:)) - ...
%                              squeeze(sims(2,1,:))-squeeze(sims(3,1,:)), ...
%                              ops.nIter)

p = signrank(squeeze(sims(5,4,:))-squeeze(sims(6,4,:)) - ...
              squeeze(sims(2,1,:))-squeeze(sims(3,1,:)))
          
%%
% keyboard
end