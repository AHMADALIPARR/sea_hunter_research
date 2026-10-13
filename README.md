# Sea Hunter Research

Clean-room maritime autonomy simulation platform and AlphaZero-style Go research.

[![License: AGPL-3.0-only](https://img.shields.io/badge/License-AGPL--3.0--only-blue.svg)](LICENSE)
[![C++17](https://img.shields.io/badge/C%2B%2B-17-blue.svg)]()
[![MATLAB](https://img.shields.io/badge/MATLAB-R2023b+-orange.svg)]()

Simulation-only research code. Not operational, not certified, not derived from any proprietary Sea Hunter source.

## Overview

Two independent research threads live in this repository:

1. **Maritime autonomy scaffold** — progressive simulation phases from a minimal safety-gated kinematic vessel to sensor models, tracking, and COLREGs-inspired encounter fixtures.
2. **AlphaZero-style Go engine** — clean-room rules implementation (area scoring, positional superko) plus MCTS and self-play scaffolding in both MATLAB and C++.

Neither thread claims completeness or operational readiness.

## Maritime Phases

| Phase | Status | Description |
|-------|--------|-------------|
| 1 | Done | Kinematic vessel, waypoint guidance, independent safety gate |
| 2 | Done | Noisy polar sensor model |
| 3 | Done | Constant-velocity Kalman track |
| 4 | Done | COLREGs encounter fixtures + CPA/TCPA |
| 5+ | Planned | Hydrodynamics, full rule engine, multi-target association |

See [`docs/PHASES.md`](docs/PHASES.md) for details.

### Build & Run (Maritime)

```bash
cmake -S . -B build
cmake --build build
./build/sim_nav_safety   # Phase 1 baseline
./build/phase_demo       # Phase 2–4 demo
```

## Go / AlphaZero Research

- `matlab/+go/Board.m` — full rules class (area scoring, simple ko / superko)
- `matlab/+az/` — self-play and supporting functions
- `cpp/` — C++ GoBoard with positional superko + optional dead-stone removal, plus MCTS skeleton

```bash
cd cpp && mkdir -p build && cd build
cmake .. && make
./az_selfplay
```

## Repository Layout

```
src/                  Maritime simulation sources
docs/                 Architecture, phases, provenance, interface
matlab/+go/           Go rules engine
matlab/+az/           AlphaZero self-play scaffolding
cpp/                  C++ GoBoard + MCTS
tests/                Test plans
```

## License

**AGPL-3.0-only**. All source files carry `SPDX-License-Identifier: AGPL-3.0-only`.

This is research software. It is not certified for any operational use, has no hardware interface, and makes no claim of formal verification or COLREGs compliance.
