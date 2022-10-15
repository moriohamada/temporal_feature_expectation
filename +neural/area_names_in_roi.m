function area_names = area_names_in_roi(rois)
% 
% Get names of all allen ccf areas that fall under some region of interest.
% 
% e.g:
%   allen_areas = area_names_in_roi({'MOs', 'Visual Cortex'})
% 
% --------------------------------------------------------------------------------------------------

area_names = cell(length(rois),1);

for r = 1:length(rois)
    
    roi = rois{r};

    switch roi
        case 'MOs'
            area_names{r} = {'MOs', 'MD'};
        case 'MOp'
            area_names{r} = {'MOp'};
        case 'BG'
            area_names{r} = {'ACB', 'CP', 'SF', 'SI', 'STR'};
        case 'STR'
            area_names{r} = {'CP', 'STR'};
        case 'V1'
            area_names{r} = {'VISp1','VISp2/3','VISp4', 'VISp5','VISp6' };
        case 'mPFC'
            area_names{r} = {'PL', 'ILA'};
        case 'ACA'
            area_names{r} = {'ACAd', 'ACAv'};
        case 'PPC'
            area_names{r} = {'VISrl', 'VISam', 'VISa', 'VISpm'};
        case 'Visual cortex'
            area_names{r} = {'VISa', 'VISpm'};
        case 'HPC'
            area_names{r} = {'CA1', 'CA3', 'DG', 'alv', 'HPF', 'POST', 'PRE', 'ProS', 'SUB' , 'VL', 'dhc'};
        case 'Frontal cortex'
            area_names{r} = { 'ORB', 'TT', 'DP', 'AI', 'AON', 'FRP'};
        case 'SSp'
            area_names{r} = {'SSp'};
        case 'Motor thalamus'
            area_names{r} = {'MD', 'SPFm' };
        case 'Visual thalamus'
            area_names{r} = {'LGd', 'LP'};
        case 'Sensory thalamus'
            area_names{r} = {'APN',  'PF', 'PO', 'POL', 'PVT', 'TH'};
        case 'Sensorimotor thalamus'
            area_names{r} = {'LD', 'VPM', 'VPL', 'VM', 'VAL'};
        case 'Motor midbrain'
            area_names{r} = {'SCO', 'MRN', 'NOT', 'NPC', 'PAG','PRC', 'RN', 'SCdg', 'SCdw', 'SCig', 'SCiw'}; 
        case 'Visual midbrain'
            area_names{r} = {'SCop', 'SCsg', 'SCzo'};
        case 'Nonvisual thalamus'
            area_names{r} = {'CL', 'LH', 'SPFm'};
        case 'Non visual midbrain'
            area_names{r} = {'IF', 'MB'}; 
        case 'Superficial rostral'
            area_names{r} = {};
        case 'Superficial caudal'
            area_names{r} = {'CLA', 'EP', 'EPd', 'PIR'};
        case 'Deep rostral'
            area_names{r} = {'OT','LSc', 'LSr', 'LSv', 'OT', 'TRS'};
        case 'Deep caudal'
            area_names{r} = {'DP', 'IPR', 'IPRL', 'OLF'};
        case 'misc'
            area_names{r} = {'SEZ', 'V3', 'VL', 'bsc', 'ccb', 'ccg', 'ccs', 'ec', 'fa', 'fiber tracts', ...
                            'fp', 'frf', 'hbc', 'lot', 'or', 'pc', 'root', 'rust', 'scwm', 'sm', 'void'};
        case 'MOs/CP'
            area_names{r} = {'CP',  'MOs1', 'MOs2/3', 'MOs5', 'MOs6b', 'STR'};
            
        case 'VIS'
            area_names{r} = {'VISp1','VISp2/3','VISp4', 'VISp5','VISp6', 'LGd', 'LP'};
            
        case 'HVA'
            area_names{r} = {'VISa1', 'VISa2/3', 'VISa4', 'VISa5', 'VISa6a', 'VISa6b', ...
                             'VISrl1', 'VISrl2/3', 'VISrl4', 'VISrl5', 'VISrl6a', 'VISrl6b', ...
                             'VISam1', 'VISam2/3', 'VISam4', 'VISam5', 'VISam6a', 'VISam6b', ...
                             'VISpm1', 'VISpm2/3', 'VISpm4', 'VISpm5', 'VISpm6a', 'VISpm6b' };
            
        otherwise
            area_names{r} = roi;
%             keyboard
    end
                
end


end