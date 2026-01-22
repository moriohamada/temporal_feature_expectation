function elts = adjust_elt_by_rt(elts, chronos_all, ops)
% 
% Align different animals (sessions)? with different reaction times, but adjusting early lick time
% according to rt.
% 

n_animals = numel(elts);
%%
rt_estimates = nan(n_animals,1);
for a = 1:n_animals
    % get average rt for changes
    rt_estimates(a) = mean(chronos_all{a}(2, [1 2 3 5 6 7]));
end

% adjust rts to minimum rt
[min_rt, ~] = min(rt_estimates);

for a = 1:n_animals
    % Adjust the early lick triggered stimulus based on the minimum reaction time
    shift = round((rt_estimates(a) - min_rt)*10);

    elts{a} = circshift(elts{a}, shift, 2);

end


end