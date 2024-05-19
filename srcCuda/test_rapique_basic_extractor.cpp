#include <gtest/gtest.h>
#include <vector>
#include <opencv2/opencv.hpp>
#include <opencv2/core/ocl.hpp>
#include <opencv2/cudaarithm.hpp>
#include <opencv2/cudafilters.hpp>
#include "rapique_basic_extractor.cuh" // Ensure this matches the correct header file name

class RapiqueBasicExtractorTest : public ::testing::Test {
protected:
    cv::Mat valid_image;
    cv::Mat empty_image;

    void SetUp() override {
        // Create a simple valid gradient image (e.g., 256x256 with a gradient)
        valid_image = cv::Mat::zeros(256, 256, CV_8UC1);
        for (int i = 0; i < valid_image.rows; ++i) {
            for (int j = 0; j < valid_image.cols; ++j) {
                valid_image.at<uchar>(i, j) = static_cast<uchar>((i + j) % 256);
            }
        }

        // Empty image
        empty_image = cv::Mat();
    }
};

TEST_F(RapiqueBasicExtractorTest, ValidImageInput) {
    // Test rapique_basic_extractor with a valid image
    std::vector<float> features = rapique_basic_extractor(valid_image);

    // Expected number of features (according to the provided implementation)
    size_t expected_num_features = 34; // Adjusted based on actual feature count from the implementation
    ASSERT_EQ(features.size(), expected_num_features);
}

TEST_F(RapiqueBasicExtractorTest, EmptyImageInput) {
    // Test rapique_basic_extractor with an empty image
    std::vector<float> features = rapique_basic_extractor(empty_image);

    // Check that the feature vector is empty or handle the case appropriately
    ASSERT_TRUE(features.empty());
}

/* Main function - entry point for running all tests
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}*/