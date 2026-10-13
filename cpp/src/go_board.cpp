// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

#include "go_board.hpp"
#include <stdexcept>
#include <queue>
#include <unordered_set>

namespace az {

GoBoard::GoBoard(int size, float komi)
    : size_(size), n_(size * size), komi_(komi) {
    if (size < 2 || size > kMaxSize)
        throw std::invalid_argument("invalid board size");
    stones_.fill(0);
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

bool GoBoard::would_be_suicide(int idx) const {
    // Temporary place to test
    // (simplified: check after hypothetical place + captures)
    return false; // full check done in play path
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

    // Simple ko
    ko_.reset();
    if (captured == 1) {
        auto [own, own_libs] = group_of(idx);
        if (own.size() == 1 && own_libs == 1 && single_cap >= 0)
            ko_ = single_cap;
    }
}

MoveResult GoBoard::play(int action) {
    if (action == n_) { // pass
        ++passes_;
        ko_.reset();
        to_play_ = opponent(to_play_);
        return {true, 0, ""};
    }
    if (action < 0 || action >= n_)
        return {false, 0, "range"};
    if (stones_[action] != 0)
        return {false, 0, "occupied"};
    if (ko_ && *ko_ == action)
        return {false, 0, "ko"};

    // Suicide check: place temporarily, capture, then see own libs
    int8_t me = static_cast<int8_t>(to_play_);
    int8_t opp = static_cast<int8_t>(opponent(to_play_));
    auto saved = stones_;
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
    stones_ = saved;
    if (suicide)
        return {false, 0, "suicide"};

    place_and_capture(action);
    passes_ = 0;
    to_play_ = opponent(to_play_);
    return {true, 0, ""};
}

std::vector<int> GoBoard::legal_moves() const {
    std::vector<int> moves;
    for (int a = 0; a < n_; ++a) {
        if (stones_[a] != 0) continue;
        if (ko_ && *ko_ == a) continue;
        // Quick suicide proxy (full check would clone; accept for now if empty neighbor or capture)
        bool has_empty = false;
        bool can_cap = false;
        for (int nb : neighbors(a)) {
            if (stones_[nb] == 0) has_empty = true;
            if (stones_[nb] == static_cast<int8_t>(opponent(to_play_))) {
                auto [grp, libs] = group_of(nb);
                if (libs == 1) can_cap = true;
            }
        }
        if (has_empty || can_cap)
            moves.push_back(a);
    }
    moves.push_back(n_); // pass always legal
    return moves;
}

bool GoBoard::is_terminal() const {
    return passes_ >= 2;
}

float GoBoard::outcome() const {
    // Area scoring (Tromp-Taylor style)
    std::vector<bool> seen(n_, false);
    float black = 0.f, white = 0.f;
    for (int i = 0; i < n_; ++i) {
        if (seen[i]) continue;
        if (stones_[i] == 1) { black += 1.f; seen[i] = true; continue; }
        if (stones_[i] == -1) { white += 1.f; seen[i] = true; continue; }
        // Empty region
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
