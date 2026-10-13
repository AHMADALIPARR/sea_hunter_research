// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab
// NOTE: Header extracted from truncated dump; implementation incomplete.

#pragma once
// Full Go rules: placement, capture, simple ko, pass, Tromp-Taylor scoring.
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

    // Methods referenced by MCTS / self-play (stubs until full impl)
    bool is_terminal() const;
    float outcome() const;
    float outcome_to_play() const;
    MoveResult play(int action);
    std::vector<int> legal_moves() const;

private:
    int size_ = 9;
    int n_ = 81;
    float komi_ = 6.5f;
    Player to_play_ = Player::Black;
    std::optional<int> ko_;
    std::array<int8_t, kMaxSize * kMaxSize> stones_{};
};

} // namespace az
