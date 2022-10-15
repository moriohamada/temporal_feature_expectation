function [spd, t_ax] = rot_enc_to_speed(A_rise_t, A_fall_t, B_rise_t, B_fall_t, res)
% 
% MATLAB v2020b
% May 2021
% 
% Convert quadrature encoder signals to rpm. 
% 
% !!!
% NOTE: output is not quite correct! Currently assumes 3-state (rather than 4-state) encoder - i.e.,
%       movements are assumed to have same magnitude (this is likely not that case)!
% !!!
% 
% INPUTS -------------------------------------------------------------------------------------------
% 
%   A_rise_t, A_fall_t, B_rise_t, B_fall_t
%       [1 x nEvents] arrays containing times (seconds) of each event occurence.
% 
%   res
%       float; containing desired time resolution for returning spd (in seconds) (RECOMMENDED!)
%       OR
%       [1 x nT] vector of floats, specifing times axis to return speeds for (note, we estimate
%       position of the wheel by interpolation to res then calculate speed in this case. This input
%       should therefore not be arbritrary time points you wish to probe the speed for, but a
%       roughly continuous time axis (e.g. [0:.05:6e5], or time axes corresponding to baseline
%       segments ([12:.05:14.5, 19.2:.05:26.0, ...]). (NOT YET TESTED)
% 
% OUTPUTS ------------------------------------------------------------------------------------------
% 
%   spd
%       [1 x nT]: running speed over time
% 
%   t_ax 
%       [1 x nT]: time axis corresponding to spd
% 
% EXAMPLE USAGE ------------------------------------------------------------------------------------
% 
%   A_rise_t = daq.Rot_enc_A.rise_t';
%   A_fall_t = daq.Rot_enc_A.fall_t';
%   B_rise_t = daq.Rot_enc_B.rise_t';
%   B_fall_t = daq.Rot_enc_B.fall_t';
%   
%   resolution = .01; % 10ms resolution
%   
%   [speed, time_axis] = rot_enc_to_speed(A_rise_t, A_fall_t, B_rise_t, B_fall_t, resolution);
% 
% --------------------------------------------------------------------------------------------------

% Concatenante and sort all event times
[all_ev_times, order] = sort([A_rise_t, A_fall_t, B_rise_t, B_fall_t], 'ascend');

% Label each event with unique value
all_ev_idx   = [1*ones(1,length(A_rise_t)), ...
                2*ones(1,length(A_fall_t)), ...
                3*ones(1,length(B_rise_t)), ...
                4*ones(1, length(B_fall_t))];
            
all_ev_idx = all_ev_idx(order);

% get starting states - if first change was a rise, then start must be 0
if A_rise_t(1) < A_fall_t(1) 
    a = 0; 
else
    a = 1;
end

if B_rise_t(1) < B_fall_t(1)
    b = 0;
else
    b = 1;
end

state = [a, b];

% initialize vector for storing positions
pos = nan(1, 1+length(all_ev_times));

% assign starting point as zero
pos(1) = 0;

for ii = 1:length(all_ev_times)
    
    e = all_ev_idx(ii);
    
    prev_state = state;
    
    switch e 
        
        case 1 % enc A activated
            switch state(2)
                case 0 % clockwise movement
                    mv = 1;
                case 1 % ccw movement
                    mv = -1;
            end
            
            state(1) = 1;
            
        case 2 % enc A deactivated
            switch state(2)
                case 0  % ccw movement
                    mv = -1;
                case 1  % clockwise movement
                    mv = 1;
            end
            
            state(1) = 0;
            
        case 3 % enc B activated
            switch state(1)
                case 0 % ccw
                    mv = -1;
                case 1 % ccw
                    mv = 1;
            end
            
            state(2) = 1;
            
        case 4 % enc B deactivated
            switch state(1)
                case 0 % cw
                    mv = 1;
                case 1 % ccw
                    mv = -1;
            end
            
            state(2) = 0;
            
    end
    
    if all(isequal(state, prev_state))
        warning('something went horribly wrong...')
        keyboard
    end
    
    pos(ii+1) = pos(ii) + mv;
    
    % add tiny offset if event times are same as prev
    if ii > 1
        if all_ev_times(ii) == all_ev_times(ii-1)
            all_ev_times(ii) = all_ev_times(ii) + 1e-9;
        end
    end
    
end

% interpolate to desired time resolution
if isscalar(res)
    
    t_ax = 0:res:max(all_ev_times);
    pos_interp = interp1([0 all_ev_times], pos, t_ax);
    
    spd  = (diff(pos_interp)/res);
    t_ax = t_ax(2:end);
    
elseif length(res) > 1
    
    pos_interp = interp1([0 all_ev_times], pos, res);
    spd  = (diff(pos_interp)./diff(res)) /100;
    t_ax = res(2:end);
    
end

%% Sanity check
% % keyboard
% tr = 1; % an aborted trial
% tr_period = [daq.Baseline_ON.rise_t(tr), daq.Baseline_ON.fall_t(tr)+1];
% t_in_tr = t_ax > tr_period(1) & t_ax < tr_period(2);
% figure; plot(t_ax(t_in_tr), spd(t_in_tr));
% hold on;
% yl = ylim;
% plot([daq.Baseline_ON.fall_t(tr) daq.Baseline_ON.fall_t(tr)], yl, 'k');
% % 

end