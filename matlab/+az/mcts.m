% SPDX-License-Identifier: AGPL-3.0-only
% Uncertified — research prototype, not for operational use.
% Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

function pi = mcts(P, root, cfg)
%AZ.MCTS Full AlphaZero-style search: PUCT selection, NN leaf evaluation,
% sign-correct value backup, root Dirichlet noise (self-play only).
% Returns visit-count policy pi over all A = N^2 + 1 actions.
N = root.N; A = N*N + 1;
legal = rootLegal(root);
r = netForward(P, features(root, {root}, cfg.hist));
prior = zeros(A, 1); prior(legal) = max(r.p(legal), 0);
s = sum(prior); if s > 0, prior = prior / s; else, prior(legal) = 1/numel(legal); end
if isfield(cfg, 'noise') && cfg.noise && numel(legal) > 1
    nz = dirichlet(cfg.noiseAlpha, numel(legal), cfg.seed + numel(legal));
    prior(legal) = (1 - cfg.noiseEps) * prior(legal) + cfg.noiseEps * nz;
end
nodes = cell(0);
rootNode = mkNode(root, P, cfg);
nodes{end+1} = rootNode; %#ok<*AGROW>
rootId = 1;
for sim = 1:cfg.sims
    path = [];
    curId = rootId; val = [];
    while true
        cur = nodes{curId};
        if isempty(cur.legal)
            val = termValue(cur.g, cfg);
            break
        end
        nsum = sum(cur.N);
        Q = zeros(size(cur.N));
        nz = cur.N > 0; Q(nz) = cur.W(nz) ./ cur.N(nz);
        U = cfg.cpuct * cur.P .* sqrt(max(nsum, 1)) ./ (1 + cur.N);
        sc = Q + U; sc(cur.P == 0) = -Inf;
        [~, ai] = max(sc);
        a = cur.legal(ai);
        ch = cur.child(ai);
        if ch == 0
            g2 = cloneGo(cur.g); applyAction(g2, a);
            if g2.passes >= 2
                val = termValue(g2, cfg);
            else
                n2 = mkNode(g2, P, cfg);
                nodes{end+1} = n2;
                cur.child(ai) = numel(nodes);
                nodes{curId} = cur;
                val = netForward(P, features(g2, {g2}, cfg.hist)).v;
            end
            path(end+1, :) = [curId, ai]; %#ok<*AGROW>
            v = -val;
            for i = size(path, 1):-1:1
                nd = nodes{path(i,1)}; ai2 = path(i,2);
                nd.N(ai2) = nd.N(ai2) + 1;
                nd.W(ai2) = nd.W(ai2) + v;
                nodes{path(i,1)} = nd;
                v = -v;
            end
            val = [];
            break
        end
        path(end+1, :) = [curId, ai]; %#ok<*AGROW>
        curId = ch;
    end
    if ~isempty(val)
        v = val;
        for i = size(path, 1):-1:1
            nd = nodes{path(i,1)}; ai2 = path(i,2);
            nd.N(ai2) = nd.N(ai2) + 1;
            nd.W(ai2) = nd.W(ai2) + v;
            nodes{path(i,1)} = nd;
            v = -v;
        end
    end
end
pi = zeros(A, 1);
rn = nodes{rootId};
tot = sum(rn.N);
if tot > 0, pi(rn.legal) = rn.N / tot; else, pi(rn.legal) = 1/numel(rn.legal); end
end

function n = mkNode(g, P, cfg)
A = g.N^2 + 1;
legal = rootLegal(g);
r = netForward(P, features(g, {g}, cfg.hist));
Pr = zeros(A, 1); Pr(legal) = max(r.p(legal), 0);
s = sum(Pr); if s > 0, Pr = Pr / s; else, Pr(legal) = 1/numel(legal); end
n = struct('g', g, 'legal', legal, 'P', Pr, ...
           'N', zeros(A, 1), 'W', zeros(A, 1), 'child', zeros(numel(legal), 1));
end

function legal = rootLegal(g)
legal = [];
for a = 0:g.N*g.N - 1
    [tf, ~] = g.isLegal(a);
    if tf, legal(end+1) = a + 1; end %#ok<*AGROW>
end
legal(end+1) = g.N*g.N + 1; % pass
end

function g2 = cloneGo(g)
g2 = go.Board(g.N);
g2.board = g.board; g2.toMove = g.toMove; g2.koPoint = g.koPoint;
g2.passes = g.passes; g2.capturedByBlack = g.capturedByBlack;
g2.capturedByWhite = g.capturedByWhite;
end

function v = termValue(g, cfg)
s = g.score(cfg.komi);
if g.toMove == 1, v = sign(s); else, v = -sign(s); end
end
