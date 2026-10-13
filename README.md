# Sea Hunter Research

[![License: AGPL-3.0-only](https://img.shields.io/badge/License-AGPL--3.0--only-blue.svg)](LICENSE)
[![C++17](https://img.shields.io/badge/C%2B%2B-17-blue.svg)]()
[![MATLAB](https://img.shields.io/badge/MATLAB-R2023b+-orange.svg)]()

Clean-room research repository containing two independent threads:

1. **Maritime autonomy simulation** — progressive phases from kinematic vessel + safety gate through sensors, tracking, and COLREGs encounter fixtures.
2. **AlphaZero-style Go** — complete rules engine, MLP policy-value network, full MCTS, and self-play pipeline (MATLAB + C++).

## How to run

### Prerequisites
- C++17 compiler (g++, clang++, or MSVC)
- CMake 3.16+
- MATLAB R2023b+ (only for the MATLAB Go pipeline)

### Maritime (C++)

From the repository root:

```bash
cmake -S . -B build
cmake --build build

# Phase 1: kinematic vessel + safety gate
./build/sim_nav_safety

# Phases 2–4: sensors, Kalman track, COLREGs fixtures + CPA/TCPA
./build/phase_demo
```

### Go / AlphaZero (C++)

```bash
cd cpp
cmake -S . -B build
cmake --build build

# Self-play with random evaluator (size, simulations, games)
./build/az_selfplay 5 50 3

# Basic rules tests
./build/az_test
```

Or build everything from the root (Go subtree is included by default):

```bash
cmake -S . -B build && cmake --build build
./build/az_selfplay
./build/az_test
```

### Go / AlphaZero (MATLAB)

From the repository root (so `+go` and `+az` are on the path):

```matlab
% Example config
cfg.N = 5;
cfg.hist = 4;
cfg.sims = 50;
cfg.cpuct = 1.5;
cfg.komi = 6.5;
cfg.maxPlies = 50;
cfg.tauPlies = 10;
cfg.noise = true;
cfg.noiseAlpha = 0.03;
cfg.noiseEps = 0.25;
cfg.seed = 42;

D = (2*cfg.hist + 1) * cfg.N^2;   % feature dimension
A = cfg.N^2 + 1;                  % actions (points + pass)
H = 64;                           % hidden size

P = az.netInit(D, A, H, cfg.seed);
traj = az.selfplay(P, cfg, 1);
data = struct('xs', traj.xs, 'pis', traj.pis, 'zs', traj.zs);
[P, loss] = az.netTrain(P, data, 10, 0.01, 1e-4);
```

## Maritime Pipeline

```
Vessel state → waypoint guidance → safety gate → kinematic update
                         ↓
              noisy polar observation → Kalman track → CPA/TCPA
```

![Feedback loop](docs/images/feedback_loop.png)

| Phase | Status | Entry point |
|-------|--------|-------------|
| 1 — kinematic + safety gate | Done | `./build/sim_nav_safety` |
| 2 — sensor model | Done | `./build/phase_demo` |
| 3 — Kalman track | Done | `./build/phase_demo` |
| 4 — COLREGs fixtures + CPA/TCPA | Done | `./build/phase_demo` |

Details: [`docs/PHASES.md`](docs/PHASES.md)

## Go / AlphaZero Pipeline

```
netInit → selfplay (MCTS + features + applyAction) → netTrain
                ↓
         visit-count policy + outcome z
```

| Component | Location |
|-----------|----------|
| Rules engine | `matlab/+go/Board.m` |
| Features | `matlab/+az/features.m` |
| MLP network | `matlab/+az/netInit.m`, `netForward.m`, `netTrain.m` |
| MCTS | `matlab/+az/mcts.m` |
| Self-play | `matlab/+az/selfplay.m` |
| C++ engine | `cpp/` (`GoBoard`, `MCTS`, `az_selfplay`) |

Network architecture: [`docs/network_tree.xml`](docs/network_tree.xml)

## Layout

```
src/                 Maritime sources
docs/                PHASES.md, network_tree.xml, architecture notes
matlab/+go/          Go rules
matlab/+az/          Features, MLP, MCTS, self-play, training
cpp/                 C++ GoBoard + MCTS + self-play
```

## License

AGPL-3.0-only. Research code only.
