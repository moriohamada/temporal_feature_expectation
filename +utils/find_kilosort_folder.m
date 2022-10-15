function ksf = find_kilosort_folder(probe_dir)
% find ks folder within directory - look for ks4 first, then 2.5, then 2.
order = {'kilosort4'};
ksf = '';
for ii = 1:length(order)
    if isfolder(fullfile(probe_dir, order{ii}))
        ksf = fullfile(probe_dir, order{ii});
        break
    end
end
% if isempty(ksf)
%     % check if directory itself has spike sorting outputs
%     if any(contains(dir2(probe_dir), 'spike_times.npy'))
%         ksf = probe_dir;
%     end
% end
end