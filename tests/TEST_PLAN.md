# Initial Test Plan

The first executable is a scaffold. These cases are required before treating it as a stable baseline:

1. **Waypoint proposal:** heading points toward the waypoint and proposed speed remains bounded.
2. **Finite-state rejection:** NaN or infinity in state causes rejection.
3. **Command bounds:** speed below zero or above configured maximum is rejected.
4. **Hazard margin:** a one-step predicted point within the configured static-hazard margin is rejected.
5. **Time monotonicity:** zero, negative, or regressing time step is rejected.
6. **Separation of concerns:** planner output cannot bypass the safety gate.
7. **Deterministic replay:** identical initial state/configuration produces identical trace.
8. **Boundary behavior:** points exactly at the safety margin follow the documented inclusive/exclusive comparison.

These are software checks, not maritime safety certification or formal verification. CTest integration is the next build increment.
