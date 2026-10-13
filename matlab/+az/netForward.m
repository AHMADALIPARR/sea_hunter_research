% SPDX-License-Identifier: AGPL-3.0-only
% Uncertified — research prototype, not for operational use.
% Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

function r = netForward(P, x)
%AZ.NETFORWARD Forward pass. Returns policy distribution P (softmax),
% value V (tanh, in [-1,1]), and hidden caches for backprop.
h1 = max(P.W1 * x + P.b1, 0); % ReLU
h2 = max(P.W2 * h1 + P.b2, 0); % ReLU
z = P.Wp * h2 + P.bp; % policy logits
z = z - max(z); % stable softmax
e = exp(z);
r.p = e / sum(e);
r.v = tanh(P.Wv * h2 + P.bv);
r.h1 = h1; r.h2 = h2;
end
