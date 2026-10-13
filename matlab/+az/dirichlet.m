% SPDX-License-Identifier: AGPL-3.0-only
% Uncertified — research prototype, not for operational use.
% Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

function s = dirichlet(alpha, k, seed)
%AZ.DIRICHLET Dirichlet(alpha) sample of length K via Marsaglia-Tsang gamma.
rng(seed, 'twister');
g = zeros(k, 1);
for i = 1:k
    g(i) = gammaMT(alpha);
end
s = g / sum(g);
end

function x = gammaMT(a)
% Marsaglia-Tsang gamma sampler (shape A, scale 1).
if a < 1
    u = rand();
    x = gammaMT(a + 1) * u^(1/a);
    return
end
d = a - 1/3;
c = 1 / sqrt(9*d);
while true
    t = randn(); v = (1 + c*t)^3;
    if v <= 0, continue; end
    u = rand();
    if u < 1 - 0.0331 * t^4, x = d * v; return; end
    if log(u) < 0.5 * t^2 + d * (1 - v + log(v)), x = d * v; return; end
end
end
