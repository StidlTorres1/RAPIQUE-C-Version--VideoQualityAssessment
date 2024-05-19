#include <gtest/gtest.h>
#include <vector>
#include <numeric>
#include <cmath>
#include "nakafit.cuh" // Ensure this matches the correct header file name

// Function to compute expected nakafit results
std::vector<double> computeExpectedNakafit(const std::vector<double>& data) {
    if (data.empty()) {
        return { 0.0, 0.0 };
    }

    const auto n = data.size();
    const double mean = std::accumulate(data.begin(), data.end(), 0.0) / n;

    if (n == 1) {
        return { mean, std::numeric_limits<double>::infinity() };
    }

    const double sq_sum = std::inner_product(data.begin(), data.end(), data.begin(), 0.0,
        std::plus<>(),
        [mean](double a, double b) { return (a - mean) * (b - mean); });

    const double stdev = std::sqrt(sq_sum / (n - 1));
    const double mean_over_stdev_sq = (mean / stdev) * (mean / stdev);
    return { mean, mean_over_stdev_sq };
}

// Test suite for nakafit function
class NakafitTest : public ::testing::Test {
};

TEST_F(NakafitTest, NonEmptyInput) {
    // Test with a non-empty vector
    std::vector<double> data = { 1.0, 2.0, 3.0, 4.0, 5.0 };
    std::vector<double> computed = nakafit(data);
    std::vector<double> expected = computeExpectedNakafit(data);

    // Validate results
    EXPECT_NEAR(computed[0], expected[0], 0.0001);  // check mean
    EXPECT_NEAR(computed[1], expected[1], 0.0001);  // check mean_over_stdev_sq
}

TEST_F(NakafitTest, EmptyInput) {
    // Test with an empty vector
    std::vector<double> data;
    std::vector<double> result = nakafit(data);

    EXPECT_EQ(result[0], 0.0);
    EXPECT_EQ(result[1], 0.0);
}

TEST_F(NakafitTest, SingleValueInput) {
    // Test with a single value vector
    std::vector<double> data = { 42.0 };
    std::vector<double> result = nakafit(data);

    EXPECT_EQ(result[0], 42.0);
    EXPECT_EQ(result[1], std::numeric_limits<double>::infinity());  // returning infinity for single value case
}

/*
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}*/