function eltas = calculate_lta(elts, elt, wins, ops)
% 
% Calculate lick-triggered average stimuli in specified windows

for w = 1:size(wins,1)
   win = wins(w,:);
   
   eltas(w,:) = nanmean(elts(isbetween(elt, win),:),1);
   
end



end