function neuron_coords_allen = bregma_to_allen(neuron_coords_bregma)

% Bregma coordinates in the Allen CCF (in micrometers)
bregma_coords_allen = [5739; 5400; 440];  % [ML; AP; DV] 

% Transform neuron coordinates to the Allen CCF
neuron_coords_allen = bregma_coords_allen - neuron_coords_bregma;

% Rotate CCF to account for saggital plane titlt
neuron_coords_allen(1,:) = neuron_coords_allen(1,:) * cos(0.0873) - neuron_coords_allen(3,:) * sin(0.0873);
neuron_coords_allen(3,:) = neuron_coords_allen(1,:) * sin(0.0873) + neuron_coords_allen(3,:) * cos(0.0873);

% squeeze dv
neuron_coords_allen(3,:) = neuron_coords_allen(3,:) * .9434;

% 
% % If your AP axis is reversed, subtract instead
% neuron_coords_allen(2, :) = bregma_coords_allen(2) - neuron_coords_bregma(2, :);

% flip DV
% neuron_coords_allen(3, :) = neuron_coords_allen(3, :) * -1;