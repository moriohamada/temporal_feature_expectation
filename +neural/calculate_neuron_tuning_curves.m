function tuning_all = calculate_neuron_tuning_curves(sessions, trials_all, daq_all, sp_all, ops)
% 
% Calculate tf x time tuning for every unit  
% 
% --------------------------------------------------------------------------------------------------

fprintf('Calculating tf x time tuning curves for each unit\n')

tuning_all = table();
flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');
animals = unique({sessions.animal});

if ~exist(ops.tuningDir), mkdir(ops.tuningDir); end

n = 0;
for s = 1:length(sessions)
    
    animal  = sessions(s).animal;
    session = sessions(s).session;
    
    fprintf('session %d/%d\n', s, length(sessions))
    if strcmp(session(1), 'h') % not recording session
        continue
    end
    
    sp = sp_all{s};
    cids = sp.cids;
    locs = sp.clu_locs';
    cgs = sp.cgs';
    
    % remove multi
    good_clu = cids(cgs~=0);
    sp.st  = sp.st(ismember(sp.clu, good_clu));
    sp.clu = sp.clu(ismember(sp.clu, good_clu));
    sp.clu_locs = sp.clu_locs(cgs~=0);
    sp.cgs  = cgs(cgs~=0);
    sp.cids = sp.cids(cgs~=0);
    cids = sp.cids;
    locs = sp.clu_locs';
    cgs = sp.cgs;
    
    nN   = length(cids);
    
    [fr, t_ax] = spike_times_to_fr(sp, ops.spBinWidth);
    [fr, t_ax] = remove_out_of_trial_fr(fr, t_ax, daq_all{s});
    
    fr = fr/(ops.spBinWidth/1000);
    fr_mu = mean(fr,2);
    fr_sd = std(fr,[],2);
    fr_z = (fr - fr_mu) ./ fr_sd;
 
    % get flip time
    animal_id = strcmp(animals, sessions(s).animal);
    flip_time = flip_times(animal_id);
   
    % get amps, times of every tf pulse
   [ampsF, timesF, tr_timesF, lickedF] = ...
       get_tf_outliers_time_amp(trials_all{s}, daq_all{s}, 2, .25, 0, 1, ops.rmvTimeAround, [0 ops.rmvTimeAround]);
   [ampsS, timesS, tr_timesS, lickedS] = ...
       get_tf_outliers_time_amp(trials_all{s}, daq_all{s}, 2, .25, 0, -1, ops.rmvTimeAround, [0 ops.rmvTimeAround]);
   
   % combine
   amps     = [ampsF, ampsS];
   times    = [timesF, timesS];
   tr_t     = [tr_timesF, tr_timesS];
   licked   = [lickedF, lickedS];
   
   fast   = amps>0;
   slow   = amps<0;
   early  = tr_t' < flip_time & tr_t' > ops.rmvTimeAround;
   late   = tr_t' > flip_time;
   licked = licked==1;
   
   tf_bin_edges_prctile = [0:10:90; 10:10:100]';
   tf_bin_edges         = zeros(size(tf_bin_edges_prctile));
   n_tf_bins = size(tf_bin_edges,1);

   for bin_i = 1:n_tf_bins
       edges = tf_bin_edges_prctile(bin_i,:);
       tf_bin_edges(bin_i,:) = prctile(amps, edges);
   end
   
   time_bin_edges = [-inf, -3; ...
                     -3, -1; ...
                     -1,  1; ...
                      1,  4; ...
                      3,  10] + flip_time;
                  
   n_time_bins = size(time_bin_edges,1);
   
   tuning    = nan(nN, n_time_bins, n_tf_bins);
   tuning_sd = nan(size(tuning));
   tuning_n  = nan(size(tuning));
   tuning_normed    = nan(size(tuning)); % subtract pre-pulse activity
   tuning_normed_sd = nan(size(tuning));
   tuning_pre       = nan(size(tuning)); % pre pulse activity - i.e. baseline offset
   tuning_pre_sd    = nan(size(tuning));
   
   responses = nan(nN, n_time_bins, n_tf_bins, ceil(1/ops.spBinWidth*1000));
   for time_i = 1:n_time_bins
       for tf_i = 1:n_tf_bins
           
           % get tf pulses in this time and tf bin
           in_tf_bin = isbetween(amps, tf_bin_edges(tf_i,:));
           in_time_bin = isbetween(tr_t, time_bin_edges(time_i,:));
           this_bin_t = times(in_tf_bin & in_time_bin & ~licked);
           
           % calculate psth
           [tax, psth_full] = get_response_to_event_from_FR_matrix(fr_z, t_ax, this_bin_t, [-.5 .6]); % take a little extra
           tax = tax(1:size(responses,4));
           psth_full = psth_full(:,:,1:size(responses,4));
           psth = psth_full(:,:,isbetween(tax, ops.respWin.tfShort));
           psth_pre = psth_full(:,:,isbetween(tax, [-.4 -.1]));
           psth_normed = (psth - nanmean(psth_pre,3));
        
           tuning(:, time_i, tf_i) = nanmean(psth, [2 3]);
           tuning_sd(:, time_i, tf_i) = nanstd(psth, [], [2 3]);
           tuning_n(:, time_i, tf_i) = size(psth,2);
           tuning_normed(:, time_i, tf_i) = nanmean(psth_normed, [2 3]);
           tuning_normed_sd(:, time_i, tf_i) = nanstd(psth_normed, [], [2 3]);
           
           % also keep 'pre-pulse tuning' - basically just bl offset
           tuning_pre(:, time_i, tf_i) = nanmean(psth_pre, [2 3]);
           tuning_pre_sd(:, time_i, tf_i) = nanstd(psth_pre, [], [2 3]);
           
           % also store responses over time
           responses(:, time_i, tf_i, :) = squeeze(nanmean(psth_full, 2));
           
           
           clear psth psth_pre psth_normed psth_full
       end
   end
   
   % get centre of mass as alternative preference measure
   % create grid of x and y coords
   [X, Y] = meshgrid(1:n_tf_bins, 1:n_time_bins);
   X = repmat(X, [1, 1, nN]);
   Y = repmat(Y, [1, 1, nN]);
   % Permute the dimensions to match inputMatrix
   X = permute(X, [3, 1, 2]);
   Y = permute(Y, [3, 1, 2]);
   
   % normalize tuning
   minVal = min(min(tuning,[],3),[],2);
   maxVal = max(max(tuning,[],3),[],2);
   tuning_norm = (tuning - minVal) ./ (maxVal - minVal);
   
   % Calculate the weighted sums
   sumMass = sum(sum(tuning_norm, 3), 2);
   sumMassX = sum(sum(X.*tuning_norm, 3), 2);
   sumMassY = sum(sum(Y.*tuning_norm, 3), 2);
   
   % Calculate the centers of mass
   COM_tf   = squeeze(sumMassX ./ sumMass);
   COM_time = squeeze(sumMassY ./ sumMass);
   
   % Store the centers of mass
   COM_pVal_time = zeros(nN, 1);
   COM_pVal_tf   = zeros(nN, 1);
   [X, Y] = meshgrid(1:n_tf_bins, 1:n_time_bins);
   % Permute the rows and columns to generate null distribution
   for ii = 1:nN
       for jj = 1:ops.nIter
           % Generate a random permutation of the rows and columns
           permMatrix = tuning(ii, randperm(n_time_bins), randperm(n_tf_bins));
           
           % Calculate the COM for the permuted matrix
           COM_x_null(jj) = sum(X(:).*permMatrix(:))/sum(permMatrix(:));
           COM_y_null(jj) = sum(Y(:).*permMatrix(:))/sum(permMatrix(:));
           
           
       end
       % get p values
       COM_pVal_time(ii) = sum(abs(COM_y_null - n_time_bins/2) > (abs(COM_time(ii) - n_time_bins/2)))/ops.nIter;
       COM_pVal_tf(ii)   = sum(abs(COM_x_null - n_tf_bins/2) > (abs(COM_tf(ii) - n_tf_bins/2)))/ops.nIter;
   end
   
   % convert 3d arrays to {nNx1} cells before converting to table
   tuning = squeeze(mat2cell(permute(tuning, [2 3 1]), n_time_bins, n_tf_bins, ones(1, nN)));
   tuning_sd = squeeze(mat2cell(permute(tuning_sd, [2 3 1]), n_time_bins, n_tf_bins, ones(1, nN)));
   tuning_n = squeeze(mat2cell(permute(tuning_n, [2 3 1]), n_time_bins, n_tf_bins, ones(1, nN)));
   
   tuning_normed = squeeze(mat2cell(permute(tuning_normed, [2 3 1]), n_time_bins, n_tf_bins, ones(1, nN)));
   tuning_normed_sd = squeeze(mat2cell(permute(tuning_normed_sd, [2 3 1]), n_time_bins, n_tf_bins, ones(1, nN)));
   
   tuning_pre = squeeze(mat2cell(permute(tuning_pre, [2 3 1]), n_time_bins, n_tf_bins, ones(1, nN)));
   tuning_pre_sd = squeeze(mat2cell(permute(tuning_pre_sd, [2 3 1]), n_time_bins, n_tf_bins, ones(1, nN)));
      
   responses = squeeze(mat2cell(permute(responses, [2 3 4 1]), n_time_bins, n_tf_bins, size(responses,4), ones(1,nN)));
   
   % create table
   tunings = table(...
                       repelem(animal, nN, 1), repelem(session,nN,1), cids, locs, cgs, ...
                       tuning, tuning_sd, tuning_n, ...
                       tuning_normed, tuning_normed_sd, ...
                       tuning_pre, tuning_pre_sd, ...
                       responses, ...
                       COM_time, COM_pVal_time, COM_tf, COM_pVal_tf,...
                       'VariableNames', ...
                      {'animal', 'session', 'cid', 'loc','cg', ...
                       'tuning', 'tuning_sd', 'tuning_n', ...
                       'tuning_normed', 'tuning_normed_sd', ...
                       'tuning_pre', 'tuning_pre_sd', ...
                       'responses', ...
                       'COM_time', 'COM_time_p', 'COM_tf', 'COM_tf_p'});
         

   % save
   tuning_save_file = fullfile(ops.tuningDir, sprintf('%s_%s.mat', animal, session));
   save(tuning_save_file, 'tunings', 'time_bin_edges', 'tf_bin_edges')
   %% append to all 
   
   if isempty(tuning_all)
       tuning_all = tunings;
   else
       tuning_all = [tuning_all; tunings];
   end

end

% save tuning_all
tuning_all_save = fullfile(ops.tuningDir, 'all_unit_tuning.mat');
save(tuning_all_save, 'tuning_all', '-v7.3');

end