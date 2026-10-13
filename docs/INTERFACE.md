# Canonical Interface Specification (v0.1-draft)

All language implementations MUST agree on the following contracts.  
Floating-point comparisons use documented absolute/relative tolerances; bitwise identity is not required across backends.

## 1. Board Indexing

- Board size `N` is a positive integer (standard targets: 9, 13, 19).
- Intersections are indexed in row-major order:  
  `idx = row * N + col` with `row, col ∈ [0, N)`.
- Coordinate system: row 0 is the top of the board when printed with Black’s perspective (standard for many engines; document any deviation).

## 2. Player Identifiers

- Black = +1  
- White = -1  
- Empty = 0  

Value head output is from the perspective of the player about to move (or the documented convention; must be identical across implementations).

## 3. Move Encoding

- Legal placement: integer in `[0, N*N)`.
- Pass move: integer `N*N` (one past the last intersection).
- Resignation (if enabled): documented sentinel, typically `N*N + 1`.
- Policy vector length = `N*N + 1` (placements + pass). Illegal actions are masked to zero probability before normalisation.

## 4. Feature Tensor Layout (Canonical Input)

Input tensor shape for residual CNN / Transformer adapter:

```
[batch, channels, N, N]
```

Minimum channel set (paper-compatible; order fixed):

0. Current player stones (1.0 where current player occupies)
1. Opponent stones
2. … history planes (previous positions of current / opponent, number of history steps is a hyper-parameter, typically 7–8 pairs)
3. Colour / to-play plane (constant 1.0 or 0.0 indicating whose turn)

Exact channel count and ordering will be locked in a later revision of this document and mirrored in every language.  
Illegal-move masking is applied on the policy head output, not inside the feature planes.

## 5. Policy / Value Contract

A model adapter receives a board state (or batch) and returns:

- `policy_logits`: vector of length `N*N + 1` (or masked legal subset)
- `value`: scalar in `[-1, +1]` estimating the expected outcome from the current player’s perspective (`+1` = current player wins, `-1` = current player loses).

Search must not depend on the internal architecture (CNN vs Transformer).

## 6. MCTS Node Quantities

Each node stores at least:

- Prior `P` (from network)
- Visit count `N`
- Total action value `W`
- Mean action value `Q = W / N` (with appropriate initialisation)
- Parent / children links
- Expansion and terminal flags

## 7. PUCT Selection

Selection maximises:

```
a* = argmax_a [ Q(s,a) + U(s,a) ]
```

where

```
U(s,a) = c_puct * P(s,a) * sqrt(Σ_b N(s,b)) / (1 + N(s,a))
```

(or the exact paper variant used; constants and any additional noise terms must be documented and identical across implementations).  
Value perspective flips correctly with player turn on backup.

## 8. Game Record / Checkpoint Format

- Game records: sequence of moves + final outcome + metadata (seed, network hash, search budget).
- Checkpoints: network parameters + optimiser state + training step + random-seed state (where supported) + interface version string.

Exact binary / text serialisation formats will be versioned in `spec/formats/`.

## 9. Randomness

Where reproducibility is required, a language-neutral seed interpretation is defined (e.g., seed expands to a deterministic stream via a documented PRNG). Different language PRNGs may produce different streams; fixtures therefore supply explicit random sequences when cross-language equality is asserted.

## Version

`INTERFACE.md` v0.1-draft – 2026-10-13  
Subsequent revisions will freeze the contracts before any “conformance” claims.
