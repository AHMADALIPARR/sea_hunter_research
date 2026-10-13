% SPDX-License-Identifier: AGPL-3.0-only
% Uncertified — research prototype, not for operational use.
% Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

function x = features(b, hist, histLen)
%AZ.FEATURES Feature planes from the mover's perspective.
% B: go.Board, HIST: cell array of past boards (newest first, including
% current position), HISTLEN: history depth. Returns a (2*histLen+1)*A
% column vector: per historical position [own stones, opponent stones],
% then one color-to-move plane (1 = black to move, 0 = white).
A = b.N * b.N;
D = 2 * histLen + 1;
x = zeros(D * A, 1);
me = b.toMove; opp = 3 - me;
for t = 0:histLen-1
    if t < numel(hist)
        g = hist{t+1};
        own = double(g.board(:) == me);
        en = double(g.board(:) == opp);
    else
        own = zeros(A, 1); en = zeros(A, 1);
    end
    x((2*t)*A + (1:A)) = own;
    x((2*t+1)*A + (1:A)) = en;
end
x(2*histLen*A + (1:A)) = (me == 1); % color to move
end
