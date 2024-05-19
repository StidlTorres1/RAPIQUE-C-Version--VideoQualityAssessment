#include <vector>
#include <cmath>
#include <numeric>
#include <algorithm>
#include <execution>
#include <iostream>
#include "Logger.h"
#include "Globals.h"

std::pair<double, double> est_GGD_param(const std::vector<double>& vec) {
    logger.startTimer(video_name_global, "est_GGD_param");

    if (vec.empty()) {
        logger.stopTimer(video_name_global, "est_GGD_param");
        return { 0.0, 0.0 };
    }

    // Define gam range and step size
    const double gam_start = 0.1;
    const double gam_end = 6.0;
    const double gam_step = 0.001;
    const size_t gamSize = static_cast<size_t>((gam_end - gam_start) / gam_step + 1);

    std::vector<double> gam(gamSize);
    std::vector<double> r_gam(gamSize);

    // Initialize gam values
    for (size_t i = 0; i < gamSize; ++i) {
        gam[i] = gam_start + i * gam_step;
    }

    // Calculate statistics needed for rho
    double sumAbsX = std::accumulate(vec.begin(), vec.end(), 0.0, [](double acc, double x) { return acc + std::abs(x); });
    double sumX2 = std::accumulate(vec.begin(), vec.end(), 0.0, [](double acc, double x) { return acc + x * x; });
    double sigma_sq = sumX2 / vec.size();
    double E = sumAbsX / vec.size();
    double rho = sigma_sq / (E * E);
    // Compute r_gam using parallel execution
    std::transform(std::execution::par, gam.begin(), gam.end(), r_gam.begin(), [](double gamVal) {
        double tgamma1 = std::tgamma(1.0 / gamVal);
        double tgamma2 = std::tgamma(2.0 / gamVal);
        double tgamma3 = std::tgamma(3.0 / gamVal);
        return (tgamma1 * tgamma3) / (tgamma2 * tgamma2);
        });

    // Find the gamma value that minimizes the difference to rho
    auto it = std::min_element(r_gam.begin(), r_gam.end(), [rho](double a, double b) { return std::abs(a - rho) < std::abs(b - rho); });
    size_t idx = std::distance(r_gam.begin(), it);

    double beta_par = gam[idx];
    double alpha_par = std::sqrt(sigma_sq);

    logger.stopTimer(video_name_global, "est_GGD_param");
    return { beta_par, alpha_par };
}