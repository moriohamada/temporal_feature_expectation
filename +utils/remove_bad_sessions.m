
function [sessions, trials_all, daq_all, sp_all] = remove_bad_sessions(sessions, trials_all, daq_all, sp_all, ops)

keep_session = false(numel(sessions),1);

for s = 1:length(sessions)
   trials  = trials_all{s};
   n_hits  = sum(strcmp({trials.trialOutcome}, 'Hit'));
   good_tr = sum([trials.keepTrial]);
   if n_hits > ops.minNumHits & good_tr > ops.minNumTrials
       keep_session(s) = 1;
   end
end

% sp_all and daq_all may be shorter in length than others if last sessions are behaviour only
if length(sp_all)<length(sessions)
    extra = cell(length(sessions)-length(sp_all),1);
    sp_all = vertcat(sp_all, extra);
    daq_all = vertcat(daq_all, extra); 
end

% remove bad sessions
sessions(~keep_session) = [];
trials_all = trials_all(keep_session);
daq_all = daq_all(keep_session);
sp_all = sp_all(keep_session);
end