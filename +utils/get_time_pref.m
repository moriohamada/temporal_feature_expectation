function [time_sensitive, time_preference] = get_time_pref(indexes)

time_sensitive  = indexes.timePreTF_p<.01 & ~isnan(indexes.timePreTF) ;
 
time_preference = indexes.timePreTF; 

end
