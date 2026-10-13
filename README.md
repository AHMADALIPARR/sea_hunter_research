# Sea Hunter Research

[![License: AGPL-3.0-only](https://img.shields.io/badge/License-AGPL--3.0--only-blue.svg)](LICENSE)
[![C++17](https://img.shields.io/badge/C%2B%2B-17-blue.svg)]()
[![MATLAB](https://img.shields.io/badge/MATLAB-R2023b+-orange.svg)]()

Clean-room research repository containing two independent threads:

1. **Maritime autonomy simulation** — progressive phases from kinematic vessel + safety gate through sensors, tracking, and COLREGs encounter fixtures.
2. **AlphaZero-style Go** — complete rules engine, MLP policy-value network, full MCTS, and self-play pipeline (MATLAB + C++).

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

```bash
cmake -S . -B build && cmake --build build
./build/sim_nav_safety
./build/phase_demo
```

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

```bash
# MATLAB (from repo root, with +go/+az on path)
P = az.netInit(D, A, H, seed);
traj = az.selfplay(P, cfg, 1);
data = struct('xs', traj.xs, 'pis', traj.pis, 'zs', traj.zs);
[P, loss] = az.netTrain(P, data, 10, 0.01, 1e-4);

# C++
cd cpp && cmake -S . -B build && cmake --build build
./build/az_selfplay
./build/az_test
```

Network architecture diagram: [`docs/network_tree.xml`](docs/network_tree.xml)

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
