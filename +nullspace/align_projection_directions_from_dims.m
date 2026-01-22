function [projs_iters_aligned, dim_iters_aligned] = align_projection_directions_from_dims(projs_iters, dims_iters)
% align movement potent, null dims to go up around fast licks

nIter = length(projs_iters);

dim_names  = fields(projs_iters{1});
resp_names = fields(projs_iters{1}.(dim_names{1}));
projs_iters_aligned = projs_iters;
dim_iters_aligned   = dims_iters;
move_dims = {'movement_potent', 'movement_null1', 'movement_null2', ...
             'movement_potent_shuffled', 'movement_null1_shuffled', 'movement_null2_shuffled'};

for iter = 1:nIter    
    
    for md = length(move_dims):-1:1
        move_dim = move_dims{md};
        
        if md == 1 | md == 4
            alignment = sign(mean(projs_iters{iter}.movement_potent.hitLickE7(200:250)));
        elseif md == 2 | md == 5
            F = sign(mean(projs_iters{iter}.movement_null1.hitLickE7(175:225)));
            S = sign(mean(projs_iters{iter}.movement_null1.hitLickE1(175:225)));
            
            if sign(F)~=sign(S)
                continue
            end
            
            alignment = sign(F);
        elseif md == 3 | md == 6
            F = mean(projs_iters{iter}.movement_null2.hitLickE7(175:225));
            S = mean(projs_iters{iter}.movement_null2.hitLickE1(175:225));
%             if sign(F) == sign(S)
%                 projs_iters_aligned{iter}=[];
%                 dim_iters_aligned{iter}=[];
%                 break
%             else
                alignment = sign(F-S);
                if alignment==0
                    keyboard
                end
%                 alignment = sign(corr(dims_iters{iter}.(move_dim), dims_iters{iter}.tf_fast - dims_iters{iter}.tf_slow));
%             end
        end
        
        for r = 1:length(resp_names)
            resp_name = resp_names{r};
            projs_iters_aligned{iter}.(move_dim).(resp_name) = ...
                projs_iters{iter}.(move_dim).(resp_name) * alignment;
        end
        dim_iters_aligned{iter}.(move_dim) = dims_iters{iter}.(move_dim)*alignment;
    end
    
%     all_dims = fields(dim_iters_aligned{iter});
%     for d = 1:numel(all_dims)
%         dim_name = all_dims{d};
%         dim_iters_aligned{iter}.(dim_name) = dim_iters_aligned{iter}.(dim_name)/norm(dim_iters_aligned{iter}.(dim_name));
%     end
    
%     if ~isempty(dim_iters_aligned{iter})
%         dim_iters_aligned{iter}.tf_fast = dims_iters{iter}.tf_fast;
%         dim_iters_aligned{iter}.tf_slow = dims_iters{iter}.tf_slow;
%         dim_iters_aligned{iter}.tf_none = dims_iters{iter}.tf_none;
%     end
end 

end






