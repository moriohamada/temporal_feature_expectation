function [ev_t_ax, psth] = get_response_to_event_from_FR_matrix(X, t_ax, event_times, win)
% 
% Return nN x nEvents x nT array with responses of each unit to every event.
% 

nEvents = length(event_times);
nN = size(X,1);
ev_t_ax = win(1):mode(diff(t_ax)):(win(2)-mode(diff(t_ax)));

psth = nan(nN, nEvents, numel(ev_t_ax));

event_wins = event_times + win';

% expected number resps 
exp_win = range(win)/mode(diff(t_ax));

% for each event, get all neurons' firing rates
for ee = 1:nEvents

    in_win = t_ax >= event_wins(1,ee) & t_ax < event_wins(2,ee);
    if abs(exp_win - sum(in_win)) > 1
        continue
    end
    
    psth(:,ee,1:sum(in_win)) = X(:,in_win);
end

psth = psth(:,:,1:numel(ev_t_ax));

end