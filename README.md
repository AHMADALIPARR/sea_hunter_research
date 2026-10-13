# Sea Hunter-Inspired Maritime Autonomy Research Platform

[![License: AGPL-3.0-only](https://img.shields.io/badge/License-AGPL--3.0--only-blue.svg)](LICENSE)
[![SPDX](https://img.shields.io/badge/SPDX-AGPL--3.0--only-green.svg)](https://spdx.org/licenses/AGPL-3.0-only.html)
**Uncertified research prototype** — simulation only, not for operational use.

Clean-room civilian research scaffold inspired by public maritime-autonomy research. This is **not** the original Sea Hunter software and is not a validated vessel controller. It is simulation-only and has no hardware actuation interface.

## Interactive Demo Feedback Loop

<details open>
<summary><strong>Click to expand: Maritime Feedback Control Loop</strong></summary>

The core loop: vessel state → waypoint guidance → independent safety gate → kinematic update (or reject) → new state.

![Feedback Control Loop](https://raw.githubusercontent.com/AHMADALIPARR/sea_hunter_research/main/docs/images/feedback_loop.png)

*Generated precision-instrument style diagram of the independent safety-gated feedback loop.*

</details>

<details>
<summary><strong>Click to expand: Simulation Demo Illustration</strong></summary>

![Simulation Demo](https://raw.githubusercontent.com/AHMADALIPARR/sea_hunter_research/main/docs/images/simulation_demo.png)

*2D local XY frame trajectory with static hazard exclusion and independent safety gate schematic. Safety rejection shown when predicted point enters the margin.*

</details>

## Phase 1 Deliverables

- [`docs/SOURCE_PROVENANCE.md`](docs/SOURCE_PROVENANCE.md) — source inventory, licenses, and evidence boundaries.
- [`docs/ARCHITECTURE_GAP_ANALYSIS.md`](docs/ARCHITECTURE_GAP_ANALYSIS.md) — known capabilities, assumptions, and implementation gaps.
- [`docs/INTERFACE_CONTRACT.md`](docs/INTERFACE_CONTRACT.md) — units, state contract, safety result contract.
- [`src/sim_nav_safety.cpp`](src/sim_nav_safety.cpp) — minimal C++ simulation → waypoint guidance → safety gate loop. SPDX: AGPL-3.0-only (uncertified).
- [`CMakeLists.txt`](CMakeLists.txt) — build instructions.
- [`tests/TEST_PLAN.md`](tests/TEST_PLAN.md) — initial verification plan.
- [`matlab/`](matlab/) — optional AlphaZero-style Transformer reference core (clean-room, educational).

## Build and Run

Requires a C++17 compiler and CMake 3.16+.

```sh
cmake -S . -B build
cmake --build build
./build/sim_nav_safety
```

The demo simulates a point-vessel in a flat local XY frame. It proposes bounded heading/speed commands toward a waypoint, then passes them through an independent safety gate that rejects commands when the vessel is too close to a static hazard or inputs are invalid. This is a deliberately small baseline, not COLREGs-compliant navigation.

Sample output is in [`run_sample.txt`](run_sample.txt).

## License

**AGPLv3 only** (GNU Affero General Public License v3.0 only). See [LICENSE](LICENSE).

All source files carry `SPDX-License-Identifier: AGPL-3.0-only` and an uncertified research-prototype notice. No MIT or other licenses are present.

## Non-goals in this phase

No Sea Hunter source recovery, no neural network weights, no learned model, no operational maritime deployment, no real-world control connection, and no claim of formal verification. Further phases should add tested sensor models, uncertainty-aware tracking, civilian COLREGs scenarios, and language-specific ports.
