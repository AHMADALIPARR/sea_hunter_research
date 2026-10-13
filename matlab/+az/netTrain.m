% SPDX-License-Identifier: AGPL-3.0-only
% Uncertified — research prototype, not for operational use.
% Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

function [P, lossHist] = netTrain(P, data, epochs, lr, l2)
%AZ.NETTRAIN Minibatch SGD with manual backprop.
% Loss = mean CE(policy, pi_target) + mean (v - z)^2 + L2 on weights.
% DATA: struct with columns xs (D x M), pis (A x M), zs (1 x M).
M = size(data.xs, 2);
lossHist = zeros(epochs, 1);
for ep = 1:epochs
    g = gradEmpty(P);
    totLoss = 0;
    for m = 1:M
        x = data.xs(:, m); piT = data.pis(:, m); zT = data.zs(m);
        r = netForward(P, x);
        totLoss = totLoss ...
            + (-sum(piT .* log(max(r.p, 1e-12)))) ...
            + (r.v - zT)^2;
        % ---- backprop ----
        dv = 2 * (r.v - zT); % d MSE
        dp = r.p - piT; % d(CE + softmax)
        g.Wv = g.Wv + dv * r.h2'; g.bv = g.bv + dv;
        g.Wp = g.Wp + dp * r.h2'; g.bp = g.bp + dp;
        dh2 = P.Wp' * dp + P.Wv' * dv;
        dh2 = dh2 .* (r.h2 > 0);
        g.W2 = g.W2 + dh2 * r.h1'; g.b2 = g.b2 + dh2;
        dh1 = P.W2' * dh2;
        dh1 = dh1 .* (r.h1 > 0);
        g.W1 = g.W1 + dh1 * x'; g.b1 = g.b1 + dh1;
    end
    % L2 gradient + parameter update
    for w = {'W1','W2','Wp','Wv'}
        g.(w{1}) = (g.(w{1}) + l2 * P.(w{1})) / M;
    end
    for w = {'b1','b2','bp','bv'}
        g.(w{1}) = g.(w{1}) / M;
    end
    P.W1 = P.W1 - lr * g.W1; P.b1 = P.b1 - lr * g.b1;
    P.W2 = P.W2 - lr * g.W2; P.b2 = P.b2 - lr * g.b2;
    P.Wp = P.Wp - lr * g.Wp; P.bp = P.bp - lr * g.bp;
    P.Wv = P.Wv - lr * g.Wv; P.bv = P.bv - lr * g.bv;
    lossHist(ep) = totLoss / M;
end
end

function g = gradEmpty(P)
g = struct('W1', zeros(size(P.W1)), 'b1', zeros(size(P.b1)), ...
           'W2', zeros(size(P.W2)), 'b2', zeros(size(P.b2)), ...
           'Wp', zeros(size(P.Wp)), 'bp', zeros(size(P.bp)), ...
           'Wv', zeros(size(P.Wv)), 'bv', 0);
end
