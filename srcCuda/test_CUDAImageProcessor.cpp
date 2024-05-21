#include <gtest/gtest.h>
#include <opencv2/opencv.hpp>
#include "CudaImageProcessor.h"  // Ensure this matches the correct header file name

class CudaImageProcessorTest : public ::testing::Test {
protected:
    cv::Mat img1;
    cv::Mat img2;
    cv::Mat window;
    CudaImageProcessor processor;

    void SetUp() override {
        // Create simple gradient images
        img1 = cv::Mat::zeros(256, 256, CV_32F);
        img2 = cv::Mat::ones(256, 256, CV_32F);

        for (int i = 0; i < img1.rows; ++i) {
            for (int j = 0; j < img1.cols; ++j) {
                img1.at<float>(i, j) = static_cast<float>(i + j);
            }
        }

        // Create a simple filter window
        window = (cv::Mat_<float>(3, 3) << 0, -1, 0, -1, 5, -1, 0, -1, 0);
    }
};

TEST_F(CudaImageProcessorTest, ApplyFilter) {
    cv::Mat result = processor.applyFilter(img1, window);

    // Check that the result has the same dimensions as the input image
    ASSERT_EQ(result.rows, img1.rows);
    ASSERT_EQ(result.cols, img1.cols);

    // Debug prints
    std::cout << "Result:\n";
    std::cout << result(cv::Rect(128, 128, 10, 10)) << std::endl;

    std::cout << "Input:\n";
    std::cout << img1(cv::Rect(128, 128, 10, 10)) << std::endl;

    // Check some pixel values to ensure the filter is applied correctly
    // Note: Instead of guessing final value, compute expected by checking surrounding values affected by filter
    float expected_val = 5 * img1.at<float>(128, 128) - img1.at<float>(127, 128) - img1.at<float>(129, 128) - img1.at<float>(128, 127) - img1.at<float>(128, 129);
    EXPECT_NEAR(result.at<float>(128, 128), expected_val, 1e-5);
}

TEST_F(CudaImageProcessorTest, Multiply) {
    cv::Mat result = processor.multiply(img1, img2);

    // Check that the result has the same dimensions as the input images
    ASSERT_EQ(result.rows, img1.rows);
    ASSERT_EQ(result.cols, img1.cols);

    // Check some pixel values to ensure multiplication is correct
    for (int i = 0; i < result.rows; ++i) {
        for (int j = 0; j < result.cols; ++j) {
            EXPECT_FLOAT_EQ(result.at<float>(i, j), img1.at<float>(i, j) * img2.at<float>(i, j));
        }
    }
}

TEST_F(CudaImageProcessorTest, CircularShift) {
    cv::Mat shifted;
    cv::Point shift(10, 20);
    processor.circularShift(img1, shifted, shift);

    // Check that the result has the same dimensions as the input image
    ASSERT_EQ(shifted.rows, img1.rows);
    ASSERT_EQ(shifted.cols, img1.cols);

    // Check shifted values against manually shifted regions
    for (int i = 0; i < img1.rows; ++i) {
        for (int j = 0; j < img1.cols; ++j) {
            int srcX = (j + shift.x) % img1.cols;
            int srcY = (i + shift.y) % img1.rows;
            EXPECT_FLOAT_EQ(shifted.at<float>(i, j), img1.at<float>(srcY, srcX));
        }
    }
}
/*
// Main function - entry point for running all tests
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}*/