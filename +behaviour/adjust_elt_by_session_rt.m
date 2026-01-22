function elts = adjust_elts_by_session_rt(elts, chrono)


rt_est = mean(chrono(2, [1 2 3 5 6 7]), 'omitmissing');

% adjust to median RT (.86) (or minimum, for reference: .5775)
avg_rt = 0.6;

shift = round((rt_est - avg_rt)*20);

elts = circshift(elts, shift, 2);


end