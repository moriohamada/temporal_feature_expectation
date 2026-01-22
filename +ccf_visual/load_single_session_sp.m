function sp = load_single_session_sp(animal, session, ops)
% 
% --------------------------------------------------------------------------------------------------

sp = loadVariable(fullfile(ops.dataDir, sprintf('%s_%s.mat', animal, session)), 'sp');