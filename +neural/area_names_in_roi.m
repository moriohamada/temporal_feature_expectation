function area_names = area_names_in_roi(rois)
% 
% Get names of all allen ccf areas that fall under some region of interest. 
% 
% --------------------------------------------------------------------------------------------------

area_names = cell(length(rois),1);

for r = 1:length(rois)
    
    roi = rois{r};

    switch roi 
        case 'MOs/CP'
            area_names{r} = {'CP',  'MOs1', 'MOs2/3', 'MOs5', 'MOs6b', 'STR'};
            
        case 'VIS'
            area_names{r} = {'VISp1','VISp2/3','VISp4', 'VISp5','VISp6', 'LGd', 'LP'};
            
        case 'PPC'
            area_names{r} = {'VISa1', 'VISa2/3', 'VISa4', 'VISa5', 'VISa6a', 'VISa6b', ...
                             'VISrl1', 'VISrl2/3', 'VISrl4', 'VISrl5', 'VISrl6a', 'VISrl6b', ...
                             'VISam1', 'VISam2/3', 'VISam4', 'VISam5', 'VISam6a', 'VISam6b', ...
                             'VISpm1', 'VISpm2/3', 'VISpm4', 'VISpm5', 'VISpm6a', 'VISpm6b', ...
                             'TH', 'SPFm', 'PVT', 'PO', 'POL'};
            
        otherwise
             keyboard
    end
                
end


end