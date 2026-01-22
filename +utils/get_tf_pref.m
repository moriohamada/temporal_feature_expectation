function [tf_sensitive, tf_preference] = get_tf_pref(indexes)
 
tf_sensitive   = indexes.tf_short_p < 0.01 & ~isnan(indexes.tf_short) & ...
                 (sign(indexes.tf_short)==sign(indexes.tf_z_absPeakD)) & ...
                 (abs(indexes.tf_z_absPeakD)>1.96 & indexes.tf_z_absPeakD_p < .05); 
tf_preference  = indexes.tf_short;  

% tf_sensitive = (abs(indexes.tf_z_peakF)>2.58 | abs(indexes.tf_z_peakS)>2.58);
% tf_preference  = indexes.tf_short;  

% tf_sensitive   = indexes.tf_adaptive_p < 0.01 & ~isnan(indexes.tf_short) & ...
%                  (sign(indexes.tf_adaptive)==sign(indexes.tf_z_peakD)) & ...
%                  abs(indexes.tf_z_peakD)>1.5; 
% tf_preference  = indexes.tf_adaptive;  

tf_sensitive   = indexes.tf_short_p < 0.05 & ~isnan(indexes.tf_short);
tf_preference  = indexes.tf_short;  


end
