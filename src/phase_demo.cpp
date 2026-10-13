// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

#include "sensor_models.hpp"
#include "kalman_track.hpp"
#include "colregs_scenarios.hpp"
#include <iostream>
#include <random>
#include <cmath>

int main() {
    using namespace maritime;
    std::mt19937 rng(42);

    std::cout << "=== Phase 2-4 Demo (uncertified research prototype) ===\n\n";

    // Phase 4: load a standard encounter
    auto encounters = standard_encounters();
    const auto& enc = encounters[0]; // head-on
    std::cout << "Encounter: " << enc.description << "\n";

    double own_x = enc.own_x, own_y = enc.own_y;
    double own_vx = enc.own_speed * std::cos(enc.own_heading);
    double own_vy = enc.own_speed * std::sin(enc.own_heading);

    double cx = enc.contact_x, cy = enc.contact_y;
    double cvx = enc.contact_speed * std::cos(enc.contact_heading);
    double cvy = enc.contact_speed * std::sin(enc.contact_heading);

    // Phase 3: initialize track from first observation
    auto obs0 = observe_contact(own_x, own_y, enc.own_heading,
                                cx, cy, 0.0, 1.0, 0.05, rng);
    double z_x = own_x + obs0.range_m * std::cos(enc.own_heading + obs0.bearing_rad);
    double z_y = own_y + obs0.range_m * std::sin(enc.own_heading + obs0.bearing_rad);
    KalmanTrack track(z_x, z_y);

    constexpr double dt = 1.0;
    for (int step = 0; step < 8; ++step) {
        // Advance truth
        own_x += own_vx * dt; own_y += own_vy * dt;
        cx += cvx * dt; cy += cvy * dt;

        // Phase 2: noisy observation
        auto obs = observe_contact(own_x, own_y, enc.own_heading,
                                   cx, cy, step * dt, 1.0, 0.05, rng);
        double zx = own_x + obs.range_m * std::cos(enc.own_heading + obs.bearing_rad);
        double zy = own_y + obs.range_m * std::sin(enc.own_heading + obs.bearing_rad);

        // Phase 3: track update
        track.predict(dt);
        track.update(zx, zy);

        // CPA/TCPA from estimated relative motion
        auto [cpa, tcpa] = cpa_tcpa(own_x, own_y, own_vx, own_vy,
                                    track.x(), track.y(), track.vx(), track.vy());

        std::cout << "t=" << step
                  << " true_contact=(" << cx << "," << cy << ")"
                  << " track=(" << track.x() << "," << track.y() << ")"
                  << " CPA=" << cpa << " TCPA=" << tcpa << "\n";
    }

    std::cout << "\nPhase 2-4 scaffold complete. Not COLREGs-compliant or validated.\n";
    return 0;
}
