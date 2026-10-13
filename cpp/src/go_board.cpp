// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab
// NOTE: Stub implementation. Full rules from the truncated dump are not yet complete.

#include "go_board.hpp"
#include <stdexcept>

namespace az {

GoBoard::GoBoard(int size, float komi)
    : size_(size), n_(size * size), komi_(komi) {
    if (size < 2 || size > kMaxSize)
        throw std::invalid_argument("invalid board size");
    stones_.fill(0);
}

bool GoBoard::is_terminal() const {
    // Stub: always false until two-pass logic is implemented
    return false;
}

float GoBoard::outcome() const {
    return 0.f; // stub
}

float GoBoard::outcome_to_play() const {
    return 0.f; // stub
}

MoveResult GoBoard::play(int /*action*/) {
    return {false, 0, "not implemented"};
}

std::vector<int> GoBoard::legal_moves() const {
    std::vector<int> moves;
    moves.push_back(n_); // pass only for now
    return moves;
}

} // namespace az
