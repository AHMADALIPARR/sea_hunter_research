% SPDX-License-Identifier: AGPL-3.0-only
% Uncertified — research prototype, not for operational use.
% Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab
% Extracted from dumps into proper functions.

function nb = neighborsOf(N, idx)
%NEIGHBORSOF Linear neighbor indices of IDX (1-based, column-major):
% idx = i + (j-1)*N, so up/down (row) are -1/+1, left/right (col) are -N/+N.
    [i, j] = ind2sub([N N], idx);
    nb = [];
    if i > 1, nb(end+1) = idx - 1; end %#ok<*AGROW> % up
    if i < N, nb(end+1) = idx + 1; end %#ok<*AGROW> % down
    if j > 1, nb(end+1) = idx - N; end %#ok<*AGROW> % left
    if j < N, nb(end+1) = idx + N; end %#ok<*AGROW> % right
end

function r = simulate(obj, idx)
%SIMULATE Stone at IDX (1-based). Order matters: place the stone FIRST, then
% capture adjacent opponent groups, then check own liberties.
% Returns struct with .suicide, .board, .koPoint, etc.
    me = obj.toMove; opp = 3 - me;
    b = obj.board;
    b(idx) = me; % <-- placed before capture scan
    cap = 0; capIdx = 0;
    nbs = neighborsOf(obj.N, idx);
    for k = 1:numel(nbs)
        nb = nbs(k);
        if b(nb) == opp
            [grp, libs] = groupOf(b, obj.N, nb); % assume groupOf exists or implement
            if libs == 0
                b(grp) = 0;
                cap = cap + numel(grp);
                if numel(grp) == 1, capIdx = grp(1); end
            end
        end
    end
    [~, ownLibs] = groupOf(b, obj.N, idx);
    r.suicide = (cap == 0 && ownLibs == 0);
    r.board = b;
    r.koPoint = 0;
    if cap == 1 && ownLibs == 1
        [ownGrp, ~] = groupOf(b, obj.N, idx);
        if numel(ownGrp) == 1, r.koPoint = capIdx; end
    end
    % ... additional return fields as needed
end

function [grp, libs] = groupOf(b, N, start)
%GROUPOf Helper: find connected group and liberty count (stub for extraction).
% Full implementation required for production use.
    grp = start; % placeholder — expand with flood fill
    libs = 1;    % placeholder
end
