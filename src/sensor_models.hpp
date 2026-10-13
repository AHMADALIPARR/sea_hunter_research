// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

#pragma once
#include <cmath>
#include <random>
#include <vector>

namespace maritime {

struct ContactObservation {
    double range_m;
    double bearing_rad;
    double timestamp_s;
    double range_sigma_m;
    double bearing_sigma_rad;
};

// Simple polar radar-like observation of a contact relative to ownship.
// Adds Gaussian noise. Deterministic under a fixed seed.
inline ContactObservation observe_contact(
    double own_x, double own_y, double own_heading,
    double contact_x, double contact_y,
    double t_s, double range_sigma, double bearing_sigma,
    std::mt19937& rng)
{
    const double dx = contact_x - own_x;
    const double dy = contact_y - own_y;
    const double true_range = std::hypot(dx, dy);
    const double true_bearing = std::atan2(dy, dx) - own_heading;

    std::normal_distribution<double> nr(0.0, range_sigma);
    std::normal_distribution<double> nb(0.0, bearing_sigma);

    return {
        true_range + nr(rng),
        true_bearing + nb(rng),
        t_s,
        range_sigma,
        bearing_sigma
    };
}

} // namespace maritime
