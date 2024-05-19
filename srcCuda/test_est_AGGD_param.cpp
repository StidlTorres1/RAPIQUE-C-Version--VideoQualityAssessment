#include <gtest/gtest.h>
#include <vector>
#include <cmath>
#include <numeric>
#include <algorithm>
#include <execution>
#include "est_AGGD_param.cuh" // Ensure the function names and file path are correct

// Helper to manually calculate standard deviation
float manualStdDev(const std::vector<double>& vec, bool left) {
    double sum = 0.0;
    int count = 0;
    for (const auto& val : vec) {
        if ((left && val < 0.0) || (!left && val > 0.0)) {
            sum += std::abs(val);
            count++;
        }
    }
    return count == 0 ? 0.0 : std::sqrt(sum / count);
}

// Test suite for calculateStdDev function
TEST(EstAGGDParamTestSuite, CalculateStdDev) {
    std::vector<double> data = { -1, -2, -3, 1, 2, 3 };
    auto [leftStd, rightStd] = calculateStdDev(data);

    float expectedLeftStd = std::sqrt((1.0 + 2.0 + 3.0) / 3.0); // sqrt(2)
    float expectedRightStd = std::sqrt((1.0 + 2.0 + 3.0) / 3.0); // sqrt(2)

    std::cout << "Expected Left Std Dev: " << expectedLeftStd << std::endl;
    std::cout << "Expected Right Std Dev: " << expectedRightStd << std::endl;
    std::cout << "Calculated Left Std Dev: " << leftStd << std::endl;
    std::cout << "Calculated Right Std Dev: " << rightStd << std::endl;

    EXPECT_NEAR(leftStd, expectedLeftStd, 0.0001);
    EXPECT_NEAR(rightStd, expectedRightStd, 0.0001);

    data = { -1, -4, -9 };
    std::tie(leftStd, rightStd) = calculateStdDev(data);

    expectedLeftStd = std::sqrt((1.0 + 4.0 + 9.0) / 3.0); // sqrt(14 / 3.0)
    expectedRightStd = 0.0;  // No positive values in data

    std::cout << "New Expected Left Std Dev: " << expectedLeftStd << std::endl;
    std::cout << "New Calculated Left Std Dev: " << leftStd << std::endl;

    EXPECT_NEAR(leftStd, expectedLeftStd, 0.0001);
    EXPECT_EQ(rightStd, 0.0);

    data = { 4, 16, 25 };
    std::tie(leftStd, rightStd) = calculateStdDev(data);

    expectedLeftStd = 0.0;  // No negative values in data
    expectedRightStd = std::sqrt((4.0 + 16.0 + 25.0) / 3.0); // sqrt((4+16+25)/3)

    std::cout << "New Expected Right Std Dev: " << expectedRightStd << std::endl;
    std::cout << "New Calculated Right Std Dev: " << rightStd << std::endl;

    EXPECT_EQ(leftStd, 0.0);
    EXPECT_NEAR(rightStd, expectedRightStd, 0.0001);
}

// Test suite for generateGam function
TEST(EstAGGDParamTestSuite, GenerateGam) {
    auto gam = generateGam();

    EXPECT_EQ(gam.size(), 9801);
    EXPECT_NEAR(gam.front(), 0.2, 0.0001);
    EXPECT_NEAR(gam.back(), 10.0, 0.0001);
}

// Test suite for est_AGGD_param function
TEST(EstAGGDParamTestSuite, EstAGGDParam) {
    std::vector<double> data = { -1.0, -2.0, -3.0, 4.0, 2.0, 1.0, -1.0, 0.5 };

    auto [alpha, leftStd, rightStd] = est_AGGD_param(data);

    std::cout << "Alpha: " << alpha << std::endl;
    std::cout << "Left Std Dev: " << leftStd << std::endl;
    std::cout << "Right Std Dev: " << rightStd << std::endl;

    float expectedLeftStd = manualStdDev(data, true);
    float expectedRightStd = manualStdDev(data, false);

    std::cout << "Expected Left Std Dev: " << expectedLeftStd << std::endl;
    std::cout << "Expected Right Std Dev: " << expectedRightStd << std::endl;

    EXPECT_GE(alpha, 0.0);
    EXPECT_NEAR(leftStd, expectedLeftStd, 0.2);
    EXPECT_NEAR(rightStd, expectedRightStd, 0.2);
}

/* Main function - entry point for running all tests
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}*/