% SPDX-License-Identifier: AGPL-3.0-only
% Uncertified — research prototype, not for operational use.
% Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

function traj = selfplay(P, cfg, gameId)
%AZ.SELFPLAY One full self-play game using MCTS.
% Records (features, legal mask, search policy, mover) per ply; outcome
% z assigned per position from the final score, mover's perspective.
rng(cfg.seed + gameId, 'twister');
b = go.Board(cfg.N);
hist = {b};
A = cfg.N^2 + 1;
XS = []; PIS = []; MASKS = []; PERSP = [];
plies = 0;
while ~b.isTerminal() && plies < cfg.maxPlies
    pi = az.mcts(P, b, cfg);
    x = az.features(b, hist, cfg.hist);
    mask = false(A, 1);
    for a = 0:b.N*b.N - 1
        [tf, ~] = b.isLegal(a);
        if tf, mask(a+1) = true; end
    end
    mask(end) = true; % pass always legal
    XS(:, end+1) = x; PIS(:, end+1) = pi; %#ok<*AGROW>
    MASKS(:, end+1) = mask; PERSP(end+1) = b.toMove; %#ok<*AGROW>
    % temperature: sample early, argmax later
    if plies < cfg.tauPlies
        r = rand(); acc = 0; action = [];
        for ai = find(mask(:))'
            acc = acc + pi(ai);
            if r <= acc, action = ai; break; end
        end
        if isempty(action), [~, ai] = max(pi); action = ai; end
    else
        [~, action] = max(pi);
    end
    az.applyAction(b, action);
    hist = [{b}, hist(1:min(end, cfg.hist - 1))]; %#ok<*SAGROW>
    plies = plies + 1;
end
sc = b.score(cfg.komi); % black - white
Z = sign(sc) * (PERSP == 1) + (-sign(sc)) * (PERSP == 2);
traj = struct('xs', XS, 'pis', PIS, 'masks', MASKS, 'zs', Z, ...
              'plies', plies, 'outcome', sc, 'gameId', gameId);
end
