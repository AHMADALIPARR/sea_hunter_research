// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

#pragma once
#include "go_board.hpp"
#include <functional>
#include <memory>
#include <unordered_map>
#include <vector>
#include <random>

namespace az {

struct MCTSNode {
    float prior = 0.f;
    uint32_t visit = 0;
    float value_sum = 0.f;
    bool expanded = false;
    bool terminal = false;
    float terminal_value = 0.f;
    float net_value = 0.f;
    std::unordered_map<int, std::unique_ptr<MCTSNode>> children;

    float q() const { return visit == 0 ? 0.f : value_sum / float(visit); }
};

// Evaluator: given board, return (policy over action_space, value in [-1,1])
using Evaluator = std::function<std::pair<std::vector<float>, float>(const GoBoard&)>;

class MCTS {
public:
    MCTS(Evaluator eval, float c_puct = 1.5f,
         float dirichlet_alpha = 0.03f, float dirichlet_frac = 0.25f);

    // Returns visit-count policy of length board.n()+1
    std::vector<float> search(const GoBoard& root_board, int n_simulations,
                              bool add_noise = false);

private:
    Evaluator eval_;
    float c_puct_;
    float dirichlet_alpha_;
    float dirichlet_frac_;
    std::mt19937 rng_{42};

    void expand(MCTSNode& node, const GoBoard& board);
    void add_dirichlet(MCTSNode& node);
    int select(const MCTSNode& node) const;
    void simulate(MCTSNode& root, GoBoard board);
};

// Uniform random policy + zero value (for testing without a network)
std::pair<std::vector<float>, float> random_evaluator(const GoBoard& board);

} // namespace az
