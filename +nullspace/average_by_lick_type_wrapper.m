function combinedOutput = average_by_lick_type_wrapper(n, m, l, t_ax, cats)
    
    [N_avgs, M_avgs] = average_by_lick_type(n,m,l,t_ax, cats);
    combinedOutput = {N_avgs, M_avgs};

end

function [N_avg, M_avg] = average_by_lick_type(n, m, l, t_ax, cats)
    if isempty(n)
        N_avg = [];
        M_avg = [];
        return
    end
    
    n = smoothdata(n, 3, 'movmean', 3);
    m = smoothdata(m, 3, 'movmean', 3);
    
    switch cats
        case 'TFval'
            % By TF value
            N_avg  = cat(2, squeeze(nanmean(n(:,l.dir==-1.75 & strcmp(l.type, 'Hit'),:),2)), ...
                            squeeze(nanmean(n(:,l.dir==-1 & strcmp(l.type, 'Hit'),:),2)), ...
                            squeeze(nanmean(n(:,l.dir==-.5 & strcmp(l.type, 'Hit'),:),2)), ...
                            squeeze(nanmean(n(:,l.dir==.5 & strcmp(l.type, 'Hit'),:),2)), ...
                            squeeze(nanmean(n(:,l.dir==1 & strcmp(l.type, 'Hit'),:),2)), ...
                            squeeze(nanmean(n(:,l.dir==1.75 & strcmp(l.type, 'Hit'),:),2)), ...
                            squeeze(nanmean(n(:,l.dir==1 & strcmp(l.type, 'FA'),:),2)), ...
                            squeeze(nanmean(n(:,l.dir==-1 & strcmp(l.type, 'FA'),:),2)));

            M_avg  = cat(2, squeeze(nanmean(m(:,l.dir==-1.75 & strcmp(l.type, 'Hit'),:),2)), ...
                            squeeze(nanmean(m(:,l.dir==-1 & strcmp(l.type, 'Hit'),:),2)), ...
                            squeeze(nanmean(m(:,l.dir==-.5 & strcmp(l.type, 'Hit'),:),2)), ...
                            squeeze(nanmean(m(:,l.dir==.5 & strcmp(l.type, 'Hit'),:),2)), ...
                            squeeze(nanmean(m(:,l.dir==1 & strcmp(l.type, 'Hit'),:),2)), ...
                            squeeze(nanmean(m(:,l.dir==1.75 & strcmp(l.type, 'Hit'),:),2)), ...
                            squeeze(nanmean(m(:,l.dir==1 & strcmp(l.type, 'FA'),:),2)), ...
                            squeeze(nanmean(m(:,l.dir==-1 & strcmp(l.type, 'FA'),:),2)));
        case 'dir'
            % By direction only
            N_avg  = cat(2, squeeze(nanmean(n(:,l.dir<0 & strcmp(l.type, 'Hit'),:),2)), ...
                squeeze(nanmean(n(:,l.dir>0 & strcmp(l.type, 'Hit'),:),2)));
            
            M_avg  = cat(2, squeeze(nanmean(m(:,l.dir<0 & strcmp(l.type, 'Hit'),:),2)), ...
                squeeze(nanmean(m(:,l.dir>0 & strcmp(l.type, 'Hit'),:),2)));
    end
    
    % remove all nan rows
    N_avg(~any(~isnan(N_avg), 2),:) = [];
    M_avg(~any(~isnan(M_avg), 2),:) = [];
    
    % subtract average activity between -2 and -1.5 s
    nrep = size(N_avg,2)/length(t_ax);
    tax_repeated = repmat(t_ax, 1, nrep);
    t_bl = tax_repeated > -1.99 & tax_repeated < -1.5;
    
    N_avg = (N_avg - nanmean(N_avg(:,t_bl),2));
    M_avg = (M_avg - nanmean(M_avg(:,t_bl),2));
    
end