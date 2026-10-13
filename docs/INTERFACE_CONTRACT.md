# Interface Contract — Version 0.1

## Coordinate frame

- Frame: local Cartesian East-North-Up projection simplified to 2D `x_m`, `y_m` for the initial prototype.
- Units: meters, seconds, radians, meters/second.
- Heading: radians, positive counter-clockwise from +X (east); this is a prototype convention, not a maritime bearing convention.
- Time: simulation seconds as `double`; wall-clock time is not used by the deterministic demo.

## State

`VesselState { x_m, y_m, heading_rad, speed_mps, sim_time_s }`

All numeric fields must be finite. Speed must be non-negative. The baseline assumes a point-vessel and does not model hull geometry.

## Command proposal

`CommandProposal { heading_rad, speed_mps, planner_id }`

The planner proposes a command; it does not directly actuate hardware. The safety gate returns `ACCEPT` or `REJECT` with a stable reason code. Rejected proposals are not applied.

## Safety results

- `ACCEPTED`: all prototype checks passed.
- `REJECT_NONFINITE`: state or proposal contains NaN/infinity.
- `REJECT_COMMAND_BOUNDS`: speed or heading proposal outside configured bounds.
- `REJECT_HAZARD_MARGIN`: predicted one-step position is within the configured static-hazard margin.
- `REJECT_INVALID_TIME`: simulation time regressed or timestep invalid.

## Determinism

The demo has no random number generation. Identical initial state, hazard configuration, and timestep should produce identical output on a given build. Floating-point cross-compiler identity is not promised.

## Limitations

No geodesy, AIS, radar, camera, COLREGs logic, moving contacts, actuator model, current/wind/wave model, probabilistic uncertainty, neural model, or hardware output exists in v0.1.
