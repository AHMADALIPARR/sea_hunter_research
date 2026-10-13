// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

#pragma once
#include <array>
#include <cstdint>
#include <optional>
#include <vector>
#include <string>

namespace az {

constexpr int kMaxSize = 19;

enum class Player : int8_t { Black = 1, White = -1, Empty = 0 };

inline Player opponent(Player p) {
    return static_cast<Player>(-static_cast<int8_t>(p));
}

struct MoveResult {
    bool ok = false;
    int captured = 0;
    std::string message;
};

class GoBoard {
public:
    explicit GoBoard(int size = 9, float komi = 6.5f);

    int size() const { return size_; }
    int n() const { return n_; }
    int pass_move() const { return n_; }
    Player to_play() const { return to_play_; }
    int8_t stone_at(int idx) const { return stones_[idx]; }
    std::optional<int> ko_point() const { return ko_; }
    int passes() const { return passes_; }

    bool is_terminal() const;
    float outcome() const;          // black - white - komi (area)
    float outcome_to_play() const;  // from current player perspective
    MoveResult play(int action);    // 0..n-1 place, n = pass
    std::vector<int> legal_moves() const;

private:
    int size_;
    int n_;
    float komi_;
    Player to_play_ = Player::Black;
    std::optional<int> ko_;
    int passes_ = 0;
    std::array<int8_t, kMaxSize * kMaxSize> stones_{};

    std::vector<int> neighbors(int idx) const;
    std::pair<std::vector<int>, int> group_of(int idx) const;
    bool would_be_suicide(int idx) const;
    void place_and_capture(int idx);
};

} // namespace az
