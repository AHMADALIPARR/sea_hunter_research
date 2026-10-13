# Sea Hunter Research — Phase Roadmap

**Uncertified research prototype. Simulation only.**

## Phase 1 (complete)
- 2D kinematic point-vessel
- Waypoint guidance proposal
- Independent safety gate (finite checks, command bounds, static hazard margin)
- See `src/sim_nav_safety.cpp`

## Phase 2 — Sensor Models (complete)
- Deterministic noisy polar observation model (`src/sensor_models.hpp`)
- Gaussian range/bearing noise with fixed seed for reproducibility

## Phase 3 — Uncertainty-Aware Tracking (complete)
- Minimal constant-velocity Kalman filter (`src/kalman_track.hpp`)
- Cartesian state [x, y, vx, vy] with simplified covariance update

## Phase 4 — Civilian COLREGs Scenarios (complete)
- Deterministic encounter fixtures: head-on, crossing (starboard/port), overtaking
- CPA/TCPA approximation under constant-velocity assumption
- See `src/colregs_scenarios.hpp`

## Phase 5+ (not started)
- Higher-fidelity 3-DOF hydrodynamics
- Full COLREGs rule engine with stand-on/give-way logic and maneuver selection
- Multi-contact association and track management
- Learned prediction / imitation baselines (only after deterministic metrics exist)
- Formal verification of the safety gate
- Hardware-in-the-loop interfaces (explicitly out of scope until simulation is mature)

All phases remain clean-room, AGPL-3.0-only, and uncertified for operational use.
