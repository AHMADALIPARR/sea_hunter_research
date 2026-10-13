// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

#include "go_board.hpp"
#include <cassert>
#include <iostream>

int main() {
    az::GoBoard b(5, 0.5f);
    assert(b.size() == 5);
    assert(b.n() == 25);
    assert(!b.is_terminal());

    auto legal = b.legal_moves();
    assert(!legal.empty());

    // Pass twice → terminal (after dead-removal phase is cleared)
    auto r1 = b.play(b.pass_move());
    assert(r1.ok);
    auto r2 = b.play(b.pass_move());
    assert(r2.ok);
    b.remove_dead({}); // clear dead-removal phase
    assert(b.is_terminal());

    std::cout << "go_board basic tests passed\n";
    return 0;
}
