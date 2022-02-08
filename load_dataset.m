% load_dataset.m
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

function dataset = load_dataset(dataset_name, datasets_directory)
%LOAD_DATASET Load a temporal graph dataset
%   Parse and prepare datasets.

if nargin == 1
    datasets_directory = '.';
end

% parse dataset files
edges = readmatrix(sprintf('%s/%s/%s_A.txt', datasets_directory, dataset_name, dataset_name), delimitedTextImportOptions('DataLines',[1,Inf],'VariableTypes','double'));
edge_attributes = readmatrix(sprintf('%s/%s/%s_edge_attributes.txt', datasets_directory, dataset_name, dataset_name), delimitedTextImportOptions('DataLines',[1,Inf],'VariableTypes','double'));
graph_indicator = readmatrix(sprintf('%s/%s/%s_graph_indicator.txt', datasets_directory, dataset_name, dataset_name), delimitedTextImportOptions('DataLines',[1,Inf],'VariableTypes','double'));
graph_labels = readmatrix(sprintf('%s/%s/%s_graph_labels.txt', datasets_directory, dataset_name, dataset_name), delimitedTextImportOptions('DataLines',[1,Inf],'VariableTypes','double'));
node_labels = readmatrix(sprintf('%s/%s/%s_node_labels.txt', datasets_directory, dataset_name, dataset_name), delimitedTextImportOptions('DataLines',[1,Inf],'VariableTypes','double'));

% build adjacency and time matrices
timesteps = max(max(edge_attributes), max(node_labels(:,3))+1);
samples = max(graph_indicator);
A_all = cell(timesteps, 1);
nodes = size(node_labels, 1);
for t = 1:timesteps
    A_all{t} = sparse(edges(edge_attributes == t,1), edges(edge_attributes == t,2), 1, nodes, nodes);
end
N = 1:nodes;
Nt = ~isnan(node_labels(:,3));
u_all = sparse(node_labels(Nt,3)+1, N(Nt), 1, timesteps, length(node_labels));
u_all = cumsum(u_all);

% split dataset samples
dataset = struct();
dataset.A = cell(samples, timesteps);
dataset.u = cell(samples, timesteps);
for i = 1:samples
    for t = 1:timesteps
        dataset.A{i,t} = A_all{t}(graph_indicator==i,graph_indicator==i);
        dataset.u{i,t} = u_all(t,graph_indicator==i);
    end
end
dataset.y = 2 * graph_labels - 1;

end

