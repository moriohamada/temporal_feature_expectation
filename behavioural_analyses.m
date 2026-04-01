function behavioural_analyses(sessions, trials_all, ops)
% 
% Produce psychometric, chronometric, and early lick triggered average plots in Figure 1, as well as
% multi-pulse psychometric plots in Figure 2.
% 
% --------------------------------------------------------------------------------------------------

plot_save_dir = fullfile(ops.saveDir, 'behaviour');
if ~exist(plot_save_dir, 'dir'), mkdir(plot_save_dir); end

%% Calculate lick psychometric and get lick-aligned stimuli for each session

n_sess = length(sessions);
a_idx = 0;
s_idx = 0;
last_animal = '';
 
for s = 1:n_sess
   animal  = sessions(s).animal;
   if ~strcmp(last_animal, animal)
       last_animal = animal;
       a_idx  = a_idx + 1;
       s_idx = 1;
   else
       s_idx = s_idx + 1;
   end
   
   session = sessions(s).session;
   cont    = sessions(s).contingency;
   
   [psycho{a_idx, s_idx}, chrono{a_idx, s_idx}, n_tr{a_idx, s_idx}] ...
                                         = behaviour.calculate_session_psychometric(trials_all{s});
   
   [elts{a_idx, s_idx}, elt{a_idx, s_idx}] = behaviour.get_lick_triggered_stimuli(trials_all{s}, ops); 
   elts{a_idx, s_idx} = behaviour.adjust_elt_by_session_rt(elts{a_idx, s_idx}, chrono{a_idx, s_idx});
   conts{a_idx, s_idx} = sessions(s).contingency;
end


%% Average psychometric/chronometric across animals

animals = unique({sessions.animal});
for a = 1:length(animals)    
    % collapse psycho/chrono across sessions, per mouse
    psycho_a = psycho(a,:);
    psycho_a = psycho_a(~cellfun('isempty', psycho_a));
    psycho_a = cell2mat(vertcat(psycho_a'));

    psychos_a_exp = psycho_a(2:3:end,:);
    psychos_a_uex = psycho_a(3:3:end,:);
    
    chrono_a = chrono(a,:);
    chrono_a = chrono_a(~cellfun('isempty', chrono_a));
    chrono_a = cell2mat(vertcat(chrono_a'));
    chronos_a_exp = chrono_a(2:3:end,:);
    chronos_a_uex = chrono_a(3:3:end,:);
    
    psychos_all{a} = [psycho_a(1,:); nanmean(psychos_a_exp,1); nanmean(psychos_a_uex)];
    chronos_all{a} = [chrono_a(1,:); nanmean(chronos_a_exp,1); nanmean(chronos_a_uex)];
    
    % also concatenate average lta by mouse
    elts_all{a} = vertcat(elts{a,:});
    elts_all{a} = elts_all{a} - mean(elts_all{a},1, 'omitmissing');
    elt_all{a}  = vertcat(elt{a,:});
end


behaviour.plot_psycho(psychos_all, chronos_all, ops);

%% Plot lick-triggered average by expectation

% Adjust early lick times by RT
% elts_aligned = behaviour.adjust_elt_by_rt(elts_all, chronos_all, ops);

elts_aligned = elts_all;
for a = 1:length(animals)
    
    flip_time(a) = behaviour.calculate_flip_time(elts_aligned{a}, elt_all{a}, ops);
    
    % define expF vs expS windows
    wins = [ops.ignoreTrStart, flip_time(a)-.5; ...
             flip_time(a)+.5, 20];
    
    % get lta - exp slow vs exp fast
    elta_el = behaviour.calculate_lta(elts_aligned{a}, elt_all{a}, wins, ops);
    
    % for animals on reversed contigency, flip windows
    switch conts{a,1}
        case 'EFLS'
            eltas(a).F = elta_el(1,:);
            eltas(a).S = elta_el(2,:);
        case 'ESLF'
            eltas(a).S = elta_el(1,:);
            eltas(a).F = elta_el(2,:);
    end
     
end

behaviour.plot_elta(eltas, ops); 

% save flip times for alter analyses
save(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time')

%% Calculate multi-pulse lick probabilities (Figure 2)

for a = 1:length(animals)
    
    % get sessions corresponding to animal
    animal = animals{a};
    sess_ids = strcmp({sessions.animal}, animal);
    trials_animal = vertcat(trials_all{sess_ids});
    trials_animal = trials_animal(logical([trials_animal.keepTrial]) & logical([trials_animal.deviantsOn]));
    
    % get every TF pulse, time, tr, next lick time, trial outcome
    [tfs, ~, stim_time, licked] = behaviour.get_all_tf_pulses(trials_animal, ops);
    
    % flip tf for reverse contingency mice
    if strcmp(conts{a,1}, 'ESLF')
        tfs = -tfs;
    end

     
    [p_lick_singlePulse{a}, p_lick_2pulse{a}, bins] = ...
                behaviour.calculate_multi_pulse_lick_probability(tfs, stim_time, licked, [ops.ignoreTrStart inf], ops);
            
    % Separate into early/late phases
    wins_FS = [ops.ignoreTrStart, flip_time(a)-.5; ...
               flip_time(a)+.5, inf];
    % wins_FS = [2 6; 7 inf];
           
    [p_lick_singlePulse_FS{a}, p_lick_2pulse_FS{a}, bins] = ...
                behaviour.calculate_multi_pulse_lick_probability(tfs, stim_time, licked, wins_FS, ops);
            
end 
%%
behaviour.plot_multi_pulse_lick_probability_by_expectation(p_lick_singlePulse, p_lick_2pulse, p_lick_singlePulse_FS, p_lick_2pulse_FS,  bins, ops);

 
end


