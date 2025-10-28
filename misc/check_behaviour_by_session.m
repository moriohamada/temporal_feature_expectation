%% Quick script for checking performance by session


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

   sess_info{a_idx, s_idx} = sessions(s);
end

%% plot by session

for a = 12%11:size(psycho, 1)
    for s = 1:size(psycho, 2)
        if isempty(psycho{a,s})
            continue
        end
        
        figure;

        subplot(1,2,1)
        plot(psycho{a, s}(1,:), psycho{a, s}(2,:), 'k'); hold on;
        plot(psycho{a, s}(1,:), psycho{a, s}(3,:), 'color', [.6 .6 .6]);

        subplot(1,2,2); hold on;
        lick_t = elt{a,s};
        lick_s = elts{a,s};
        if strcmp(conts{a,s}, 'EFLS')
            early = isbetween(lick_t, [2 7]);
            late  = isbetween(lick_t, [7 20]);
        else
            late = isbetween(lick_t, [2 7]);
            early = isbetween(lick_t, [7 20]);
        end
        lick_stim_e = smoothdata(mean(lick_s(early,:),1,'omitmissing'), 'movmean', 3);
        lick_stim_l = smoothdata(mean(lick_s(late,:),1,'omitmissing'), 'movmean', 3);
        plot(linspace(-2, 0, 40), lick_stim_e, 'r');
        plot(linspace(-2, 0, 40), lick_stim_l, 'b');
        
        sgtitle(sprintf('%s %s', sess_info{a,s}.animal,sess_info{a,s}.session))

        pause;
        close all
    end
end

