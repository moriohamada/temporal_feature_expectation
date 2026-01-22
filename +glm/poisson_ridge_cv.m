function [beta, dev, lambda_best] = poisson_ridge_cv(X, y, lambdas, n_folds)

    if nargin < 3, lambdas = logspace(-2, 6, 10); end
    if nargin < 4, n_folds = 5; end  

    fprintf('Fitting CV (%d-fold) ridge models for %d lambdas\n', n_folds, length(lambdas))
    
    % Keep sparse if possible
    if ~issparse(X)
        X = sparse(X);
    end
    y = full(y(:));
    
    [n, p] = size(X);
    cv = cvpartition(n, 'KFold', n_folds);
    
    % Pre-extract indices
    train_idx = cell(n_folds, 1);
    test_idx = cell(n_folds, 1);
    for fold = 1:n_folds
        train_idx{fold} = training(cv, fold);
        test_idx{fold} = test(cv, fold);
    end
    
    n_lambdas = length(lambdas);
    dev = zeros(n_lambdas, n_folds);
    
    % Precompute identity matrix (sparse)
    Ip = speye(p);
    
    parfor fold = 1:n_folds
        fprintf('Fold %d/%d\n', fold, n_folds);
        X_train = X(train_idx{fold}, :);
        y_train = y(train_idx{fold});
        X_test = X(test_idx{fold}, :);
        y_test = y(test_idx{fold});
        
        fold_dev = zeros(n_lambdas, 1);
        
        % Warm start: use previous lambda's solution as starting point
        beta_warm = zeros(p, 1);
        
        for li = n_lambdas:-1:1 % reverse order so beta is brought away from zero relative to beta warm
            [beta_fold, beta_warm] = poisson_ridge_fit(X_train, y_train, lambdas(li), Ip, beta_warm, 50, 1e-4);
            mu = exp(X_test * beta_fold);
            fold_dev(li) = 2 * sum(y_test .* log((y_test + 1e-10) ./ (mu + 1e-10)) - (y_test - mu));
        end
        dev(:, fold) = fold_dev;
    end
    
    mean_dev = mean(dev, 2);
    [~, best_idx] = min(mean_dev);
    lambda_best = lambdas(best_idx);
    
    % Final fit
    beta = poisson_ridge_fit(X, y, lambda_best, Ip, zeros(p,1), 100, 1e-5);
    
    figure;
    errorbar(log10(lambdas), mean_dev, std(dev, [], 2) / sqrt(n_folds));
    xlabel('log10(Lambda)'); ylabel('Deviance');
    xline(log10(lambda_best), 'r--');
    title('Poisson Ridge CV');
end

function [beta, beta_out] = poisson_ridge_fit(X, y, lambda, Ip, beta_init, max_iter, tol)
    if nargin < 6, max_iter = 100; end
    if nargin < 7, tol = 1e-5; end
    
    [~, p] = size(X);
    beta = beta_init;
    
    for iter = 1:max_iter
        eta = X * beta;
        
        % Clamp eta to prevent overflow
        eta = min(max(eta, -20), 20);
        mu = exp(eta);
        
        % IRLS
        W = mu;
        z = eta + (y - mu) ./ mu;
        
        % Use sparse operations
        XtW = X' * spdiags(W, 0, length(W), length(W));
        H = XtW * X + lambda * Ip;
        g = XtW * z;
        
        % Use conjugate gradient for large systems (faster than backslash)
        [beta_new, ~] = pcg(H, g, 1e-6, 100, [], [], beta);
        
        if norm(beta_new - beta) / (norm(beta) + 1e-10) < tol
            break;
        end
        beta = beta_new;
    end
    beta = beta_new;
    beta_out = beta;  % for warm start
end