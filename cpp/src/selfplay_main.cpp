// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

#include "go_board.hpp"
#include "mcts.hpp"
#include <iostream>
#include <random>
#include <chrono>

using namespace az;

int main(int argc, char** argv) {
    int size = 5;
    int sims = 30;
    int games = 3;
    if (argc > 1) size = std::atoi(argv[1]);
    if (argc > 2) sims = std::atoi(argv[2]);
    if (argc > 3) games = std::atoi(argv[3]);

    std::mt19937 rng(42);
    std::cout << "C++ self-play: size=" << size << " sims=" << sims
              << " games=" << games << "\n";

    for (int g = 0; g < games; ++g) {
        GoBoard board(size, 6.5f);
        MCTS mcts(random_evaluator, 1.5f);
        auto t0 = std::chrono::steady_clock::now();
        int moves = 0;
        while (!board.is_terminal() && moves < size * size * 2) {
            bool noise = moves < 10;
            auto pi = mcts.search(board, sims, noise);
            // Sample from visit policy
            std::discrete_distribution<int> dist(pi.begin(), pi.end());
            int action = dist(rng);
            auto res = board.play(action);
            if (!res.ok) board.play(board.pass_move());
            ++moves;
        }
        auto t1 = std::chrono::steady_clock::now();
        double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
        float outcome = board.outcome();
        char result = outcome > 0 ? 'B' : (outcome < 0 ? 'W' : 'D');
        std::cout << " Game " << (g+1) << ": moves=" << moves
                  << " result=" << result << " (" << ms << " ms)\n";
    }
    std::cout << "Done.\n";
    return 0;
}
