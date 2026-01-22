function tf_values = get_each_timebin_tf(tf_vector, frame_times, tr_start, tr_end, bin_size)

% duration    = ceil((tr_end - tr_start)/bin_size); % convert frame times
% tf_vector   = tf_vector(tf_vector~=0); % remove grey screen periods
% 
% bin_times   = 0:bin_size:(tr_end-tr_start);
% 
% % for each bin, calculate what the tf value on screen was
% tf_values = zeros(duration, 1);
% 
% % get frame times
% if delayed <= 3
%     t = frame_times-tr_start;
% else
%     t = tr_start:1/60:tr_end;
% end
% t = t(1:3:end);
% tf_vector = tf_vector(1:3:length(t));
% 
% % for each tf, place value in nearest bin
% 
% for ii = 1:length(tf_vector)
%     fr_t = t(ii);
%     [~, nearest_bin] = min(abs(fr_t - bin_times));
%     tf_values(nearest_bin) = tf_vector(ii);
% end

% change frame times if too delayed
% if delayed > 3
%     frame_times = tr_start:1/60:tr_end;
% end


duration    = ceil((tr_end - tr_start)*(1/bin_size)); % convert frame times
tf_vector   = tf_vector(tf_vector~=0); % remove grey screen periods

bin_times   = frame_times(1):bin_size:tr_end+.05;

% for each bin, calculate what the tf value on screen was
tf_values = zeros(duration, 1);

if length(frame_times) > length(tf_vector)
    frame_times = frame_times(1:length(tf_vector));
end
for bin_i = 1:duration
    
    if bin_i >duration
        break
    end
    
    bin_t = bin_times(bin_i);
    
    if bin_t < frame_times(1) | bin_t > frame_times(end) + 1/60
        continue
    end
    
    [curr_frame_onset, curr_fr_idx] = max(frame_times(frame_times<=bin_t));
    tf_values(bin_i) = tf_vector(curr_fr_idx);

end
end