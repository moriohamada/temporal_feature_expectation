function [indexes, avg_resps, t_ax, allen_areas, roi_titles] = load_indexes_resps(sessions, ops)


%% Load indexes and responses 

indexes = table;

% load in indexes
for s = 1:length(sessions)
    animal  = sessions(s).animal;
    session = sessions(s).session;

    if strcmp(session(1), 'h') % not recording session
        continue
    end
    
    inds = loadVariable(fullfile(ops.indexesDir, sprintf('%s_%s.mat', animal, session)), 'indexes');
    inds.session = string(inds.session);
    indexes = vertcat(indexes, inds);
end

% get average responses for every unit
avg_resps = table(); 

varNames = {'animal', 'session', 'cid', 'loc', 'FRmu', 'FRsd', 'bl', 'FexpF', 'FexpS', 'SexpF', 'SexpS', ...
            'FAexpF', 'FAexpS', ...
            'hitF', 'hitS', 'hitE1', 'hitE2', 'hitE3', 'hitE4', 'hitE5', 'hitE6', 'hitE7',  ...
            'hitEshort1', 'hitEshort2', 'hitEshort3', 'hitEshort4','hitEshort5','hitEshort6','hitEshort7',...
            'hitElong1', 'hitElong2', 'hitElong3', 'hitElong4','hitElong5','hitElong6','hitElong7',...
            'hitLickF', 'hitLickS', 'hitLickE1','hitLickE2','hitLickE3','hitLickE4','hitLickE5','hitLickE6','hitLickE7'};


for s = 1:length(sessions)
    animal  = sessions(s).animal;
    session = sessions(s).session;

    if strcmp(session(1), 'h') % not recording session
        continue
    end
    
    r = loadVariable(fullfile(ops.avgPSTHdir, sprintf('%s_%s.mat', animal, session)), 'r');
    
    vars = fields(r);
    for v = 7:width(r)
        varName = vars{v};
        if strcmp(varName(end-1:end), '_n')
            continue
        end
        if mod(size(r.(varName),2),5)==1
            r.(varName) = r.(varName)(:,1:end-1);
        end
        if mod(size(r.(varName),2),5)==4
            r.(varName) = cat(2,r.(varName), nan(size(r.(varName),1),1));
        end
    end
    
    
    % Fast and slow hits
    r.hitS = (r.hitE1.*r.hitE1_n + r.hitE2.*r.hitE2_n + r.hitE3.*r.hitE3_n)./(r.hitE1_n + r.hitE2_n + r.hitE3_n);
    r.hitF = (r.hitE5.*r.hitE5_n + r.hitE6.*r.hitE6_n + r.hitE7.*r.hitE7_n)./(r.hitE5_n + r.hitE6_n + r.hitE7_n);
   
    r.hitLickS = (r.hitLickE1.*r.hitLickE1_n + r.hitLickE2.*r.hitLickE2_n + r.hitLickE3.*r.hitLickE3_n)./(r.hitLickE1_n + r.hitLickE2_n + r.hitLickE3_n);
    r.hitLickF = (r.hitLickE5.*r.hitLickE5_n + r.hitLickE6.*r.hitLickE6_n + r.hitLickE7.*r.hitLickE7_n)./(r.hitLickE5_n + r.hitLickE6_n + r.hitLickE7_n);
    
    % false alarms - group by expF/expS
    % r.FAexpF = (r.FAFexpF.*r.FAFexpF_n + r.FASexpF.*r.FASexpF_n + r.FAMexpF.*r.FAMexpF)./(r.FAFexpF_n + r.FASexpF_n + r.FAMexpF_n);
    % r.FAexpS = (r.FAFexpS.*r.FAFexpS_n + r.FASexpS.*r.FASexpS_n + r.FAMexpS.*r.FAMexpS)./(r.FAFexpS_n + r.FASexpS_n + r.FAMexpS_n);
    r = r(:,varNames);
    r.session = string(r.session);
    if isempty(avg_resps)
        avg_resps = r;
        t_ax = loadVariable(fullfile(ops.avgPSTHdir, sprintf('%s_%s.mat', animal, session)), 'time_axes');
    else
        avg_resps = [avg_resps; r];
    end
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

%% 

avg_resps.animal = string(avg_resps.animal);
avg_resps.session = string(avg_resps.session);
indexes.animal = string(indexes.animal);
indexes.session = string(indexes.session);

% fix avererage responses
% avg_resps.FRsd = avg_resps.FRsd / 10;


avg_resps.cg = indexes.cg;

end