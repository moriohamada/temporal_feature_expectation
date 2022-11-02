function [psycho, chrono, ntr] = calculate_psychometric(trials)

% change_tfs = sort(unique([trials.changeTF]));
change_tfs = [.25 1 1.5 2 2.5 3 3.75];
trials = trials([trials.keepTrial] & [trials.deviantsOn]);
ntr = length(trials);

change = [trials.changeTF];
hits = strcmp({trials.trialOutcome}, 'Hit');
miss = strcmp({trials.trialOutcome}, 'Miss');
exp  = strcmp({trials.trialType}, 'EarlyE') | ...
       strcmp({trials.trialType}, 'LateE' ) |...
       strcmp({trials.trialType}, 'zero');
uex  = strcmp({trials.trialType}, 'EarlyU') | ...
       strcmp({trials.trialType}, 'LateU' ) |...
       strcmp({trials.trialType}, 'zero');
   
rxn_times = [trials.reactionTimes];
rxn_times = [rxn_times.RT];

psycho = nan(3, length(change_tfs));
chrono = nan(3, length(change_tfs));
psycho(1,:) = change_tfs;
chrono(1,:) = change_tfs;

for ctf = 1:length(change_tfs)

    change_tf = change_tfs(ctf);
    
    psycho(2, ctf) = sum(change == change_tf & hits & exp) / ...
                     sum(change == change_tf & (hits | miss) & exp);
    psycho(3, ctf) = sum(change == change_tf & hits & uex) / ...
                     sum(change == change_tf & (hits | miss) & uex);
                 
    chrono(2, ctf) = nanmean(rxn_times(change == change_tf & hits & exp));
    chrono(3, ctf) = nanmean(rxn_times(change == change_tf & hits & uex));       
end


end