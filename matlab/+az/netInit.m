% SPDX-License-Identifier: AGPL-3.0-only
% Uncertified — research prototype, not for operational use.
% Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

function P = netInit(D, A, H, seed)
%AZ.NETINIT Tiny MLP policy+value network: D -> H -> H -> (A logits, 1 value).
% He-style scaled-uniform init, deterministic under SEED.
rng(seed, 'twister');
P = struct();
P.W1 = (rand(H, D) - 0.5) * sqrt(12/(D+H)); P.b1 = zeros(H, 1);
P.W2 = (rand(H, H) - 0.5) * sqrt(12/(H+H)); P.b2 = zeros(H, 1);
P.Wp = (rand(A, H) - 0.5) * sqrt(12/H); P.bp = zeros(A, 1);
P.Wv = (rand(1, H) - 0.5) * sqrt(12/H); P.bv = 0;
P.D = D; P.A = A; P.H = H;
end
