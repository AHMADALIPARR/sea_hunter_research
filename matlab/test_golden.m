% SPDX-License-Identifier: AGPL-3.0-only
% Uncertified — research prototype, not for operational use.
% Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab
% Extracted from mixed dump into clean test function.

function test_golden()
%TEST_GOLDEN Cross-language golden-vector conformance runner.
% All expected values are frozen fixtures computed and verified against a
% reference implementation; any diff is a conformance failure.
% Uses helpers from go_board_helpers.m and golden_vectors.json.
fails = {};
b0 = go.Board(5); % assumes go.Board class; replace with local if needed

% ---- G1: neighbor sets (regression for column-major offset mapping) ----
if ~isequal(sort(neighborsOf(5, 13)), [8 12 14 18])
    fails{end+1} = 'G1 neighbors interior'; %#ok<*SAGROW>
end
if ~isequal(sort(neighborsOf(5, 6)), [1 7 11])
    fails{end+1} = 'G1b neighbors top edge'; %#ok<*SAGROW>
end
if ~isequal(sort(neighborsOf(5, 1)), [2 6])
    fails{end+1} = 'G1c neighbors corner'; %#ok<*SAGROW>
end

% Remaining cases assume go.Board implementation; load golden_vectors.json for full fixtures.
% See matlab/golden_vectors.json for AGZF cases G1-G8 and P1-P3.

if isempty(fails)
    fprintf('GOLDEN CONFORMANCE: ALL PASSED (partial G1 extracted)\n');
else
    fprintf('GOLDEN CONFORMANCE FAILURES (%d):\n', numel(fails));
    for i = 1:numel(fails), fprintf(' - %s\n', fails{i}); end
end
end
