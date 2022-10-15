function is_stable = find_stable_clusters(sp, ops)
% 
% Find units with sufficiently high firing rate and stable recordings.
% 
% INPUTS -------------------------------------------------------------------------------------------
% 
% sp 
%   struct
%   kilosort output struct
% 
% ops
%   struct, with fields:
%   - minFR: minimum average firing rate (Hz) over entire recording to consider a 'stable' unit
%   - minFRDrop: minimum firing rate neuron can drop to in any 10% period of session,
%                relative to mean FR
% 
% OUTPUTS ------------------------------------------------------------------------------------------
% 
% is_stable
%   logical vector
%   Whether each neuron is a 'good' (high firing, stable) unit (1) or not (0)
% 
% EXAMPLE USE --------------------------------------------------------------------------------------
% 
% ops.minFR     = .5;             % minimum firing rate for neuron to be considered
% ops.minFRDrop = .2;              % minimum firing rate neuron can drop to relative to mean
% is_stable = find_stable_clusters(sp, ops);
% 
%%

nN = length(sp.cids);
% tT = sp.st(end);

is_stable = zeros(1, nN);

for n = 1:nN
   
    st = sp.st(sp.clu == sp.cids(n));
    
    if isempty(st)
        continue
    end
    
    tT = range(sp.st);
    
    mean_fr = length(st)/tT;
    
    if mean_fr < ops.minFR
        continue
    end
    
    if ops.minFRDrop > 0
        % chunk session into 10 segments
        try
            t_wins = linspace(0, tT, 11);
        catch
            keyboard
        end
        
        win_to_avg = zeros(1, 10);
        
        for w = 1:10
            fr_win = sum(st>t_wins(w) & st<t_wins(w+1)) / (t_wins(w+1) - t_wins(w));
            win_to_avg(w) = fr_win/mean_fr;
            if win_to_avg(w) < ops.minFRDrop
                break
            end
        end
        
        if mean_fr > ops.minFR & min(win_to_avg) > ops.minFRDrop
            is_stable(n) = 1;
        end
    else
        if mean_fr > ops.minFR
            is_stable(n) = 1;
        end
    end
    
end

is_stable = logical(is_stable);

end