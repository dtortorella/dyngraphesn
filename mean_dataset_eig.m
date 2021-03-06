% mean_dataset_eig.m
% Copyright (C) 2021, Domenico Tortorella
% Copyright (C) 2021, University of Pisa
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.

function eigMean = mean_dataset_eig(data)
%MEAN_DATASET_EIG Mean eigenvalue bound in dataset
%   Compute and average geometric mean of graph largest eigenvalue.
E = cellfun(@(A) max(abs(eig(A))), data.A, 'UniformOutput', true);
E(~(E>0)) = nan; % skip disconnected time-steps
eigMean = mean(geomean(E, 2, 'omitnan'));
end

