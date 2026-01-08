function [time_sensitive, time_preference] = get_time_pref(indexes)

time_sensitive  = indexes.timePreTF_p<.01 & ~isnan(indexes.timePreTF) ;
% time_sensitive = indexes.timeBL_p<.01;
time_preference = indexes.timePreTF;
% time_sensitive  = indexes.timeBL_p<.01 & ~isnan(indexes.timeBL);
% time_preference = indexes.timeBL;

end