function good_subj = get_good_subjects(avg_resps)

ephys_subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006',  'MH_010', 'MH_011', ...
                  'MH_015', 'MH_100', 'MH_103', 'MH_105', 'MH_111'};
% ephys_subjects = {'MH_001', 'MH_002', 'MH_004', 'MH_006',  'MH_010', 'MH_011','MH_015'};
% ephys_subjects = {'MH_100', 'MH_103', 'MH_105', 'MH_111'};
% 
good_subj = ismember(avg_resps.animal, ephys_subjects);


end