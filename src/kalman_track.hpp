// SPDX-License-Identifier: AGPL-3.0-only
// Uncertified — research prototype, not for operational use.
// Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

#pragma once
#include <array>
#include <cmath>

namespace maritime {

// Minimal constant-velocity Kalman filter in Cartesian coordinates.
// State: [x, y, vx, vy]. Process and measurement noise are scalar approximations.
class KalmanTrack {
public:
    KalmanTrack(double x0, double y0, double process_var = 0.1, double meas_var = 1.0)
        : q_(process_var), r_(meas_var)
    {
        x_ = {x0, y0, 0.0, 0.0};
        // Diagonal initial covariance
        for (int i = 0; i < 4; ++i) P_[i][i] = 10.0;
    }

    void predict(double dt) {
        // F = [[1,0,dt,0],[0,1,0,dt],[0,0,1,0],[0,0,0,1]]
        double x = x_[0] + x_[2] * dt;
        double y = x_[1] + x_[3] * dt;
        x_ = {x, y, x_[2], x_[3]};

        // Simplified P update (diagonal process noise)
        for (int i = 0; i < 4; ++i) P_[i][i] += q_ * dt;
    }

    void update(double z_x, double z_y) {
        // H = [[1,0,0,0],[0,1,0,0]]
        double innov_x = z_x - x_[0];
        double innov_y = z_y - x_[1];
        double S = P_[0][0] + r_;
        double K = P_[0][0] / S;

        x_[0] += K * innov_x;
        x_[1] += K * innov_y;
        P_[0][0] *= (1.0 - K);
        P_[1][1] *= (1.0 - K);
    }

    std::array<double, 4> state() const { return x_; }
    double x() const { return x_[0]; }
    double y() const { return x_[1]; }
    double vx() const { return x_[2]; }
    double vy() const { return x_[3]; }

private:
    std::array<double, 4> x_{};
    double P_[4][4] = {};
    double q_, r_;
};

} // namespace maritime
