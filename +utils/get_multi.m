function multi = get_multi(avg_resps, indexes)

multi = avg_resps.FRmu < .25 | avg_resps.FRsd  < .25 | ...
        ~utils.get_good_subjects(avg_resps) | ...
        avg_resps.cg == 0;
    
% if nargin>1
%     multi = multi | ~utils.get_responsive_units(indexes);
% end


end