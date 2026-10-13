// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

#pragma once
#include <string>
#include <vector>

namespace maritime {

enum class EncounterType {
    HeadOn,
    CrossingFromStarboard,
    CrossingFromPort,
    Overtaking,
    Overtaken
};

struct EncounterFixture {
    EncounterType type;
    double own_x, own_y, own_heading, own_speed;
    double contact_x, contact_y, contact_heading, contact_speed;
    std::string description;
};

// Deterministic civilian COLREGs-inspired encounter generators.
// These are scenario fixtures only — not a full rule engine.
inline std::vector<EncounterFixture> standard_encounters() {
    return {
        {EncounterType::HeadOn,
         0.0, 0.0, 0.0, 2.0,
         40.0, 0.0, 3.14159, 2.0,
         "Head-on: both vessels on reciprocal courses"},

        {EncounterType::CrossingFromStarboard,
         0.0, 0.0, 0.0, 2.0,
         20.0, -15.0, 1.57, 2.0,
         "Crossing: contact from own starboard (give-way)"},

        {EncounterType::CrossingFromPort,
         0.0, 0.0, 0.0, 2.0,
         20.0, 15.0, -1.57, 2.0,
         "Crossing: contact from own port (stand-on)"},

        {EncounterType::Overtaking,
         0.0, 0.0, 0.0, 3.0,
         15.0, 0.0, 0.0, 1.5,
         "Overtaking: own vessel overtaking slower contact"}
    };
}

// Simple CPA/TCPA approximation (constant velocity assumption).
inline std::pair<double, double> cpa_tcpa(
    double ox, double oy, double ovx, double ovy,
    double cx, double cy, double cvx, double cvy)
{
    double dx = cx - ox, dy = cy - oy;
    double dvx = cvx - ovx, dvy = cvy - ovy;
    double dv2 = dvx*dvx + dvy*dvy;
    if (dv2 < 1e-9) return {std::hypot(dx, dy), 0.0};
    double tcpa = -(dx*dvx + dy*dvy) / dv2;
    if (tcpa < 0.0) tcpa = 0.0;
    double cpa_x = dx + dvx * tcpa;
    double cpa_y = dy + dvy * tcpa;
    return {std::hypot(cpa_x, cpa_y), tcpa};
}

} // namespace maritime
