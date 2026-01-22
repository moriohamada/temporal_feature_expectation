function load_session_data_bootstrapped()

mu = frstats{s,1};
sd = frstats{s,2};

trials = trials_all{s};
daq = daq_all{s};
nTr = length(trials);
nTrain = ceil(nTr * pTrain);

% make sure enough (min 5) hits for each change
hits   = strcmp({trials.trialOutcome}, 'Hit') & ...
    ~contains({trials.trialType}, 'U')   & ...
    [trials.changeTF] ~= 2;
hitTFs = [trials(hits).changeTF];
if length(unique(hitTFs))<6, continue; end
hitTF_counts = histc(hitTFs, change_TF_vals);
if any(hitTF_counts<4)
    continue
end
if sum(sess_in_roi) < 5
    continue
end
sp = sp_all{s};
sp.cids = sp.cids(sess_in_roi);
spx2keep = ismember(sp.clu, sp.cids);
sp.clu  = sp.clu(spx2keep);
sp.st   = sp.st(spx2keep);
[fr, tax_fr] = spike_times_to_fr(sp, 10);
%clear sp

fr = (fr - mu)./sd;
fr = smoothdata(fr, 2, 'movmean', 3);

% make sure all tf changes are included in training set
all_changes_inc = 0;
while ~all_changes_inc
    ids = randperm(nTr);
    train_trs = ids(1:nTrain);
    valid_trs = ids(nTrain+1:end);
    
    trials_train = trials(train_trs);
    hits   = strcmp({trials_train.trialOutcome}, 'Hit') & ...
        ~contains({trials_train.trialType}, 'U')   & ...
        [trials_train.changeTF] ~= 2;
    hitTFs = [trials_train(hits).changeTF];
    hitTF_counts_train = histc(hitTFs, change_TF_vals);
    
    
    trials_valid = trials(valid_trs);
    hits   = strcmp({trials_valid.trialOutcome}, 'Hit') & ...
        ~contains({trials_valid.trialType}, 'U')   & ...
        [trials_valid.changeTF] ~= 2;
    hitTFs = [trials_valid(hits).changeTF];
    hitTF_counts_valid = histc(hitTFs, change_TF_vals);
    
    if all(hitTF_counts_train >= 2) & all(hitTF_counts_valid >= 1)
        all_changes_inc = true;
        break
    end
end

% bootstrap sample units
nN = size(fr,1);
nF = 0;
nS = 0;
while nF<2 | nS<2
    iter_units = sort(datasample(1:nN, nN))';
    nF = sum(fast_sess(iter_units));
    nS = sum(slow_sess(iter_units));
end
%         iter_units = sort(randperm(nN, round(nN/2)));
%         iter_units = 1:nN;
fr = fr(iter_units,:);
fast_iters = vertcat(fast_iters, fast_sess(iter_units));
slow_iters = vertcat(slow_iters, slow_sess(iter_units));

units_inc = vertcat(units_inc, iter_units);
% generate trials and daq structures training and validation trials
%[trials_train, daq_train] = get_trial_subset(trials, daq, train_trs);
[trials_valid, daq_valid] = get_trial_subset(trials, daq, valid_trs);

% get responses
%resps_train_sess = calculate_session_responses(trials_train, daq_train, fr, tax_fr, cont, flip_time, ops);
resps_valid_sess = calculate_session_responses(trials_valid, daq_valid, fr, tax_fr, cont, flip_time, ops);

% make sure all responses have correct length
%resps_train_sess = correct_resp_size(resps_train_sess);
resps_valid_sess = correct_resp_size(resps_valid_sess);

if isempty(avg_resps_valid)
    %avg_resps_train = struct2table(resps_train_sess);
    avg_resps_valid = struct2table(resps_valid_sess);
else
    %avg_resps_train = vertcat(avg_resps_train, struct2table(resps_train_sess));
    avg_resps_valid = vertcat(avg_resps_valid, struct2table(resps_valid_sess));
end

% get lick events in training and validation trials
train_lick_ids = ismember(licks.trial, train_trs);
Ns_train{s} = N(iter_units,train_lick_ids,:);
Ms_train{s} = M(:, train_lick_ids,:);
lick_inf_train{s} = lick_inf{s};
lick_inf_train{s}.times   = lick_inf_train{s}.times(train_lick_ids);
lick_inf_train{s}.trTimes = lick_inf_train{s}.trTimes(train_lick_ids);
lick_inf_train{s}.type    = lick_inf_train{s}.type(train_lick_ids);
lick_inf_train{s}.dir     = lick_inf_train{s}.dir(train_lick_ids);
lick_inf_train{s}.trial   = lick_inf_train{s}.trial(train_lick_ids);

valid_lick_ids = ismember(licks.trial, valid_trs);
Ns_valid{s} = N(iter_units,valid_lick_ids,:);
Ms_valid{s} = M(:, valid_lick_ids,:);
lick_inf_valid{s} = lick_inf{s};
lick_inf_valid{s}.times   = lick_inf_valid{s}.times(valid_lick_ids);
lick_inf_valid{s}.trTimes = lick_inf_valid{s}.trTimes(valid_lick_ids);
lick_inf_valid{s}.type    = lick_inf_valid{s}.type(valid_lick_ids);
lick_inf_valid{s}.dir     = lick_inf_valid{s}.dir(valid_lick_ids);
lick_inf_valid{s}.trial   = lick_inf_valid{s}.trial(valid_lick_ids);
end
sampled_units{iter} = units_inc;
fast_iters = logical(fast_iters);
slow_iters = logical(slow_iters);

end