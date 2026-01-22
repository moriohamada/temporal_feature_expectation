function f = test_tf_rotation(dims_iters_aligned, ops)
% Test whether TF axes rotate
%%
nIter = length(dims_iters_aligned);
sims  = nan(3, 2, 2, nIter); % moves, F/S, expF/expS

moves = {'movement_potent', 'movement_null1', 'movement_null2'};
tfs = {'F', 'S'};
exp = {'expF', 'expS'};
for iter = 1:nIter
    for movei = 1:3
        for tfi = 1:2 % F/S
            for expi = 1:2 %expF/expS
                move_dim = dims_iters_aligned{iter}.(sprintf('%s', moves{movei}));
                tf_dim = dims_iters_aligned{iter}.(sprintf('tf_%s%s', tfs{tfi}, exp{expi}));
                sims(movei, tfi, expi, iter) = cosineSim(move_dim, tf_dim);
            end
        end
    end
end

% get differences between f and s
d_sim = squeeze(sims(:, 1, :, :) - sims(:, 2, :, :)); % leaves movedim x exp x iter
%%
f = figure('Units', 'normalized', 'OuterPosition', [.3 .1 .1 .16]);
pot_clrs  = flipud(cbrewer2('Greens', 2));
null_clrs = flipud(cbrewer2('Blues', 4));
cols = [pot_clrs(1,:); null_clrs(1, :); null_clrs(3,:)];
shps = {'s', 'o', '^'};
sz = [50, 30, 30];
alphas = [.1 .1 .2];
hold on
% keyboard
for movei = 1:3
    scatter(squeeze(d_sim(movei, 1, :)), squeeze(d_sim(movei, 2, :)), 20, shps{movei}, ...
            'markerfacecolor', cols(movei,:), 'markeredgealpha', 0, 'markerfacealpha', alphas(movei))
    % plot cis and averages
    mu1 = squeeze(median(d_sim(movei, 1, :),3));
    mu2 = squeeze(median(d_sim(movei, 2, :),3));   
    ci1 = prctile(squeeze(d_sim(movei, 1, :)), [2.5 97.5]);
    ci2 = prctile(squeeze(d_sim(movei, 2, :)), [2.5 97.5]);
    % diagonal ci
    ci_diag = prctile(squeeze(d_sim(movei, 1, :))-squeeze(d_sim(movei, 2, :)), [2.5 97.5]);
%     mu_d_diag = mean(squeeze(d_sim(movei, 1, :))-squeeze(d_sim(movei, 2, :)));
%     ci_diag = mu_d_diag + ci_diag;
    plot([mu1 mu1], ci2, '-k');
    plot(ci1, [mu2 mu2], '-k');
%     mu_along_eq = 
    plot(mu1+ci_diag/sqrt(2)-(mu1-mu2)/sqrt(2), mu2-ci_diag/sqrt(2)-(mu2-mu1)/sqrt(2), '-k')
    scatter(mu1, mu2, sz(movei), shps{movei}, 'markerfacecolor', cols(movei,:), 'markeredgealpha', 0)
end

xl = xlim; yl = ylim; maxlim = [min([xl, yl]) max([xl, yl])];
plot(maxlim, maxlim, '--k');
plot([0 0], yl, '-k');
plot(xl, [0 0], '-k');
xlim(xl); ylim(yl);
xticks([-.5:.5:.5]); yticks([-.5:.5:.5])
xlabel(sprintf('Alignment to TF dims \n(F - S; exp fast change)'))
ylabel(sprintf('Alignment to TF dims \n(F - S; exp slow change)'))
end