% experiments.m
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

% Bootstrap experiments for different networks
datasets = {'dblp_ct1', 'facebook_ct1', 'highschool_ct1', 'infectious_ct1', 'mit_ct1', 'tumblr_ct1', 'dblp_ct2', 'facebook_ct2', 'highschool_ct2', 'infectious_ct2', 'mit_ct2', 'tumblr_ct2'};
H = [1 2 4 8 16];
L = [1 2 3 4 5 6];
leakage = .1;
sigma = .9;
lambda = 1e-3;
trials = 200;
ratio = .9;
Acc = zeros(length(datasets), length(L), length(H), trials);
rng(123); % reproducibility
for i = 1:12
    tic;
    fprintf('%s\t000', datasets{i});
    data = load_dataset(datasets{i}, 'datasets');
    samples = length(data.y);
    split = floor(samples * ratio);
    maxEig = mean_dataset_eig(data);
    for k = 1:trials
        p = randperm(samples);
        for l = 1:length(L)
            for h = 1:length(H)
                esn = DynGraphESN(1, 1, H(h), L(l), []);
                esn.init(sigma, maxEig, 1, 1, leakage, @rand);
                esn.train(data.A(p(1:split),:), data.u(p(1:split),:), data.y(p(1:split),:), lambda);
                Acc(i,l,h,k) = esn.test_accuracy(data.A(p(split+1:end),:), data.u(p(split+1:end),:), data.y(p(split+1:end),:));
            end
        end
        fprintf('\b\b\b%03d', k);
    end
    fprintf('\b\b\b%f sec\n', toc);
    save experiments.mat Acc datasets H L leakage sigma lambda trials
end
