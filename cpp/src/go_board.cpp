// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

#include "go_board.hpp"
#include <stdexcept>
#include <queue>
#include <unordered_set>
#include <functional>

namespace az {

GoBoard::GoBoard(int size, float komi)
    : size_(size), n_(size * size), komi_(komi) {
    if (size < 2 || size > kMaxSize)
        throw std::invalid_argument("invalid board size");
    stones_.fill(0);
    history_.insert(board_hash());
}

uint64_t GoBoard::board_hash() const {
    uint64_t h = 14695981039346656037ULL;
    for (int i = 0; i < n_; ++i) {
        h ^= static_cast<uint64_t>(stones_[i] + 1);
        h *= 1099511628211ULL;
    }
    return h;
}

std::vector<int> GoBoard::neighbors(int idx) const {
    int r = idx / size_;
    int c = idx % size_;
    std::vector<int> nb;
    if (r > 0) nb.push_back(idx - size_);
    if (r < size_ - 1) nb.push_back(idx + size_);
    if (c > 0) nb.push_back(idx - 1);
    if (c < size_ - 1) nb.push_back(idx + 1);
    return nb;
}

std::pair<std::vector<int>, int> GoBoard::group_of(int idx) const {
    int8_t color = stones_[idx];
    std::vector<int> grp;
    std::unordered_set<int> seen;
    std::queue<int> q;
    q.push(idx);
    seen.insert(idx);
    while (!q.empty()) {
        int cur = q.front(); q.pop();
        grp.push_back(cur);
        for (int nb : neighbors(cur)) {
            if (stones_[nb] == color && !seen.count(nb)) {
                seen.insert(nb);
                q.push(nb);
            }
        }
    }
    int libs = 0;
    std::unordered_set<int> lib_set;
    for (int g : grp) {
        for (int nb : neighbors(g)) {
            if (stones_[nb] == 0 && !lib_set.count(nb)) {
                lib_set.insert(nb);
                ++libs;
            }
        }
    }
    return {grp, libs};
}

void GoBoard::place_and_capture(int idx) {
    int8_t me = static_cast<int8_t>(to_play_);
    int8_t opp = static_cast<int8_t>(opponent(to_play_));
    stones_[idx] = me;

    int captured = 0;
    int single_cap = -1;
    for (int nb : neighbors(idx)) {
        if (stones_[nb] == opp) {
            auto [grp, libs] = group_of(nb);
            if (libs == 0) {
                for (int g : grp) stones_[g] = 0;
                captured += static_cast<int>(grp.size());
                if (grp.size() == 1) single_cap = grp[0];
            }
        }
    }

    ko_.reset();
    if (captured == 1) {
        auto [own, own_libs] = group_of(idx);
        if (own.size() == 1 && own_libs == 1 && single_cap >= 0)
            ko_ = single_cap;
    }
}

MoveResult GoBoard::play(int action) {
    if (dead_removal_phase_)
        return {false, 0, "dead removal phase"};

    if (action == n_) { // pass
        ++passes_;
        ko_.reset();
        to_play_ = opponent(to_play_);
        if (passes_ >= 2)
            dead_removal_phase_ = true;
        return {true, 0, ""};
    }
    if (action < 0 || action >= n_)
        return {false, 0, "range"};
    if (stones_[action] != 0)
        return {false, 0, "occupied"};
    if (ko_ && *ko_ == action)
        return {false, 0, "ko"};

    // Simulate for suicide + superko
    auto saved = stones_;
    int8_t me = static_cast<int8_t>(to_play_);
    int8_t opp = static_cast<int8_t>(opponent(to_play_));
    stones_[action] = me;
    int cap = 0;
    for (int nb : neighbors(action)) {
        if (stones_[nb] == opp) {
            auto [grp, libs] = group_of(nb);
            if (libs == 0) {
                for (int g : grp) stones_[g] = 0;
                cap += static_cast<int>(grp.size());
            }
        }
    }
    auto [own, own_libs] = group_of(action);
    bool suicide = (cap == 0 && own_libs == 0);
    uint64_t h = board_hash();
    stones_ = saved;

    if (suicide)
        return {false, 0, "suicide"};
    if (history_.count(h))
        return {false, 0, "superko"};

    place_and_capture(action);
    history_.insert(board_hash());
    passes_ = 0;
    dead_removal_phase_ = false;
    to_play_ = opponent(to_play_);
    return {true, 0, ""};
}

std::vector<int> GoBoard::legal_moves() const {
    if (dead_removal_phase_) return {};
    std::vector<int> moves;
    for (int a = 0; a < n_; ++a) {
        if (stones_[a] != 0) continue;
        if (ko_ && *ko_ == a) continue;

        auto saved = stones_;
        // const_cast for temporary simulation (legal_moves is const)
        auto* self = const_cast<GoBoard*>(this);
        self->stones_[a] = static_cast<int8_t>(to_play_);
        int8_t opp = static_cast<int8_t>(opponent(to_play_));
        for (int nb : neighbors(a)) {
            if (self->stones_[nb] == opp) {
                auto [grp, libs] = self->group_of(nb);
                if (libs == 0)
                    for (int g : grp) self->stones_[g] = 0;
            }
        }
        auto [own, own_libs] = self->group_of(a);
        bool suicide = (own_libs == 0);
        uint64_t h = self->board_hash();
        self->stones_ = saved;

        if (!suicide && !history_.count(h))
            moves.push_back(a);
    }
    moves.push_back(n_); // pass always legal
    return moves;
}

bool GoBoard::is_terminal() const {
    return passes_ >= 2 && !dead_removal_phase_;
}

void GoBoard::remove_dead(const std::vector<int>& dead_indices) {
    if (!dead_removal_phase_) return;
    for (int idx : dead_indices) {
        if (idx >= 0 && idx < n_ && stones_[idx] != 0)
            stones_[idx] = 0;
    }
    dead_removal_phase_ = false;
    history_.insert(board_hash());
}

float GoBoard::outcome() const {
    // Area scoring (Tromp-Taylor / Chinese style)
    std::vector<bool> seen(n_, false);
    float black = 0.f, white = 0.f;
    for (int i = 0; i < n_; ++i) {
        if (seen[i]) continue;
        if (stones_[i] == 1) { black += 1.f; seen[i] = true; continue; }
        if (stones_[i] == -1) { white += 1.f; seen[i] = true; continue; }
        std::vector<int> region;
        std::queue<int> q;
        q.push(i);
        seen[i] = true;
        bool touch_b = false, touch_w = false;
        while (!q.empty()) {
            int c = q.front(); q.pop();
            region.push_back(c);
            for (int nb : neighbors(c)) {
                if (stones_[nb] == 1) touch_b = true;
                else if (stones_[nb] == -1) touch_w = true;
                else if (!seen[nb]) {
                    seen[nb] = true;
                    q.push(nb);
                }
            }
        }
        if (touch_b && !touch_w) black += static_cast<float>(region.size());
        else if (touch_w && !touch_b) white += static_cast<float>(region.size());
    }
    return black - white - komi_;
}

float GoBoard::outcome_to_play() const {
    float s = outcome();
    return (to_play_ == Player::Black) ? s : -s;
}

} // namespace az
