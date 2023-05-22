function kernels = collate_glm_fits_v2(neuron_info, ops, type)
% 
% Return kernels and p values for every %unit fitted with GLM
%%
fprintf('\nLoading all glm kernel fits. This will take a moment...\n')
nN = height(neuron_info);
kernels = table;

switch type
    case 'basic'
        glm_dir = ops.fullGLMDir;
    case 'EL'
        glm_dir = ops.glmELDir;
    otherwise
        keyboard
end

if exist(fullfile(glm_dir, 'all_su_kernels.mat'), 'file')
    kernels = loadVariable(fullfile(glm_dir, 'all_su_kernels.mat'), 'kernels');
else

ii = 0;
for n = 1:nN
    
   animal = neuron_info{n,'animal'};
   session = neuron_info{n,'session'};
   
   if ~exist(fullfile(glm_dir, animal, session), 'dir')
       continue
   end
   
%    if neuron_info{n,'cg'} == 1
%        continue
%    end
   
   % load glm fit data
   cid = neuron_info{n, 'cid'};
   res_files = dir2(fullfile(glm_dir, animal, session));
   res_id = contains(res_files, sprintf('cid%d', cid));
   if sum(res_id)==0
       continue
   end
   res_file  = res_files{res_id};
   
   fit_info = load(fullfile(glm_dir, animal, session, res_file));
   
   % skip if lesioning everything isnt significant
   if fit_info.p_corr(end) > .01 | isnan(fit_info.p_corr(end))
       continue
   end
   
   ii = ii+1;
   
   unit_kernels = struct;
   unit_kernels.animal = animal;
   unit_kernels.session = session;
   unit_kernels.cid = cid;
   unit_kernels.loc = neuron_info{n,'loc'};
   for r = 1:length(fit_info.regressors)-4
       regressor = fit_info.regressors{r};
       unit_kernels.(regressor) = fit_info.w(fit_info.regressor_dims{r})';
       unit_kernels.(strcat(regressor,'_p')) = fit_info.p_corr_active(r);
   end
   
   
   % get refits
   if all(fit_info.p_corr_refit_active<.05), continue; end
   unit_kernels.TFbl_all_p = fit_info.p_corr_refit_active(1);
   unit_kernels.time_p     = fit_info.p_corr_refit_active(2);
   unit_kernels.premotor_p = fit_info.p_corr_refit_active(3);
   
%    keyboard
   
   % append to kernels
   kernels = vertcat(kernels, struct2table(unit_kernels, 'AsArray', true));
%     kernels(n) = struct2table(unit_kernels, 'AsArray', true);
  
end

% save 
save(fullfile(glm_dir, 'all_su_kernels.mat'), 'kernels', '-v7.3')
fprintf('done.\n')

end

end