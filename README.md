# Sea Hunter Research

<p align="center">
  <img src="https://img.shields.io/badge/License-AGPL--3.0--only-blue?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/badge/C%2B%2B-17-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white" alt="C++"/>
  <img src="https://img.shields.io/badge/MATLAB-R2023b+-orange?style=for-the-badge&logo=mathworks&logoColor=white" alt="MATLAB"/>
</p>

<p align="center">
  <strong>Maritime autonomy simulation</strong> · <strong>AlphaZero-style Go engine</strong>
</p>

<p align="center">
  <img src="docs/images/guidance_loop.gif" alt="Guidance loop" width="640"/>
</p>

---

## Overview

This repository contains two independent clean-room research components:

1. **Maritime autonomy simulation.** A progressive kinematic model of an unmanned surface vessel. Guidance produces a proposed command; an independent safety gate accepts or rejects it before the state is advanced. Subsequent stages introduce a noisy polar sensor, a constant-velocity Kalman filter, and encounter geometry analysis (CPA/TCPA). The animation above illustrates the basic closed-loop guidance concept.
2. **AlphaZero-style Go engine.** A rules implementation (area scoring, positional superko), a small multilayer-perceptron policy-value network, Monte Carlo Tree Search with PUCT selection, and a self-play training loop. The same pipeline is available in MATLAB (trainable) and C++ (rules + search).

The components share no source code. They are co-located because both address sequential decision-making under hard constraints.

## Background

**Sea Hunter** is an unmanned surface vehicle developed under the Defense Advanced Research Projects Agency (DARPA) Anti-Submarine Warfare Continuous Trail Unmanned Vessel (ACTUV) program. The 132-foot (40 m) trimaran was designed and constructed by Leidos, christened in Portland, Oregon in April 2016, and subsequently transitioned to the Office of Naval Research.

Publicly stated program objectives included long-endurance autonomous operation (nominally 60–90 days), sparse supervisory control rather than continuous remote piloting, and compliance with the International Regulations for Preventing Collisions at Sea (COLREGs). The vessel was sized for independent deployment and was intended primarily for continuous trail of diesel-electric submarines, with a modular payload architecture supporting additional missions.

This repository is a research scaffold motivated by publicly described problems in maritime autonomy: separation of guidance from safety enforcement, sensor observation under uncertainty, track maintenance, and encounter assessment. It does not contain, reverse-engineer, or claim to reproduce any Sea Hunter software, trained weights, or proprietary design information.

## Table of Contents

- [Overview](#overview)
- [Background](#background)
- [Requirements](#requirements)
- [Usage](#usage)
- [Architecture](#architecture)
- [Repository Layout](#repository-layout)
- [License](#license)

---

## Requirements

| Tool | Minimum Version | Notes |
|------|-----------------|-------|
| C++ compiler | C++17 | g++, clang++, or MSVC |
| CMake | 3.16 | |
| MATLAB | R2023b | Required only for the MATLAB Go pipeline |

---

## Usage

### Maritime Simulation

Configure and build from the repository root:

```bash
cmake -S . -B build
cmake --build build
```

Two executables are produced:

- `sim_nav_safety` — Phase 1 demonstration. A kinematic vessel follows a short waypoint sequence. Each guidance command is evaluated by an independent safety gate before the state is integrated.
- `phase_demo` — Phases 2–4 demonstration. A standard encounter is loaded, noisy polar observations are generated, a constant-velocity Kalman filter maintains a track, and CPA/TCPA are computed from the estimated relative motion.

```bash
./build/sim_nav_safety
./build/phase_demo
```

### Go Engine (C++)

```bash
cd cpp
cmake -S . -B build
cmake --build build

./build/az_selfplay 5 50 3   # board size, simulations per move, games
./build/az_test
```

The C++ self-play binary uses a uniform random evaluator. It exercises the rules engine (including positional superko and the optional dead-stone removal phase) and the MCTS implementation. The `cpp/` subtree is also included by default when configuring from the repository root.

### Go Engine (MATLAB)

The MATLAB implementation provides the complete training loop: history-based feature planes, a two-hidden-layer MLP, MCTS with network priors and root Dirichlet noise, self-play trajectory collection, and minibatch SGD with manually derived gradients.

```matlab
cfg.N          = 5;
cfg.hist       = 4;
cfg.sims       = 50;
cfg.cpuct      = 1.5;
cfg.komi       = 6.5;
cfg.maxPlies   = 50;
cfg.tauPlies   = 10;
cfg.noise      = true;
cfg.noiseAlpha = 0.03;
cfg.noiseEps   = 0.25;
cfg.seed       = 42;

D = (2 * cfg.hist + 1) * cfg.N^2;
A = cfg.N^2 + 1;
H = 64;

P    = az.netInit(D, A, H, cfg.seed);
traj = az.selfplay(P, cfg, 1);
data = struct('xs', traj.xs, 'pis', traj.pis, 'zs', traj.zs);
[P, loss] = az.netTrain(P, data, 10, 0.01, 1e-4);
```

---

## Architecture

### System Overview

The repository is organized as two independent stacks. The maritime stack advances a vessel state under a safety-gated guidance loop and optional perception stages. The Go stack implements rules, search, and (in MATLAB) training.

```mermaid
graph LR
    subgraph Maritime
        M1[Guidance]
        M2[Safety Gate]
        M3[Kinematics]
        M4[Sensor]
        M5[Tracker]
        M1 --> M2 --> M3 --> M4 --> M5
    end
    subgraph Go
        G1[Rules]
        G2[MCTS]
        G3[Network]
        G4[Self-play]
        G1 --> G2
        G3 --> G2
        G2 --> G4
        G4 --> G3
    end
```

### Maritime

Guidance and safety enforcement are decoupled. A candidate command is generated from the current state and the active waypoint; the safety gate evaluates it independently and either permits the kinematic update or holds the vessel. Later phases introduce a polar observation model with additive Gaussian noise, a constant-velocity Kalman filter for track maintenance, and closed-form CPA/TCPA under a constant-velocity relative-motion assumption.

```mermaid
graph TD
    A[Vessel State] --> B[Waypoint Guidance]
    B --> C{Safety Gate}
    C -->|Accept| D[Kinematic Update]
    C -->|Reject| E[Hold]
    D --> F[Sensor Observation]
    F --> G[Kalman Track]
    G --> H[CPA TCPA]
    D --> A
```

| Phase | Capability | Executable |
|:------|:-----------|:-----------|
| 1 | Kinematic model, waypoint guidance, independent safety gate | `sim_nav_safety` |
| 2–4 | Polar sensor model, constant-velocity Kalman filter, COLREGs encounter fixtures, CPA/TCPA | `phase_demo` |

Further detail is given in [`docs/PHASES.md`](docs/PHASES.md).

### Go

Self-play generates training data by searching from each position with MCTS. At every leaf the network is evaluated to obtain a policy prior and a scalar value. Selection uses the PUCT formula with Dirichlet noise injected at the root during self-play. After the game terminates, the visit-count distribution and the final outcome (from the mover’s perspective) become the policy and value targets. The training loss is the sum of cross-entropy on the policy and mean-squared error on the value, plus L2 regularization on the weights.

```mermaid
graph TD
    A[netInit] --> B[selfplay]
    B --> C[MCTS]
    C --> D[features]
    C --> E[PUCT]
    E --> F[applyAction]
    F --> C
    B --> G[policy and outcome]
    G --> H[netTrain]
    H --> A
```

| Module | Path | Role |
|:-------|:-----|:-----|
| Rules | `matlab/+go/Board.m` | Area scoring, positional superko, suicide ban |
| Features | `matlab/+az/features.m` | History planes (own/opponent stones) + color-to-move |
| Network | `matlab/+az/netInit.m`, `netForward.m`, `netTrain.m` | Two-hidden-layer MLP, manual backprop |
| Search | `matlab/+az/mcts.m` | PUCT, Dirichlet noise, sign-correct value backup |
| Self-play | `matlab/+az/selfplay.m` | Trajectory collection |
| C++ | `cpp/` | GoBoard, MCTS, self-play binary |

A structural description of an alternative Transformer policy-value network is provided in [`docs/network_tree.xml`](docs/network_tree.xml).

---

## Repository Layout

```text
src/                 Maritime simulation sources
docs/                PHASES.md, network_tree.xml, architecture notes
matlab/+go/          Go rules engine
matlab/+az/          Features, network, MCTS, self-play, training
cpp/                 C++ GoBoard, MCTS, self-play
```

---

## License

This project is licensed under the GNU Affero General Public License v3.0 only. See [LICENSE](LICENSE).
