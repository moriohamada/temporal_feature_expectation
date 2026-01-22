function [fr, t_ax] = spike_times_to_fr(sp, bin_width, t_ax)
% 
% Convert spike times to firing rate trace
% 
% --------------------------------------------------------------------------------------------------

if ~exist('t_ax', 'var') || isempty(t_ax)
    t_ax = min(sp.st):bin_width/1000:(max(sp.st)+5);
end

fr = histcounts2(sp.st, sp.clu, t_ax, [sort(sp.cids); inf])';

t_ax = t_ax(1:end-1);

end