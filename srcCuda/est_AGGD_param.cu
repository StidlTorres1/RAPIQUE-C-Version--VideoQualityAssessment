#include <vector>
#include <cmath>
#include <algorithm>
#include <numeric>
#include <limits>
#include <execution>
#include <future>
#include <iostream>
#include "Logger.h"
#include "Globals.h"


std::pair<float, float> calculateStdDev(const std::vector<double>& vec) {
    float sumLeft = 0.0, sumRight = 0.0;
    int countLeft = 0, countRight = 0;

    for (float val : vec) {
        if (val < 0) {
            sumLeft += std::abs(val);
            ++countLeft;
        }
        else if (val > 0) {
            sumRight += std::abs(val);
            ++countRight;
        }
    }

    float leftMean = countLeft == 0 ? 0.0 : std::sqrt(sumLeft / countLeft);
    float rightMean = countRight == 0 ? 0.0 : std::sqrt(sumRight / countRight);

    return { leftMean, rightMean };
}

std::vector<double> generateGam() {
    std::vector<double> gam;
    for (double g = 0.2; g <= 10.0; g += 0.001) {
        gam.push_back(g);
    }
    return gam;
}


std::tuple<double, double, double> est_AGGD_param(const std::vector<double>& vec) {
    std::vector<double> gam(9951);  // Adjust the size to match MATLAB's 0.2:0.001:10 range
    std::iota(gam.begin(), gam.end(), 200);  // Start from 0.2
    std::transform(gam.begin(), gam.end(), gam.begin(), [](double x) { return x / 1000.0; });

    double sumAbs = std::accumulate(vec.begin(), vec.end(), 0.0,
        [](double acc, double val) { return acc + std::abs(val); });
    double meanAbs = sumAbs / vec.size();

    auto [leftstd, rightstd] = calculateStdDev(vec);

    double gammahat = leftstd / rightstd;
    double rhat = std::pow(meanAbs, 2) / std::accumulate(vec.begin(), vec.end(), 0.0, [](double acc, double val) { return acc + val * val; }) / vec.size();
    double rhatnorm = (rhat * (std::pow(gammahat, 3) + 1) * (gammahat + 1)) / std::pow((std::pow(gammahat, 2) + 1), 2);

    double minDiff = std::numeric_limits<double>::max();
    double alpha = 0.0;

    auto result = std::transform_reduce(
        std::execution::par,
        gam.begin(),
        gam.end(),
        std::make_pair(std::numeric_limits<double>::max(), 0.0),
        [](const std::pair<double, double>& a, const std::pair<double, double>& b) {
            return (a.first < b.first) ? a : b;
        },
        [&rhatnorm](double x) {
            double r_gam_val = std::pow(std::tgamma(2.0 / x), 2) / (std::tgamma(1.0 / x) * std::tgamma(3.0 / x));
            double diff = std::pow(r_gam_val - rhatnorm, 2);
            return std::make_pair(diff, x);
        }
    );

    return { result.second, leftstd, rightstd };
}