function proj = project_resps(axes, resps, ax_names)

resp_fields = fields(resps);

for ax_i = 1:length(ax_names)
    ax_name = ax_names{ax_i};
    ax = axes.(ax_name);
    nN = size(ax,1);
    for f = 1:length(resp_fields)-3 % last three are table properties
        x = resps{:, resp_fields{f}};
        
        if size(x,1)==nN & strcmp(class(x), 'double') & ~contains(resp_fields{f}, 'FR')
            x = (x - resps.FRmu)./resps.FRsd;
            x(isnan(x))=0;
            x(isinf(x))=0;
            proj.(ax_name).(resp_fields{f}) = ax' * x;
        end
    end
end