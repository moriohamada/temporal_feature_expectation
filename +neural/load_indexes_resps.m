function [indexes, avg_resps, t_ax, allen_areas, roi_titles] = load_indexes_avgResps_all(sessions, neuron_info, ops)


%% Load indexes and responses


flip_times = loadVariable(fullfile(ops.dataDir, 'flip_times.mat'), 'flip_time');
animals = unique({sessions.animal});
% rois = {{'V1', 'Visual thalamus', 'Visual midbrain'}, ...
%         {'PPC','Visual cortex',  'Sensory thalamus'}, ...
%         {'MOs', 'BG'}};
rois = {{'Visual thalamus'}, ...
        {'Sensory thalamus'},...
        {'V1'},...
        {'Visual cortex', 'PPC'}, ...
        {'MOs', 'mPFC'}, ...
        {'BG'}};
roi_titles = {'Vis Th', 'Th', 'V1',  'PPC',  'MOs', 'BG'};


% subjects = {'MH_006'};
allen_areas = {};
for r = 1:length(rois)
    areas = area_names_in_roi(rois{r});
    
    while any(cellfun(@iscell, areas))
        areas = [areas{cellfun(@iscell,areas)} areas(~cellfun(@iscell,areas))];
    end
    allen_areas{r} = areas;
end

indexes = table;

% load in indexes
for s = 1:length(sessions)
    animal  = sessions(s).animal;
    session = sessions(s).session;

    if strcmp(session(1), 'h') % not recording session
        continue
    end
    
    inds = loadVariable(fullfile(ops.indexesDir, sprintf('%s_%s.mat', animal, session)), 'indexes');
    
    indexes = vertcat(indexes, inds);
end

% avg resps
avg_resps = table();
% resp_dir = strrep(ops.dataDir, 'session_data', 'avg_responses_tuning_multipulse_mouthO_hitTimes');
% resp_dir = strrep(ops.dataDir, 'session_data', 'avg_responses_basics');
% resp_dir = strrep(ops.dataDir, 'session_data', 'avg_responses_basics_sd1.5');

% resp_dir = strrep(ops.dataDir, 'session_data', 'avg_responses_basics_sd1.5_rmv2');
resp_dir =  strrep(ops.eventPSTHdir, 'event_responses', 'avg_responses');

for s = 1:length(sessions)
    animal  = sessions(s).animal;
    session = sessions(s).session;

    if strcmp(session(1), 'h') % not recording session
        continue
    end
    
    r = loadVariable(fullfile(resp_dir, sprintf('%s_%s.mat', animal, session)), 'r');
    vars = fields(r);
    
    varNames = vars;
%     keyboard
    varNames(startsWith(varNames, 'tfbin')|startsWith(varNames, 'tf_bin')|startsWith(varNames, 'proj')) = [];
    varNames(startsWith(varNames, 'FF') | startsWith(varNames, 'FS') | startsWith(varNames, 'SF') | startsWith(varNames, 'SS')) = [];
%     varNames(contains(varNames, 'exp') & contains(varNames, 'L')) = [];
    varNames(contains(varNames, 'miss') | contains(varNames, 'U')) = [];
    r = r(:,varNames(1:end-3));
    for v = 7:width(r)
        varName = varNames{v};
        if strcmp(varName(end-1:end), '_n') 
            continue
        end
        if strcmp(varName(end-1:end), '_t')
            if size(r.(varName),2) > 1
                r.(varName) = r.(varName)(:,1);
            elseif size(r.(varName),2) == 0
                r.(varName) = nan(size(r.(varName),1),1);
            end
        end
        if mod(size(r.(varName),2),5)==1
            r.(varName) = r.(varName)(:,1:end-1);
        end
        if mod(size(r.(varName),2),5)==4
            r.(varName) = cat(2,r.(varName), nan(size(r.(varName),1),1));
        end
    end
    
    % weighted avg of FAexpS and FAexpF
    r.FAexpF = (r.FAFexpF.*r.FAFexpF_n + r.FAMexpF.*r.FAMexpF_n + r.FASexpF.*r.FASexpF)./(r.FAFexpF_n+r.FAMexpF_n+r.FASexpF);
    r.FAexpS = (r.FAFexpS.*r.FAFexpS_n + r.FAMexpS.*r.FAMexpS_n + r.FASexpS.*r.FASexpS)./(r.FAFexpS_n+r.FAMexpS_n+r.FASexpS);
    
    r.FAFMexpF = (r.FAFexpF.*r.FAFexpF_n + r.FAMexpF.*r.FAMexpF_n)./(r.FAFexpF_n+r.FAMexpF_n);
    r.FASMexpS = (r.FAMexpS.*r.FAMexpS_n + r.FASexpS.*r.FASexpS)./(r.FAMexpS_n+r.FASexpS);
    
    % Fast and slow hits
    r.hitS = (r.hitE1.*r.hitE1_n + r.hitE2.*r.hitE2_n + r.hitE3.*r.hitE3_n)./(r.hitE1_n + r.hitE2_n + r.hitE3_n);
    r.hitF = (r.hitE5.*r.hitE5_n + r.hitE6.*r.hitE6_n + r.hitE7.*r.hitE7_n)./(r.hitE5_n + r.hitE6_n + r.hitE7_n);
  
%     r.missS = (r.missE1.*r.missE1_n + r.missE2.*r.missE2_n + r.missE3.*r.missE3_n)./(r.missE1_n + r.missE2_n + r.missE3_n);
%     r.missF = (r.missE5.*r.missE5_n + r.missE6.*r.missE6_n + r.missE7.*r.missE7_n)./(r.missE5_n + r.missE6_n + r.missE7_n);
    
    r.hitLickS = (r.hitLickE1.*r.hitLickE1_n + r.hitLickE2.*r.hitLickE2_n + r.hitLickE3.*r.hitLickE3_n)./(r.hitLickE1_n + r.hitLickE2_n + r.hitLickE3_n);
    r.hitLickF = (r.hitLickE5.*r.hitLickE5_n + r.hitLickE6.*r.hitLickE6_n + r.hitLickE7.*r.hitLickE7_n)./(r.hitLickE5_n + r.hitLickE6_n + r.hitLickE7_n);
   
    if isempty(avg_resps)
        avg_resps = r;
        t_ax = loadVariable(fullfile(resp_dir, sprintf('%s_%s.mat', animal, session)), 'time_axes');
        t_axes.fields = fields(t_ax);
        for t = 1:length(t_axes.fields)
            t_field = t_axes.fields{t};
            if mod(length(t_ax.(t_field)),5)==1
                t_ax.(t_field) = t_ax.(t_field)(1:end-1);
            end
        end
    else
        avg_resps = [avg_resps; r];
    end
end

% avg_resps = avg_resps(good_subj,:);

% subjects = {'MH_006'};
allen_areas = {};
for r = 1:length(rois)
    areas = area_names_in_roi(rois{r});
    
    while any(cellfun(@iscell, areas))
        areas = [areas{cellfun(@iscell,areas)} areas(~cellfun(@iscell,areas))];
    end
    allen_areas{r} = areas;
end


% need to flip around some animals - get contingencies
conts = nan(height(indexes),1);
for ii = 1:height(indexes)
    animal = indexes{ii,'animal'};
    session = indexes{ii,'session'};
    sess_id = strcmp({sessions.animal}, animal) & strcmp({sessions.session}, session);
    if strcmp(sessions(sess_id).contingency, 'EFLS')
        conts(ii) = 1;
    else
        conts(ii) = -1;
    end
end
indexes.conts = conts;

t_ax.tf = linspace(-.5, 1.5, 200);
end