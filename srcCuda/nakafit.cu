#include <vector>
#include <numeric>
#include <cmath>
#include <iostream>
#include "Logger.h"
#include "Globals.h"

std::vector<double> nakafit(const std::vector<double>& data) {
    logger.startTimer(video_name_global, "nakafit");
    if (data.empty()) {
        return { 0.0, 0.0 };
    }

    const auto n = data.size();
    const double mean = std::accumulate(data.begin(), data.end(), 0.0) / n;

    const double sq_sum = std::inner_product(data.begin(), data.end(), data.begin(), 0.0,
        std::plus<>(),
        [mean](double a, double b) { return (a - mean) * (b - mean); });

    const double stdev = std::sqrt(sq_sum / (n - 1));
    const double mean_over_stdev_sq = (mean / stdev) * (mean / stdev);
    logger.stopTimer(video_name_global, "nakafit");
    return { mean, mean_over_stdev_sq };
}
