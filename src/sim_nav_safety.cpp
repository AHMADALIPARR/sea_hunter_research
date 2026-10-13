// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>

namespace maritime {

constexpr double kPi = 3.14159265358979323846;

struct VesselState {
    double x_m;
    double y_m;
    double heading_rad;
    double speed_mps;
    double sim_time_s;
};

struct Waypoint {
    double x_m;
    double y_m;
};

struct StaticHazard {
    double x_m;
    double y_m;
    double exclusion_radius_m;
};

struct CommandProposal {
    double heading_rad;
    double speed_mps;
    std::string planner_id;
};

enum class Decision {
    Accepted,
    RejectNonfinite,
    RejectCommandBounds,
    RejectHazardMargin,
    RejectInvalidTime
};

const char* reason(Decision d) {
    switch (d) {
        case Decision::Accepted: return "ACCEPTED";
        case Decision::RejectNonfinite: return "REJECT_NONFINITE";
        case Decision::RejectCommandBounds: return "REJECT_COMMAND_BOUNDS";
        case Decision::RejectHazardMargin: return "REJECT_HAZARD_MARGIN";
        case Decision::RejectInvalidTime: return "REJECT_INVALID_TIME";
    }
    return "REJECT_UNKNOWN";
}

bool finite(double v) { return std::isfinite(v); }

bool valid(const VesselState& s) {
    return finite(s.x_m) && finite(s.y_m) && finite(s.heading_rad) &&
           finite(s.speed_mps) && finite(s.sim_time_s) && s.speed_mps >= 0.0;
}

CommandProposal propose_waypoint_command(const VesselState& s,
                                         const Waypoint& w,
                                         double desired_speed_mps) {
    const double dx = w.x_m - s.x_m;
    const double dy = w.y_m - s.y_m;
    const double heading = std::atan2(dy, dx);
    const double speed = std::fmax(0.0, std::fmin(desired_speed_mps, 3.0));
    return {heading, speed, "waypoint-guidance-v0"};
}

Decision safety_gate(const VesselState& s,
                     const CommandProposal& c,
                     const StaticHazard& h,
                     double dt_s,
                     double max_speed_mps,
                     double safety_margin_m) {
    if (!valid(s) || !finite(c.heading_rad) || !finite(c.speed_mps) ||
        !finite(h.x_m) || !finite(h.y_m) || !finite(h.exclusion_radius_m) ||
        !finite(dt_s) || !finite(max_speed_mps) || !finite(safety_margin_m)) {
        return Decision::RejectNonfinite;
    }
    if (dt_s <= 0.0 || h.exclusion_radius_m < 0.0 || safety_margin_m < 0.0) {
        return Decision::RejectInvalidTime;
    }
    if (c.speed_mps < 0.0 || c.speed_mps > max_speed_mps ||
        c.heading_rad < -kPi || c.heading_rad > kPi) {
        return Decision::RejectCommandBounds;
    }

    // One-step kinematic prediction only; this is not a full collision predictor.
    const double px = s.x_m + c.speed_mps * std::cos(c.heading_rad) * dt_s;
    const double py = s.y_m + c.speed_mps * std::sin(c.heading_rad) * dt_s;
    const double dx = px - h.x_m;
    const double dy = py - h.y_m;
    const double required = h.exclusion_radius_m + safety_margin_m;
    if (dx * dx + dy * dy <= required * required) {
        return Decision::RejectHazardMargin;
    }
    return Decision::Accepted;
}

VesselState apply_simulated_command(const VesselState& s,
                                    const CommandProposal& c,
                                    double dt_s) {
    return {s.x_m + c.speed_mps * std::cos(c.heading_rad) * dt_s,
            s.y_m + c.speed_mps * std::sin(c.heading_rad) * dt_s,
            c.heading_rad,
            c.speed_mps,
            s.sim_time_s + dt_s};
}

} // namespace maritime

int main() {
    using namespace maritime;
    VesselState vessel{0.0, 0.0, 0.0, 0.0, 0.0};
    const Waypoint target{30.0, 10.0};
    const StaticHazard hazard{12.0, 4.0, 2.0};
    constexpr double dt = 1.0;
    constexpr double max_speed = 3.0;
    constexpr double safety_margin = 3.0;

    std::cout << "simulation_only=true\n"
              << "warning=prototype_not_COLREGS_compliant_or_validated_for_real_vessels\n";
    std::cout << std::fixed << std::setprecision(3);

    for (int step = 0; step < 12; ++step) {
        const CommandProposal command = propose_waypoint_command(vessel, target, 2.0);
        const Decision d = safety_gate(vessel, command, hazard, dt, max_speed, safety_margin);
        std::cout << "step=" << step
                  << " t=" << vessel.sim_time_s
                  << " x=" << vessel.x_m
                  << " y=" << vessel.y_m
                  << " proposed_heading=" << command.heading_rad
                  << " proposed_speed=" << command.speed_mps
                  << " safety=" << reason(d) << '\n';
        if (d != Decision::Accepted) {
            std::cout << "command_not_applied=true\n";
            break;
        }
        vessel = apply_simulated_command(vessel, command, dt);
        if (std::hypot(target.x_m - vessel.x_m, target.y_m - vessel.y_m) < 1.0) {
            std::cout << "waypoint_reached=true\n";
            break;
        }
    }
    return 0;
}
