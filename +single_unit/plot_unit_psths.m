function f = plot_single_unit_psths(ev_times, st, flip_time, ops)

f = figure('Units', 'normalized', 'OuterPosition', [.1 .1 .5 .25]); hold on;

% PSTH smoothing filter
gw = gausswin(round((ops.spSmoothSize/ops.spBinWidth)*5),3);
smWin = gw./sum(gw);
% smoothWin = [20 10];
%% baseline onset

[psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(1).times, ev_times(1).win + [-.2 .2], ops.spBinWidth/1000);

% smooth ba
baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);
% raster
[tr,b] = find(ba);
[rasterX, yy] = rasterize(bins(b));
rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything

% scale the raster ticks
rasterScale = floor(numel(ev_times(1).times)/100);
rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;
    
subplot(2, 9, 1);
shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', 'k'});
xlim([-1 2])


subplot(2, 9, 10); hold on
plot(rasterX, rasterY, 'k');
xlim([-1 2])


%% baseline long
% PSTH smoothing filter
gw = gausswin(round((ops.spSmoothSize/ops.spBinWidth)*5),2);
smWin = gw./sum(gw);
[psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(2).times, ev_times(2).win + [-.2 .2], ops.spBinWidth/1000);

% smooth ba
baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin*5)./(ops.spBinWidth/1000);

% raster
[tr,b] = find(ba);
[rasterX, yy] = rasterize(bins(b));
rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
% scale the raster ticks
rasterScale = floor(numel(ev_times(2).times)/100);
rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;
    
subplot(2, 9, 2); cla
shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', 'k'});
xlim([-2 12])


subplot(2, 9, 11); hold on
plot(rasterX, rasterY, 'k');
xlim([-2 12])

% PSTH smoothing filter
gw = gausswin(round(5*5),3);
smWin = gw./sum(gw);

%% Change

% PSTH smoothing filter

gw = gausswin(round((ops.spSmoothSize/ops.spBinWidth)*5),3);
smWin = gw./sum(gw);

% Hits 
E_hits = strcmp(ev_times(3).classes(1,:), 'exp_hit');
U_hits = strcmp(ev_times(3).classes(1,:), 'uex_hit');
fast   = [ev_times(3).classes{2,:}] > 2;
slow   = [ev_times(3).classes{2,:}] < 2;
zero   = [ev_times(3).classes{2,:}] == 2;

% E hit, fast
[psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(3).times(E_hits & fast), ev_times(2).win + [-.2 .2], ops.spBinWidth/1000);

% smooth ba
baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);
% keyboard

% raster
[tr,b] = find(ba);
[rasterX, yy] = rasterize(bins(b));
rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
% scale the raster ticks
rasterScale = floor(numel(ev_times(1).times)/100);
rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;


subplot(2, 9, 3);
shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.F});
xlim([-1 2])


subplot(2, 9,12); hold on
plot(rasterX, rasterY, 'Color',  ops.colors.F);
xlim([-1 2])
max_y = max(rasterY);

% E hit, slow

[psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(3).times(E_hits & slow), ev_times(2).win + [-.2 .2], ops.spBinWidth/1000);

% smooth ba
baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

% raster
[tr,b] = find(ba);
[rasterX, yy] = rasterize(bins(b));
rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
% scale the raster ticks
rasterScale = floor(numel(ev_times(1).times)/100);
rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;


subplot(2, 9, 3); hold on
shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.S});
xlim([-1 2])


subplot(2, 9,12); hold on
plot(rasterX, rasterY+max_y, 'Color',  ops.colors.S);
xlim([-1 2])

% 
% % U hit, fast
% if sum(U_hits & fast) > ops.minEventCount
%     [psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
%         psthAndBA(st , ev_times(3).times(U_hits & fast), ev_times(2).win + [-.2 .2], ops.spBinWidth/1000);
% 
%     % smooth ba
     baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
%     % raster
%     [tr,b] = find(ba);
%     [rasterX, yy] = rasterize(bins(b));
%     rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
%     % scale the raster ticks
%     rasterScale = floor(numel(ev_times(1).times)/100);
%     rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;
% 
% 
%     subplot(2, 9, 3);
%     shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.F_light});
%     xlim([-1 2])
% 
% 
%     subplot(2, 9,12); hold on
%     plot(rasterX, rasterY, 'Color',  ops.colors.F);
%     xlim([-1 2])
% 
% end
% 
% % U hit, slow
% if sum(U_hits & slow) > ops.minEventCount
%     [psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
%         psthAndBA(st , ev_times(3).times(U_hits & slow), ev_times(2).win + [-.2 .2], ops.spBinWidth/1000);
% 
%     % smooth ba
     baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
%     % raster
%     [tr,b] = find(ba);
%     [rasterX, yy] = rasterize(bins(b));
%     rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
%     % scale the raster ticks
%     rasterScale = floor(numel(ev_times(1).times)/100);
%     rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;
% 
% 
%     subplot(2, 9, 3); hold on
%     shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.S_light});
%     xlim([-1 2])
% 
% 
%     subplot(2, 9,12); hold on
%     plot(rasterX, rasterY, 'Color',  ops.colors.S);
%     xlim([-1 2])
% end
% 

%% Miss

% Miss
E_miss = strcmp(ev_times(3).classes(1,:), 'exp_miss');
U_miss = strcmp(ev_times(3).classes(1,:), 'uex_miss');

%E miss, fast
if sum(E_miss & fast) >  ops.minEventCount
[psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(3).times(E_miss & fast), ev_times(2).win + [-.2 .2], ops.spBinWidth/1000);

% smooth ba
baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

% raster
[tr,b] = find(ba);
[rasterX, yy] = rasterize(bins(b));
rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
% scale the raster ticks
rasterScale = floor(numel(ev_times(1).times)/100);
rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;


subplot(2, 9, 4);
shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.F});
xlim([-1 2])


subplot(2, 9,13); hold on
plot(rasterX, rasterY, 'Color',  ops.colors.F);
xlim([-1 2])
max_y = max(rasterY);
end

% E miss, slow
if  sum(E_miss & slow) > ops.minEventCount
[psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(3).times(E_miss & slow), ev_times(2).win + [-.2 .2], ops.spBinWidth/1000);

% smooth ba
baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

% raster
[tr,b] = find(ba);
[rasterX, yy] = rasterize(bins(b));
rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
% scale the raster ticks
rasterScale = floor(numel(ev_times(1).times)/100);
rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;

subplot(2, 9, 4); hold on
shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.S});
xlim([-1 2])

subplot(2, 9,13); hold on
plot(rasterX, rasterY+max_y, 'Color',  ops.colors.S);
xlim([-1 2])
end

% % U miss, fast
% if sum(U_miss & fast) >  ops.minEventCount
%     [psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
%         psthAndBA(st , ev_times(3).times(U_miss & fast), ev_times(2).win + [-.2 .2], ops.spBinWidth/1000);
% 
%     % smooth ba
     baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
%     % raster
%     [tr,b] = find(ba);
%     [rasterX, yy] = rasterize(bins(b));
%     rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
%     % scale the raster ticks
%     rasterScale = floor(numel(ev_times(1).times)/100);
%     rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;
% 
% 
%     subplot(2, 9, 4);
%     shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.F_light});
%     xlim([-1 2])
% 
% 
%     subplot(2, 9,13); hold on
%     plot(rasterX, rasterY, 'Color',  ops.colors.F);
%     xlim([-1 2])
%     max_y = max(rasterY);
% end
% 
% % U miss, slow
% if sum(U_miss & slow) > ops.minEventCount
%     [psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
%         psthAndBA(st , ev_times(3).times(U_miss & slow), ev_times(2).win + [-.2 .2], ops.spBinWidth/1000);
% 
%     % smooth ba
     baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
%     % raster
%     [tr,b] = find(ba);
%     [rasterX, yy] = rasterize(bins(b));
%     rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
%     % scale the raster ticks
%     rasterScale = floor(numel(ev_times(1).times)/100);
%     rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;
% 
% 
%     subplot(2, 9, 4); hold on
%     shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.S_light});
%     xlim([-1 2])
% 
% 
%     subplot(2, 9,13); hold on
%     plot(rasterX, rasterY+max_y, 'Color',  ops.colors.S);
%     xlim([-1 2])
% end


%% Lick

early = ev_times(4).classes < flip_time;
late  = ev_times(4).classes > flip_time;

% early
if sum(early) > ops.minEventCount
[psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(4).times(early), ev_times(4).win + [-.2 .2], ops.spBinWidth/1000);

% smooth ba
baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

% raster
[tr,b] = find(ba);
[rasterX, yy] = rasterize(bins(b));
rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
% scale the raster ticks
rasterScale = floor(numel(ev_times(1).times)/100);
rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;
    
subplot(2, 9, 5); hold on
shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.E});
xlim([-2 0])

subplot(2, 9,14); hold on
plot(rasterX, rasterY, 'color', ops.colors.E);
xlim([-2 0])
max_y = max(rasterY);
end

% late
if sum(late) > ops.minEventCount
[psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(4).times(late), ev_times(4).win + [-.2 .2], ops.spBinWidth/1000);

% smooth ba
baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

% raster
[tr,b] = find(ba);
[rasterX, yy] = rasterize(bins(b));
rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
% scale the raster ticks
rasterScale = floor(numel(ev_times(1).times)/100);
rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;
    
subplot(2, 9, 5);
shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.L});
xlim([-1 .5])


subplot(2, 9,14); hold on
plot(rasterX, rasterY+max_y, 'color', ops.colors.L);
xlim([-1 .5])
end

%% TF outlier, no lick
% PSTH smoothing filter
gw = gausswin(round((ops.spSmoothSize/ops.spBinWidth)*5),3);
% gw = gausswin(round(5*5),3);
smWin = gw./sum(gw);

signs = sign(ev_times(5).classes(1,:));
early = ev_times(5).classes(2,:) < flip_time;
late  = ev_times(5).classes(2,:) > flip_time;
licked = ev_times(5).classes(3,:) == 1;

% early, no lick
if sum(early & ~licked) > ops.minEventCount 

    % fast
    [psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(5).times(early & ~licked & signs==1), ev_times(5).win + [-.2 .2], ops.spBinWidth/1000);

    % smooth ba
    baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

    % raster
    [tr,b] = find(ba);
    [rasterX, yy] = rasterize(bins(b));
    rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
    % scale the raster ticks
    rasterScale = floor(numel(ev_times(1).times)/100);
    rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;

    subplot(2, 9, 6);
    mean_detrend = detrend_resp(nanmean(baSm,1), isbetween(bins, [-1 -.5]), isbetween(bins, [0.8 1.2]));
    shadedErrorBar(bins, mean_detrend, nanStdError(baSm,1), 'lineprops', {'color', ops.colors.F});
    % shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.F});
    xlim([-.5 1])

    subplot(2, 9, 15); hold on
    plot(rasterX, rasterY, 'color', ops.colors.F);
    xlim([-.5 1])
    max_y = max(rasterY);

    % slow
    [psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(5).times(early & ~licked & signs==-1), ev_times(5).win + [-.2 .2], ops.spBinWidth/1000);

    % smooth ba
     baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

    % raster
    [tr,b] = find(ba);
    [rasterX, yy] = rasterize(bins(b));
    rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
    % scale the raster ticks
    rasterScale = floor(numel(ev_times(1).times)/100);
    rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;

    subplot(2, 9, 6);
    
    mean_detrend = detrend_resp(nanmean(baSm,1), isbetween(bins, [-1 -.5]), isbetween(bins, [0.8 1.2]));
    shadedErrorBar(bins, mean_detrend, nanStdError(baSm,1), 'lineprops', {'color', ops.colors.S});
    % shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.S});
    xlim([-.5 1])

    subplot(2, 9, 15); hold on
    plot(rasterX, rasterY+max_y, 'color', ops.colors.S);
    xlim([-.5 1])
    
end

% late, no lick
if sum(late & ~licked) > ops.minEventCount 

    % fast
    [psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(5).times(late & ~licked & signs==1), ev_times(5).win + [-.2 .2], ops.spBinWidth/1000);

    % smooth ba
     baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

    % raster
    [tr,b] = find(ba);
    [rasterX, yy] = rasterize(bins(b));
    rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
    % scale the raster ticks
    rasterScale = floor(numel(ev_times(1).times)/100);
    rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;

    subplot(2, 9, 7);
    
    mean_detrend = detrend_resp(nanmean(baSm,1), isbetween(bins, [-1 -.5]), isbetween(bins, [0.8 1.2]));
    shadedErrorBar(bins, mean_detrend, nanStdError(baSm,1), 'lineprops', {'color', ops.colors.F});
    % shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.F});
    xlim([-.5 1])

    subplot(2, 9, 16); hold on
    plot(rasterX, rasterY, 'color', ops.colors.F);
    xlim([-.5 1])
    max_y = max(rasterY);

    % slow
    [psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(5).times(late & ~licked & signs==-1), ev_times(5).win + [-.2 .2], ops.spBinWidth/1000);

    % smooth ba
     baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

    % raster
    [tr,b] = find(ba);
    [rasterX, yy] = rasterize(bins(b));
    rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
    % scale the raster ticks
    rasterScale = floor(numel(ev_times(1).times)/100);
    rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;

    subplot(2, 9, 7);
    
    mean_detrend = detrend_resp(nanmean(baSm,1), isbetween(bins, [-1 -.5]), isbetween(bins, [0.8 1.2]));
    shadedErrorBar(bins, mean_detrend, nanStdError(baSm,1), 'lineprops', {'color', ops.colors.S});
    % shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.S});
    xlim([-.5 1])

    subplot(2, 9, 16); hold on
    plot(rasterX, rasterY+max_y, 'color', ops.colors.S);
    xlim([-.5 1])
    
end

%% TF outlier, lick
licked = ev_times(5).classes(3,:) == 1;

% early, lick
if sum(early & licked) > ops.minEventCount 

    % fast
    [psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(5).times(early & licked & signs==1), ev_times(5).win + [-.2 .2], ops.spBinWidth/1000);

    % smooth ba
     baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

    % raster
    [tr,b] = find(ba);
    [rasterX, yy] = rasterize(bins(b));
    rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
    % scale the raster ticks
    rasterScale = floor(numel(ev_times(1).times)/100);
    rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;

    subplot(2, 9, 8);
    shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.F});
    xlim([-1 2])

    subplot(2, 9, 17); hold on
    plot(rasterX, rasterY, 'color', ops.colors.F);
    xlim([-1 2])
    max_y = max(rasterY);

    % slow
    [psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(5).times(early & licked & signs==-1), ev_times(5).win + [-.2 .2], ops.spBinWidth/1000);

    % smooth ba
     baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

    % raster
    [tr,b] = find(ba);
    [rasterX, yy] = rasterize(bins(b));
    rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
    % scale the raster ticks
    rasterScale = floor(numel(ev_times(1).times)/100);
    rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;

    subplot(2, 9, 8);
    shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.S});
    xlim([-1 2])

    subplot(2, 9, 17); hold on
    plot(rasterX, rasterY+max_y, 'color', ops.colors.S);
    xlim([-1 2])
    
end

% late,  lick
if sum(late & licked) > ops.minEventCount 

    % fast
    [psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(5).times(late & licked & signs==1), ev_times(5).win + [-.2 .2], ops.spBinWidth/1000);

    % smooth ba
     baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

    % raster
    [tr,b] = find(ba);
    [rasterX, yy] = rasterize(bins(b));
    rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
    % scale the raster ticks
    rasterScale = floor(numel(ev_times(1).times)/100);
    rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;

    subplot(2, 9, 9);
    shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.F});
    xlim([-1 2])

    subplot(2, 9, 18); hold on
    plot(rasterX, rasterY, 'color', ops.colors.F);
    xlim([-1 2])
    max_y = max(rasterY);

    % slow
    [psth, bins, rasterX, rasterY, spikeCounts, ba] = ...
    psthAndBA(st , ev_times(5).times(late & licked & signs==-1), ev_times(5).win + [-.2 .2], ops.spBinWidth/1000);

    % smooth ba
     baSm = conv2(smWin,1,ba', 'same')'./(ops.spBinWidth/1000);
% baSm = smoothdata(ba, 2, 'movmean', smoothWin)./(ops.spBinWidth/1000);

    % raster
    [tr,b] = find(ba);
    [rasterX, yy] = rasterize(bins(b));
    rasterY = yy+reshape(repmat(tr',3,1),1,length(tr)*3); % yy is of the form [0 1 NaN 0 1 NaN...] so just need to add trial number to everything
    % scale the raster ticks
    rasterScale = floor(numel(ev_times(1).times)/100);
    rasterY(2:3:end) = rasterY(2:3:end)+rasterScale;

    subplot(2, 9, 9);
    shadedErrorBar(bins, nanmean(baSm,1), nanStdError(baSm,1), 'lineprops', {'color', ops.colors.S});
    xlim([-1 2])

    subplot(2, 9, 18); hold on
    plot(rasterX, rasterY+max_y, 'color', ops.colors.S);
    xlim([-1 2])
    
end
%%
subplot(2,9,1)
title('baseline onset')
subplot(2,9,2) 
title('baseline')
subplot(2,9,3)
title('hits')
subplot(2,9,4)
title('miss')
subplot(2,9,5)
title('early lick')
subplot(2,9,6)
title('TF outlier (early)')
subplot(2,9,7)
title('TF outlier (late)')
subplot(2,9,8)
title('TF outlier (early, licked)')
subplot(2,9,9)
title('TF outlier (late, licked)')

% align some y ax
% hit/miss/el
yls = [inf -inf];
for ii = [3 4 5]
    subplot(2,9,ii)
    yl = ylim;
    yls = [min([yls(1) yl(1)]), max([yls(2) yl(2)])];
end
for ii = [3 4 5]
    subplot(2,9,ii)
    ylim(yls)
end
% TF outliers
yls = [inf -inf];
for ii = [6 7]
    subplot(2,9,ii)
    yl = ylim;
    yls = [min([yls(1) yl(1)]), max([yls(2) yl(2)])];
end
for ii = [6 7]
    subplot(2,9,ii)
    ylim(yls)
end
% TF outliers (lick)
yls = [inf -inf];
for ii = [8 9]
    subplot(2,9,ii)
    yl = ylim;
    yls = [min([yls(1) yl(1)]), max([yls(2) yl(2)])];
end
for ii = [8 9]
    subplot(2,9,ii)
    ylim(yls)
end
% keyboard

end