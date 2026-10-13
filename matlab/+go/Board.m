% SPDX-License-Identifier: AGPL-3.0-only
% Uncertified — research prototype, not for operational use.
% Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

classdef Board < handle
%GO.BOARD Clean-room Go rules engine for the AlphaGo Zero recreation.
% N x N board, area scoring, simple ko, suicide ban, two passes end game.
% Actions are 0-based linear indices (column-major); [] = pass.
    properties
        N
        board % N*N int8 column-major: 0 empty, 1 black, 2 white
        toMove = 1 % 1 = black, 2 = white
        koPoint = 0 % 1-based index forbidden by simple ko, 0 = none
        passes = 0
        capturedByBlack = 0
        capturedByWhite = 0
    end
    methods
        function obj = Board(N)
            obj.N = N;
            obj.board = zeros(N, N, 'int8');
        end

        function [tf, reason] = isLegal(obj, a)
            % A: 0-based linear action id, or [] for pass.
            if isempty(a), tf = true; reason = ''; return; end
            if a < 0 || a >= obj.N*obj.N
                tf = false; reason = 'range'; return
            end
            idx = a + 1;
            if obj.board(idx) ~= 0
                tf = false; reason = 'occupied'; return
            end
            if idx == obj.koPoint
                tf = false; reason = 'ko'; return
            end
            r = obj.simulate(idx);
            if r.suicide
                tf = false; reason = 'suicide'; return
            end
            tf = true; reason = '';
        end

        function play(obj, a)
            % A: 0-based linear action id, or [] for pass. (Handle class:
            % mutates in place.)
            [tf, reason] = obj.isLegal(a);
            if ~tf, error('go:illegal', 'illegal move (%s)', reason); end
            if isempty(a)
                obj.passes = obj.passes + 1;
                obj.koPoint = 0;
                obj.toMove = 3 - obj.toMove;
                return
            end
            obj.applySim(obj.simulate(a + 1));
        end

        function tf = isTerminal(obj)
            tf = obj.passes >= 2;
        end

        function s = score(obj, komi)
            % Area scoring: s = black - white - komi. Empty regions count
            % for a color only if that color exclusively borders them.
            seen = false(obj.N*obj.N, 1);
            val = zeros(obj.N*obj.N, 1);
            for i = 1:obj.N*obj.N
                if ~seen(i)
                    if obj.board(i) == 1
                        val(i) = 1; seen(i) = true;
                    elseif obj.board(i) == 2
                        val(i) = -1; seen(i) = true;
                    else
                        region = []; touchBlack = false; touchWhite = false;
                        stack = i;
                        while ~isempty(stack)
                            c = stack(end); stack(end) = [];
                            if seen(c), continue; end
                            seen(c) = true; region(end+1) = c; %#ok<*AGROW>
                            nbs = Board.neighborsOf(obj.N, c);
                            for k = 1:numel(nbs)
                                if obj.board(nbs(k)) == 1
                                    touchBlack = true;
                                elseif obj.board(nbs(k)) == 2
                                    touchWhite = true;
                                elseif ~seen(nbs(k))
                                    stack(end+1) = nbs(k); %#ok<*AGROW>
                                end
                            end
                        end
                        if touchBlack && ~touchWhite, val(region) = 1; end
                        if touchWhite && ~touchBlack, val(region) = -1; end
                    end
                end
            end
            s = sum(val) - komi;
        end

        function h = stateHash(obj)
            % FNV-1a 32-bit over board bytes + toMove + koPoint + passes.
            h = uint32(2166136261);
            v = [double(obj.board(:)); obj.toMove; obj.koPoint; obj.passes];
            for k = 1:numel(v)
                h = bitxor(h, uint32(v(k)));
                h = mod(h * uint32(16777619), uint32(4294967296));
            end
        end
    end
    methods (Access = private)
        function r = simulate(obj, idx)
            % Stone at IDX (1-based): capture adjacent opponent groups, detect
            % suicide, apply simple-ko rule. Returns a simulation record.
            me = obj.toMove; opp = 3 - me;
            b = obj.board;
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
            b(idx) = me;
            [~, ownLibs] = Board.groupOf(b, obj.N, idx);
            r.suicide = (cap == 0 && ownLibs == 0);
            r.board = b;
            r.koPoint = 0;
            if cap == 1 && ownLibs == 1
                [ownGrp, ~] = Board.groupOf(b, obj.N, idx);
                if numel(ownGrp) == 1, r.koPoint = capIdx; end
            end
            r.passes = 0;
            if me == 1
                r.capturedByBlack = obj.capturedByBlack + cap;
                r.capturedByWhite = obj.capturedByWhite;
            else
                r.capturedByWhite = obj.capturedByWhite + cap;
                r.capturedByBlack = obj.capturedByBlack;
            end
            r.toMove = 3 - me;
        end

        function applySim(obj, r)
            obj.board = r.board;
            obj.koPoint = r.koPoint;
            obj.passes = r.passes;
            obj.capturedByBlack = r.capturedByBlack;
            obj.capturedByWhite = r.capturedByWhite;
            obj.toMove = r.toMove;
        end
    end
    methods (Static)
        function nb = neighborsOf(N, idx)
            % Linear neighbor indices of IDX (1-based, column-major).
            [i, j] = ind2sub([N N], idx);
            nb = [];
            if i > 1, nb(end+1) = idx - N; end %#ok<*AGROW>
            if i < N, nb(end+1) = idx + N; end %#ok<*AGROW>
            if j > 1, nb(end+1) = idx - 1; end %#ok<*AGROW>
            if j < N, nb(end+1) = idx + 1; end %#ok<*AGROW>
        end

        function [grp, libs] = groupOf(b, N, idx)
            % Stones connected to IDX (including IDX) and their liberty count.
            color = b(idx);
            grp = idx; seen = false(N*N, 1); seen(idx) = true;
            head = 1;
            while head <= numel(grp)
                nbs = Board.neighborsOf(N, grp(head));
                for k = 1:numel(nbs)
                    nb = nbs(k);
                    if b(nb) == color && ~seen(nb)
                        seen(nb) = true; grp(end+1) = nb; %#ok<*AGROW>
                    end
                end
                head = head + 1;
            end
            libs = 0;
            for k = 1:numel(grp)
                nbs = Board.neighborsOf(N, grp(k));
                for m = 1:numel(nbs)
                    if b(nbs(m)) == 0, libs = libs + 1; end
                end
            end
        end
    end
end
