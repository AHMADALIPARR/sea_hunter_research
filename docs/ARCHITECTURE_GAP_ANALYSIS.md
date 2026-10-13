# Architecture Gap Analysis — Phase 1

## 1. Facts supported by public references

- DARPA describes ACTUV as an unmanned surface-vessel program focused on extended autonomous operation, safe navigation, and autonomous system management.
- DARPA reported that the demonstrator passed progressively challenging at-sea tests involving sensing/autonomy integration and compliance with COLREGs in operationally realistic scenarios.
- NASA/JPL describes a high-sea-state research approach involving onboard sea-state estimation, wave parameters, a 3D sea-surface model, hazard identification, and safe-path generation that accounts for waves, wind, and vessel control surfaces.
- A public ROS 2 USV simulator repository proposes a layered architecture with scenario evaluation, navigation/guidance/control, sensor interfaces, vehicle dynamics/actuators, and marine physics.
- Aeolus Ocean's public README describes PPO/imitation-learning navigation, radar/camera fusion, and COLREG-oriented simulation, but also says the current release is binary form.

## 2. Not established by these sources

- The original Sea Hunter neural-network architecture, if any.
- Original model weights, source tree, training data, or private engineering specifications.
- Exact internal algorithms, source-code interfaces, runtime scheduling, and hardware/software partitioning.
- That any third-party simulator reproduces Sea Hunter's implementation.

## 3. Proposed research architecture (new work)

`Scenario clock → sensor observations → validation/time alignment → state estimate → track fusion → optional learned prediction → civilian navigation planner → independent safety gate → simulated command application → audit log`

The initial prototype intentionally collapses this to a 2D kinematic vessel, a waypoint guidance rule, a static hazard, and an independent command safety gate. It does not implement a full COLREGs rule engine.

## 4. Gap table

| Capability | Evidence / current state | Gap | Next action |
|---|---|---|---|
| Source provenance | Phase 1 inventory created | Exact commit SHAs and license files still need pinning before code reuse | Record SHA and license checksums for any adopted source |
| Interface schema | Minimal C++ structs and contract doc | No cross-language schema yet | Define versioned JSON/CBOR/protobuf-like interchange contract without forcing a runtime |
| Simulation | Flat 2D point-vessel loop | No hydrodynamics, actuator lag, waves, wind, current, or world physics | Add a tested low-fidelity 3-DOF model |
| Sensor models | None in executable baseline | No timestamps, noise, dropout, association, or uncertainty propagation | Add deterministic synthetic observation generator |
| State estimation | None | No tracking, EKF/Kalman filtering, or covariance | Implement and test an estimator independently |
| Navigation | Waypoint heading/speed proposal only | No COLREGs logic, moving contacts, CPA/TCPA, route constraints, or receding-horizon planner | Add civilian encounter fixtures and deterministic rule-based planner |
| Safety gate | Basic finite-value, command-bound, and static-hazard checks | Not formally verified; not enough for real-world safety | Expand invariants, tests, and failure-mode analysis |
| Neural models | None | No learned perception, trajectory prediction, or calibration | Add only after deterministic baseline is measurable |
| Cross-language ports | None | No parity guarantees | Keep shared golden vectors and port one module at a time |
| Verification | Manual baseline test plan | No executed test harness yet | Add CTest cases and record observed outcomes |
| Hardware integration | Explicitly absent | No HIL interface | Keep out of scope until simulation and safety validation mature |

## 5. Phase 1 acceptance criteria

- Source references and known limits are documented.
- No claims of original source recovery are made.
- Minimal simulation → planner → safety-gate executable builds under C++17.
- Safety gate is independent from waypoint proposal logic.
- Invalid state and out-of-bound commands are rejected.
- Test cases and limitations are documented.
