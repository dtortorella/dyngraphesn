% DynGraphESN.m
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

classdef DynGraphESN < handle
    %DYNGRAPHESN Dynamic GraphESN
    %   A multi-layer echo state network for dynamic time graphs
    
    properties
        inputDim     % input dimension
        targetDim    % output target dimension
        hiddenUnits  % hidden units in all layers
        numLayers    % number of layers
        embedDim     % embedding random projection size (optional)
        Wi    % input weights
        Wh    % recurrent weighs
        Wphi  % random projection weights (optional)
        Wy    % readout weights
        a     % leakage constant
        skipDisconnected % whether to skip fully disconnected timesteps
    end
    
    methods
        function self = DynGraphESN(inputDim, targetDim, hiddenUnits, numLayers, embedDim)
            %DYNGRAPHESN Construct an instance of this class
            %  Reservoir configuration parameters are:
            % - inputDim: input dimension
            % - targetDim: output target dimension
            % - hiddenUnits: hidden units in all layers
            % - numLayers: number of layers
            % - embedDim: embedding random projection size (optional)
            self.inputDim = inputDim;
            self.targetDim = targetDim;
            self.hiddenUnits = hiddenUnits;
            self.numLayers = numLayers;
            self.embedDim = embedDim;
            self.Wi = cell(numLayers, 1);
            self.Wh = cell(numLayers, 1);
            self.a = 1;
            self.skipDisconnected = true;
        end
        
        function init(self, sigma, maxEigenvalue, inputScaling, interScaling, leakageConst, randomFun)
            %INIT Initialize reservoir with random weights
            %  New random weights are produced according to reservoir parameters and the inputs:
            % - sigma: spectral norm (normalized w.r.t. maxEigenvalue)
            % - maxEigenvalue: maximum eigenvalue of input graphs
            % - inputScaling: scale factor for input
            % - interScaling: scale factor for inter-layer input
            % - leakageConst: leakage constant
            % - randomFun: random function that generates matrices
            self.a = leakageConst;
            self.Wi{1} = inputScaling * randomFun(self.hiddenUnits, self.inputDim);
            self.Wh{1} = randomFun(self.hiddenUnits, self.hiddenUnits);
            self.Wh{1} = self.Wh{1} * sigma / maxEigenvalue / norm(self.Wh{1});
            for i = 2:self.numLayers
                self.Wi{i} = interScaling * randomFun(self.hiddenUnits, self.hiddenUnits);
                self.Wh{i} = randomFun(self.hiddenUnits, self.hiddenUnits);
                self.Wh{i} = self.Wh{i} * sigma / maxEigenvalue / norm(self.Wh{i});
            end
            if ~isempty(self.embedDim)
                self.Wphi = randomFun(self.hiddenUnits*self.numLayers, self.embedDim);
            else
                self.Wphi = [];
            end
        end
        
        function X = embed_vertices(self, A, u)
            %EMBED_VERTICES Encode a dynamic temporal graph's vertices into vectors
            %  A dynamic temporal graph must be provided by:
            % - A: cell list of adjacency matrices for each time-step
            % - u: cell list of input matrices inputDim × #vertices for each time-step
            T = length(A); % time-steps
            N = size(A{1}, 1); % vertices
            X = cell(self.numLayers, 1); % state for each layer
            [X{:}] = deal(zeros(self.hiddenUnits,N)); % initial null state
            if ~isnan(self.a)
                for t = 1:T
                    if self.skipDisconnected && nnz(A{t}) == 0
                        continue;
                    end
                    X{1} = self.a * tanh(self.Wi{1}*u{t} + self.Wh{1}*X{1}*A{t}) + (1-self.a) * X{1};
                    for i = 2:self.numLayers
                        X{i} = self.a * tanh(self.Wi{i}*X{i-1} + self.Wh{i}*X{i}*A{t}) + (1-self.a) * X{i};
                    end
                end
            else
                for t = 1:T
                    if self.skipDisconnected && nnz(A{t}) == 0
                        continue;
                    end
                    connected = full(sum(A{t}, 1) > 0);
                    X{1} = connected .* tanh(self.Wi{1}*u{t} + self.Wh{1}*X{1}*A{t}) + (~connected) .* X{1};
                    for i = 2:self.numLayers
                        X{i} = connected .* tanh(self.Wi{i}*X{i-1} + self.Wh{i}*X{i}*A{t}) + (~connected) .* X{i};
                    end
                end
            end
            X = cat(1, X{:});
        end
        
        function Xg = embed_graph(self, A, u)
            %EMBED_GRAPH Encode a dynamic temporal graph into a vector
            %  A dynamic temporal graph must be provided by:
            % - A: cell list of adjacency matrices for each time-step
            % - u: cell list of input matrices inputDim × #vertices for each time-step
            T = length(A); % time-steps
            N = size(A{1}, 1); % vertices
            X = cell(self.numLayers, 1); % state for each layer
            [X{:}] = deal(zeros(self.hiddenUnits,N)); % initial null state
            if ~isnan(self.a)
                for t = 1:T
                    if self.skipDisconnected && nnz(A{t}) == 0
                        continue;
                    end
                    X{1} = self.a * tanh(self.Wi{1}*u{t} + self.Wh{1}*X{1}*A{t}) + (1-self.a) * X{1};
                    for i = 2:self.numLayers
                        X{i} = self.a * tanh(self.Wi{i}*X{i-1} + self.Wh{i}*X{i}*A{t}) + (1-self.a) * X{i};
                    end
                end
            else
                for t = 1:T
                    if self.skipDisconnected && nnz(A{t}) == 0
                        continue;
                    end
                    connected = full(sum(A{t}, 1) > 0);
                    X{1} = connected .* tanh(self.Wi{1}*u{t} + self.Wh{1}*X{1}*A{t}) + (~connected) .* X{1};
                    for i = 2:self.numLayers
                        X{i} = connected .* tanh(self.Wi{i}*X{i-1} + self.Wh{i}*X{i}*A{t}) + (~connected) .* X{i};
                    end
                end
            end
            Xg = cellfun(@(x) sum(x, 2), X, 'UniformOutput', false); % graph pooling
            Xg = cat(1, Xg{:});
            if ~isempty(self.Wphi)
                Xg = tanh(self.Wphi * Xg); % project graph embedding
            end
        end
        
        function fit(self, X, y, regularization)
            %FIT Train readout by MSE minimization
            %  Input data must be provided as:
            % - X: samples on rows
            % - y: targets on rows
            % - regularization: Tychonoff lambda (optional)
            Z = [X ones(size(X,1),1)];
            if isempty(regularization)
                self.Wy = Z \ y;
            else
                [U, S, V] = svd(Z, 'econ');
                s = diag(S);
                self.Wy = V * ((U' * y) .* (s ./ (s.^2 + regularization.^2)));
            end
        end
        
        function fit_linear_svm(self, X, y, C)
            %FIT_LINEAR_SVM Train readout by linear SVM
            %  Input data must be provided as:
            % - X: samples on rows
            % - y: targets on rows
            % - C: slack
            svm = fitclinear(X, y, 'Lambda', C);
            self.Wy = [svm.Beta; svm.Bias];
        end
        
        function y = predict(self, A, u)
            %PREDICT Predicts target for a dynamic temporal graph
            %  A dynamic temporal graph must be provided by:
            % - A: cell list of adjacency matrices for each time-step
            % - u: cell list of input matrices inputDim × #vertices for each time-step
            Xg = self.embed_graph(A, u);
            y = [Xg' 1] * self.Wy;
        end
        
        function train(self, AA, uu, y, regularization)
            %TRAIN Train reservoir on dataset
            %  Training data must be provided by cell matrices (samples × timesteps) for:
            % - AA: adjacency matrices for each time-step
            % - uu: input matrices inputDim × #vertices for each time-step
            % - y: targets on rows
            % - regularization: Tychonoff lambda (optional)
            samples = size(AA, 1);
            X = cell(samples, 1);
            for i = 1:samples
                X{i} = self.embed_graph(AA(i,:), uu(i,:))';
            end
            self.fit(cat(1, X{:}), y, regularization);
        end
        
        function train_linear_svm(self, AA, uu, y, C)
            %TRAIN_LINEAR_SVM Train reservoir on dataset
            %  Training data must be provided by cell matrices (samples × timesteps) for:
            % - AA: adjacency matrices for each time-step
            % - uu: input matrices inputDim × #vertices for each time-step
            % - y: targets on rows
            % - C: slack
            samples = size(AA, 1);
            X = cell(samples, 1);
            for i = 1:samples
                X{i} = self.embed_graph(AA(i,:), uu(i,:))';
            end
            self.fit_linear_svm(cat(1, X{:}), y, C);
        end
        
        function acc = test_accuracy(self, AA, uu, y)
            %TEST_ACCURACY Evaluate accuracy on dataset
            %  Test data must be provided by cell matrices (samples × timesteps) for:
            % - AA: adjacency matrices for each time-step
            % - uu: input matrices inputDim × #vertices for each time-step
            % - y: targets on rows
            samples = size(AA, 1);
            yPred = zeros(samples, self.targetDim);
            for i = 1:samples
                yPred(i,:) = self.predict(AA(i,:), uu(i,:));
            end
            if self.targetDim == 1
                acc = mean(sign(yPred) == y);
            end
        end
    end
end

