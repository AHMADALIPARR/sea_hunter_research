# Sea Hunter-Inspired Maritime Autonomy Research Platform

Clean-room civilian research scaffold inspired by public maritime-autonomy research. This is **not** the original Sea Hunter software and is not a validated vessel controller. It is simulation-only and has no hardware actuation interface.

## Phase 1 deliverables

- `docs/SOURCE_PROVENANCE.md` — source inventory, licenses, and evidence boundaries.
- `docs/ARCHITECTURE_GAP_ANALYSIS.md` — known capabilities, assumptions, and implementation gaps.
- `docs/INTERFACE_CONTRACT.md` — units, state contract, safety result contract.
- `src/sim_nav_safety.cpp` — minimal C++ simulation → waypoint guidance → safety gate loop.
- `CMakeLists.txt` — build instructions.
- `tests/TEST_PLAN.md` — initial verification plan.

## Build and run

Requires a C++17 compiler and CMake 3.16+.

```sh
cmake -S . -B build
cmake --build build
./build/sim_nav_safety
```

The demo simulates a point-vessel in a flat local XY frame. It proposes bounded heading/speed commands toward a waypoint, then passes them through an independent safety gate that rejects commands when the vessel is too close to a static hazard or inputs are invalid. This is a deliberately small baseline, not COLREGs-compliant navigation.

## Non-goals in this phase

No Sea Hunter source recovery, no neural network weights, no learned model, no operational maritime deployment, no real-world control connection, and no claim of formal verification. Further phases should add tested sensor models, uncertainty-aware tracking, civilian COLREGs scenarios, and language-specific ports.
