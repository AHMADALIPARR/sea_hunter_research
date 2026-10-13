function test_golden()
%TEST_GOLDEN Cross-language golden-vector conformance runner.
% All expected values are frozen fixtures computed and verified against a
% reference implementation; any diff is a conformance failure.
fails = {};
b0 = go.Board(5);

% ---- G1: neighbor sets (regression for column-major offset mapping) ----
if ~isequal(sort(b0.neighborsOf(13)), [8 12 14 18])
    fails{end+1} = 'G1 neighbors interior'; %#ok<*SAGROW>
end
if ~isequal(sort(b0.neighborsOf(6)), [1 7 11])
    fails{end+1} = 'G1b neighbors top edge'; %#ok<*SAGROW>
end
if ~isequal(sort(b0.neighborsOf(1)), [2 6])
    fails{end+1} = 'G1c neighbors corner'; %#ok<*SAGROW>
end

% ---- G2: place then occupied ----
b = go.Board(5);
[tf1, ~] = b.isLegal(12);
b.play(12);
[tf2, r2] = b.isLegal(12);
if ~(tf1 && ~tf2 && strcmp(r2, 'occupied') && b.toMove == 2 && b.board(13) == 1)
    fails{end+1} = 'G2 place then occupied'; %#ok<*SAGROW>
end

% ---- G3: single-stone capture ----
b = go.Board(5);
for m = [7 2 25 12 24 6 23 8], b.play(m - 1); end
if ~(b.board(7) == 0 && b.capturedByWhite == 1 && b.capturedByBlack == 0)
    fails{end+1} = 'G3 single stone capture'; %#ok<*SAGROW>
end

% ---- G4: suicide ban ----
b = go.Board(5);
for m = [25 2 24 12 23 6 22 8], b.play(m - 1); end
[tf, r] = b.isLegal(6);
if ~(~tf && strcmp(r, 'suicide'))
    fails{end+1} = 'G4 suicide ban'; %#ok<*SAGROW>
end

% ---- G5: simple ko ----
b = go.Board(5);
for m = [1 2 7 25 11 6], b.play(m - 1); end
koOk = b.board(1) == 0 && b.board(6) == 2 && b.koPoint == 1 ...
       && b.capturedByWhite == 1;
[tfK, rK] = b.isLegal(0); % B immediate recapture -> ko
koOk = koOk && ~tfK && strcmp(rK, 'ko');
b.play(3); % B plays elsewhere; ko cleared
koOk = koOk && b.koPoint == 0;
[tfL, ~] = b.isLegal(0); % point playable again (W to move)
koOk = koOk && tfL;
if ~koOk, fails{end+1} = 'G5 simple ko'; end %#ok<*SAGROW>

% ---- G6: area scoring ----
b = go.Board(5);
for m = [7 2 25 12 24 6 23 8], b.play(m - 1); end
if b.score(0.5) ~= -3.5
    fails{end+1} = 'G6 area score'; %#ok<*SAGROW>
end

% ---- G7: state hash ----
b1 = go.Board(5); h1 = b1.stateHash();
b2 = go.Board(5); b2.play(12); h2 = b2.stateHash();
b3 = go.Board(5); b3.play(12);
if ~(h1 == uint32(3068479146) && h2 == uint32(1061019210) ...
        && h2 == b3.stateHash() && h1 ~= h2)
    fails{end+1} = 'G7 state hash'; %#ok<*SAGROW>
end

% ---- G8: two passes end the game ----
b = go.Board(5); b.play([]); b.play([]);
if ~(b.passes == 2 && b.score(0.5) == -0.5)
    fails{end+1} = 'G8 two passes'; %#ok<*SAGROW>
end

% ---- P1..P3: PUCT selection ----
A = 26;
P = zeros(A, 1); P(4) = 0.5; P(11) = 0.3; P(26) = 0.2;
if go.puctSelect(zeros(A, 1), zeros(A, 1), P, 1.25) ~= 4
    fails{end+1} = 'P1 puct prior argmax'; %#ok<*SAGROW>
end
Nv = zeros(A, 1); W = zeros(A, 1); P = repmat(1/26, A, 1);
Nv(6) = 10; W(6) = 8; Nv(8) = 10; W(8) = -8;
if go.puctSelect(Nv, W, P, 1.25) ~= 6
    fails{end+1} = 'P2 puct Q dominates'; %#ok<*SAGROW>
end
Nv = repmat(5, A, 1); W = ones(A, 1); P = zeros(A, 1); P(26) = 1.0;
if go.puctSelect(Nv, W, P, 1.25) ~= 26
    fails{end+1} = 'P3 puct only pass legal'; %#ok<*SAGROW>
end

% ---- report ----
if isempty(fails)
    fprintf('GOLDEN CONFORMANCE: ALL PASSED (G1-G8, P1-P3)\n');
else
    fprintf('GOLDEN CONFORMANCE FAILURES (%d):\n', numel(fails));
    for i = 1:numel(fails), fprintf(' - %s\n', fails{i}); end
end
end
{
  "format": "AGZF", "version": 1, "N": 5,
  "actionIdConvention": "0-based linear column-major, null/[] = pass",
  "cases": [
    { "id": "G1", "name": "neighbors interior", "idx": 13, "expected": [8, 12, 14, 18] },
    { "id": "G1b", "name": "neighbors top edge (1,2)", "idx": 6, "expected": [1, 7, 11] },
    { "id": "G1c", "name": "neighbors corner (1,1)", "idx": 1, "expected": [2, 6] },
    { "id": "G2", "name": "place then occupied",
      "expected": { "firstTf": true, "secondTf": false, "secondReason": "occupied",
                    "toMove": 2, "board13": 1 } },
    { "id": "G3", "name": "single stone capture",
      "moves_1based": [7, 2, 25, 12, 24, 6, 23, 8],
      "expected": { "board7": 0, "capturedByWhite": 1, "capturedByBlack": 0 } },
    { "id": "G4", "name": "suicide ban",
      "moves_1based": [25, 2, 24, 12, 23, 6, 22, 8],
      "expected": { "tf": false, "reason": "suicide" } },
    { "id": "G5", "name": "simple ko",
      "moves_1based": [1, 2, 7, 25, 11, 6],
      "expected": { "board1": 0, "board6": 2, "koPoint": 1, "capturedByWhite": 1,
                    "immediateRecaptureTf": false, "immediateRecaptureReason": "ko",
                    "koPointAfterIntervening": 0, "laterTf": true } },
    { "id": "G6", "name": "area score komi 0.5",
      "moves_1based": [7, 2, 25, 12, 24, 6, 23, 8],
      "expected": { "score": -3.5 } },
    { "id": "G7", "name": "state hash",
      "expected": { "emptyHash": 3068479146, "afterMoveHash": 1061019210,
                    "deterministic": true, "distinct": true } },
    { "id": "G8", "name": "terminal after two passes",
      "expected": { "passes": 2, "score": -0.5 } }
  ],
  "puct": [
    { "id": "P1", "cpuct": 1.25, "argmax": 3, "score": 0.625 },
    { "id": "P2", "cpuct": 1.25, "argmax": 5, "score": 0.8195460487543689 },
    { "id": "P3", "cpuct": 1.25, "argmax": 25, "score": 2.5753654689565377 }
  ]
}function r = simulate(obj, idx)
    % Stone at IDX (1-based). Order matters: place the stone FIRST, then
    % capture adjacent opponent groups, then check own liberties.
    me = obj.toMove; opp = 3 - me;
    b = obj.board;
    b(idx) = me; % <-- placed before capture scan
    cap = 0; capIdx = 0;
    nbs = Board.neighborsOf(obj.N, idx);
    for k = 1:numel(nbs)
        nb = nbs(k);
        if b(nb) == opp
            [grp, libs] = Board.groupOf(b, obj.N, nb);
            if libs == 0
                b(grp) = 0;
                cap = cap + numel(grp);
                if numel(grp) == 1, capIdx = grp(1); end
            end
        end
    end
    [~, ownLibs] = Board.groupOf(b, obj.N, idx);
    r.suicide = (cap == 0 && ownLibs == 0);
    r.board = b;
    r.koPoint = 0;
    if cap == 1 && ownLibs == 1
        [ownGrp, ~] = Board.groupOf(b, obj.N, idx);
        if numel(ownGrp) == 1, r.koPoint = capIdx; end
    end
    ...function nb = neighborsOf(N, idx)
    % Linear neighbor indices of IDX (1-based, column-major):
    % idx = i + (j-1)*N, so up/down (row) are -1/+1, left/right (col) are -N/+N.
    [i, j] = ind2sub([N N], idx);
    nb = [];
    if i > 1, nb(end+1) = idx - 1; end %#ok<*AGROW> % up
    if i < N, nb(end+1) = idx + 1; end %#ok<*AGROW> % down
    if j > 1, nb(end+1) = idx - N; end %#ok<*AGROW> % left
    if j < N, nb(end+1) = idx + N; end %#ok<*AGROW> % right
end
