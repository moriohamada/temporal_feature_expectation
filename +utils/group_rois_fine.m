function rois = group_rois_fine()

% early visual
rois{1,2} = {'LGd', 'LP'};

% VISp
rois{2,2} = {'VISp1','VISp2/3','VISp4', 'VISp5','VISp6a', 'VISp6b'};

% Sensory thalamus
rois{3,2} =  { 'PF', 'PO', 'POL', 'PVT', 'TH', 'VPM', 'SPFm', 'SPFp', 'SPA', 'Eth', 'CL', 'LH' };
            
% PPC
% rois{4,2} = {'VISa1', 'VISa2/3', 'VISa4', 'VISa5', 'VISa6a', 'VISa6b', ...
%              'VISrl1', 'VISrl2/3', 'VISrl4', 'VISrl5', 'VISrl6a', 'VISrl6b', ...
%              'VISam1', 'VISam2/3', 'VISam4', 'VISam5', 'VISam6a', 'VISam6b', ...
%              'VISpm1', 'VISpm2/3', 'VISpm4', 'VISpm5', 'VISpm6a', 'VISpm6b'};
rois{4,2} = {'VISa1', 'VISa2/3', 'VISa4', 'VISa5', 'VISa6a', 'VISa6b', ...
             'VISrl1', 'VISrl2/3', 'VISrl4', 'VISrl5', 'VISrl6a', 'VISrl6b', ...
             'VISam1', 'VISam2/3', 'VISam4', 'VISam5', 'VISam6a', 'VISam6b', ...
             'VISpm1', 'VISpm2/3', 'VISpm4', 'VISpm5', 'VISpm6a', 'VISpm6b', ...
             'RSPagl1', 'RSPagl2/3', 'RSPagl5', 'RSPagl6a', 'RSPagl6b', ...
             'RSPd1', 'RSPd2/3', 'RSPd5', 'RSPd6a', 'RSPd6b', ...
             'RSPv1', 'RSPv2/3', 'RSPv5', 'RSPv6a', 'RSPv6b'};
% MOs 
rois{5,2} = { 'MOs1', 'MOs2/3', 'MOs5', 'MOs6a', 'MOs6b'};

% Striatum
rois{6,2} = { 'CP',  'STR'};

rois(:, 1) = {'Visual thalamus', 'V1', 'Sensory thalamus', 'Higher Visual', 'MOs', 'Striatum'};
            
end