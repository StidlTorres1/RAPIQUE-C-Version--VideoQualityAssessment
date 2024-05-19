#include <gtest/gtest.h>
#include <vector>
#include <opencv2/opencv.hpp>
#include <opencv2/core/ocl.hpp>
#include <opencv2/cudaarithm.hpp>
#include <opencv2/cudafilters.hpp>
#include "RAPIQUE_spatial_features.cuh"  // Ensure this matches the correct header file name

class RAPIQUESpatialFeaturesTest : public ::testing::Test {
protected:
    cv::Mat valid_rgb_image;
    cv::Mat empty_image;

    void SetUp() override {
        // Create a simple valid RGB gradient image (e.g., 256x256 with a gradient)
        valid_rgb_image = cv::Mat::zeros(256, 256, CV_8UC3);
        for (int i = 0; i < valid_rgb_image.rows; ++i) {
            for (int j = 0; j < valid_rgb_image.cols; ++j) {
                valid_rgb_image.at<cv::Vec3b>(i, j) = cv::Vec3b(i % 256, j % 256, (i + j) % 256);
            }
        }

        // Empty image
        empty_image = cv::Mat();
    }
};

TEST_F(RAPIQUESpatialFeaturesTest, ValidImageInput) {
    // Test RAPIQUE_spatial_features with a valid RGB image
    std::vector<float> features = RAPIQUE_spatial_features(valid_rgb_image);

    // Expected number of features (assuming 680 features to be extracted)
    size_t expected_num_features = 680;
    ASSERT_EQ(features.size(), expected_num_features);
}

TEST_F(RAPIQUESpatialFeaturesTest, EmptyImageInput) {
    // Test RAPIQUE_spatial_features with an empty image
    std::vector<float> features = RAPIQUE_spatial_features(empty_image);

    // Check that the feature vector is empty or handle the case appropriately
    ASSERT_TRUE(features.empty());
}


// Main function - entry point for running all tests
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}