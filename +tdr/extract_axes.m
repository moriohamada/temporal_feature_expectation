function axes = extract_NxT_axes(indexes, resps, kernels, tf_selection, lick_selection)

axes.fast   = kernels{:,'TFbl'};
axes.fast   = (indexes.tf_short>0 & tf_selection) .* axes.fast;
axes.fast   = axes.fast(:,2:20);

axes.slow   = kernels{:,'TFbl'};
axes.slow   = (indexes.tf_short<0 & tf_selection) .* axes.slow*-1;
axes.slow   = axes.slow(:,2:20);

axes.lick = kernels{:,'PreLick'};
axes.lick = lick_selection .* axes.lick;
axes.lick = axes.lick(:,5:end-1);

end