function eigMean = mean_dataset_eig(data)
%MEAN_DATASET_EIG Mean eigenvalue bound in dataset
%   Compute and average geometric mean of graph largest eigenvalue.
E = cellfun(@(A) max(abs(eig(A))), data.A, 'UniformOutput', true);
E(~(E>0)) = nan; % skip disconnected time-steps
eigMean = mean(geomean(E, 2, 'omitnan'));
end

