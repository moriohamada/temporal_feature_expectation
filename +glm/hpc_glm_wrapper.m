function hpc_glm_wrapper(nCat)
% 
% Wrapper function for running glm.fit_glm_main.m on chunks of 10 units
% on hpc.


[~, name] = system('hostname');
name = name(1:5);
if strcmp(name, 'earth')
addpath(genpath('/home/morio/Documents/MATLAB/General'));
addpath(genpath('/home/morio/Documents/MATLAB/switch-task/final_pipeline'));
else
addpath(genpath('/nfs/nhome/live/morioh/Documents/MATLAB/General'));
addpath(genpath('/nfs/nhome/live/morioh/Documents/MATLAB/final_pipeline'));
end 

ns = nCat*10 + (1:10);
for n = ns
    try
        glm.fit_glm_main(n);
    catch me
        fprintf('!!! Errored !!!\n')
        fprintf('Error message: %s\n', me.message);
        fprintf('Error trace: \n');
        disp(me.stack)

    end
    fprintf('\n')
end

end