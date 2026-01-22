function daq = remove_unnecessary_daq_fields(daq)

to_remove = {'Synch', 'Front_cam', 'Eye_cam', 'Top_cam', 'Masking_ON', 'Laser_ON', 'Lick_R', 'Valve_R'};

daq = rmfield(daq, to_remove);

end