function daq_all = add_mouth_opening_to_daq(sessions, daq_all, ops)
%%
for s = 1:length(daq_all)
    
    if isempty(daq_all{s}), continue; end
    
    animal = sessions(s).animal;
    sess   = sessions(s).session;
    
    mouth_opening_times_file = fullfile(strrep(ops.dataDir,'npx','videography'), 'lick_onsets', ...
                                        sprintf('%s_%s.mat', animal, sess));
                                    
    if exist(mouth_opening_times_file, 'file')
        mouth_opening = load(mouth_opening_times_file);
        daq_all{s}.mouthOpening = mouth_opening;
    else
        continue
    end
    
end

end