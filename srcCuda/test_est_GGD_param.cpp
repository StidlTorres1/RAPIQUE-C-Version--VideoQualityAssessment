#include <gtest/gtest.h>
#include <vector>
#include <cmath>
#include <numeric>
#include <algorithm>
#include <execution>
#include "est_GGD_param.cuh" // Assuming this is the correct header file name

// Helper function to validate expected results with some tolerance
void validateResults(const std::pair<double, double>& computed, const std::pair<double, double>& expected, double tolerance = 0.01) {
    EXPECT_NEAR(computed.first, expected.first, tolerance);
    EXPECT_NEAR(computed.second, expected.second, tolerance);
}

// Test suite for est_GGD_param function
class EstGGDParamTest : public ::testing::Test {
};

TEST_F(EstGGDParamTest, NonEmptyInput) {
    // Test with a non-empty vector
    std::vector<double> data = { 1.0, 2.0, 3.0, 4.0, 5.0 };
    auto [beta_par, alpha_par] = est_GGD_param(data);

    // Expected results
    double sumX2 = std::accumulate(data.begin(), data.end(), 0.0, [](double acc, double x) { return acc + x * x; });
    double sigma_sq = sumX2 / data.size();
    double expectedAlpha = std::sqrt(sigma_sq);

    // Correctly derive expectedBeta from the function calculations
    double sumAbsX = std::accumulate(data.begin(), data.end(), 0.0, [](double acc, double x) { return acc + std::abs(x); });
    double E = sumAbsX / data.size();
    double rho = sigma_sq / (E * E);

    double expectedBeta = 0.1;  // This is an example. Let's refine below.
    {  // Compute gamma value closest match to rho
        std::vector<double> gam(5901);  // (6.0 - 0.1) / 0.001 + 1
        std::iota(gam.begin(), gam.end(), static_cast<size_t>(0));
        std::transform(gam.begin(), gam.end(), gam.begin(), [](double val) { return 0.1 + val * 0.001; });

        std::vector<double> r_gam(gam.size());
        std::transform(gam.begin(), gam.end(), r_gam.begin(), [](double gamVal) {
            double tgamma1 = std::tgamma(1.0 / gamVal);
            double tgamma2 = std::tgamma(2.0 / gamVal);
            double tgamma3 = std::tgamma(3.0 / gamVal);
            return (tgamma1 * tgamma3) / (tgamma2 * tgamma2);
            });

        auto it = std::min_element(r_gam.begin(), r_gam.end(), [rho](double a, double b) { return std::abs(a - rho) < std::abs(b - rho); });
        expectedBeta = 0.1 + std::distance(r_gam.begin(), it) * 0.001;
    }

    validateResults({ beta_par, alpha_par }, { expectedBeta, expectedAlpha });
}

TEST_F(EstGGDParamTest, EmptyInput) {
    // Test with an empty vector
    std::vector<double> data;
    auto [beta_par, alpha_par] = est_GGD_param(data);

    EXPECT_EQ(beta_par, 0.0);
    EXPECT_EQ(alpha_par, 0.0);
}

TEST_F(EstGGDParamTest, SingleValueInput) {
    // Test with a single value vector
    std::vector<double> data = { 42.0 };
    auto [beta_par, alpha_par] = est_GGD_param(data);

    // For a single value, alpha_par should be the value itself, and beta_par should be theoretically irrelevant but deterministic
    EXPECT_EQ(alpha_par, 42.0);
    EXPECT_GT(beta_par, 0.0); // Ensure beta_par is a positive number
}

/* Main function - entry point for running all tests
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}*/