% SPDX-License-Identifier: AGPL-3.0-only
% Uncertified — research prototype, not for operational use.
% Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

function applyAction(b, action)
%AZ.APPLYACTION Apply 1-based ACTION to go.Board B (handle class, in place).
% Action ids: 1..N^2 are point moves (0-based id = action-1),
% N^2+1 is pass.
A = b.N^2 + 1;
if action == A
    b.play([]);
else
    b.play(action - 1);
end
end
