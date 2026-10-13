// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

#include "mcts.hpp"
#include <cmath>
#include <numeric>

namespace az {

MCTS::MCTS(Evaluator eval, float c_puct, float dirichlet_alpha, float dirichlet_frac)
    : eval_(std::move(eval)), c_puct_(c_puct),
      dirichlet_alpha_(dirichlet_alpha), dirichlet_frac_(dirichlet_frac) {}

void MCTS::expand(MCTSNode& node, const GoBoard& board) {
    if (board.is_terminal()) {
        node.terminal = true;
        node.terminal_value = board.outcome_to_play();
        node.expanded = true;
        return;
    }
    auto [policy, value] = eval_(board);
    auto legal = board.legal_moves();
    for (int a : legal) {
        auto child = std::make_unique<MCTSNode>();
        child->prior = (a < (int)policy.size()) ? policy[a] : 0.f;
        node.children[a] = std::move(child);
    }
    node.net_value = value;
    node.expanded = true;
}

void MCTS::add_dirichlet(MCTSNode& node) {
    if (node.children.empty()) return;
    std::gamma_distribution<float> gamma(dirichlet_alpha_, 1.f);
    std::vector<float> noise;
    float sum = 0.f;
    for (size_t i = 0; i < node.children.size(); ++i) {
        float v = gamma(rng_);
        noise.push_back(v);
        sum += v;
    }
    size_t i = 0;
    for (auto& [a, child] : node.children) {
        float n = noise[i++] / sum;
        child->prior = (1.f - dirichlet_frac_) * child->prior + dirichlet_frac_ * n;
    }
}

int MCTS::select(const MCTSNode& node) const {
    uint32_t total = 0;
    for (auto& [a, c] : node.children) total += c->visit;
    float total_f = float(total > 0 ? total : 1);
    int best = -1;
    float best_score = -1e30f;
    for (auto& [a, c] : node.children) {
        float u = c_puct_ * c->prior * std::sqrt(total_f) / (1.f + float(c->visit));
        float score = c->q() + u;
        if (score > best_score) {
            best_score = score;
            best = a;
        }
    }
    return best;
}

void MCTS::simulate(MCTSNode& root, GoBoard board) {
    std::vector<std::pair<MCTSNode*, int>> path;
    MCTSNode* node = &root;

    while (node->expanded && !node->terminal && !node->children.empty()) {
        int action = select(*node);
        path.emplace_back(node, action);
        auto res = board.play(action);
        if (!res.ok) break;
        node = node->children[action].get();
        if (!node->expanded) break;
    }

    if (!node->expanded) expand(*node, board);

    float value = node->terminal ? node->terminal_value : node->net_value;

    for (auto it = path.rbegin(); it != path.rend(); ++it) {
        MCTSNode* parent = it->first;
        int action = it->second;
        MCTSNode* child = parent->children[action].get();
        child->visit += 1;
        child->value_sum += -value;
        value = -value;
    }
}

std::vector<float> MCTS::search(const GoBoard& root_board, int n_simulations, bool add_noise) {
    MCTSNode root;
    expand(root, root_board);
    if (add_noise) add_dirichlet(root);

    for (int i = 0; i < n_simulations; ++i)
        simulate(root, root_board);

    std::vector<float> policy(root_board.n() + 1, 0.f);
    float total = 0.f;
    for (auto& [a, c] : root.children) {
        policy[a] = float(c->visit);
        total += policy[a];
    }
    if (total > 0)
        for (float& p : policy) p /= total;
    return policy;
}

std::pair<std::vector<float>, float> random_evaluator(const GoBoard& board) {
    auto legal = board.legal_moves();
    std::vector<float> policy(board.n() + 1, 0.f);
    float p = 1.f / float(legal.size());
    for (int a : legal) policy[a] = p;
    return {policy, 0.f};
}

} // namespace az
