#include <gtest/gtest.h>
#include <opencv2/opencv.hpp>
#include <opencv2/cudaarithm.hpp>
#include <opencv2/cudafilters.hpp>
#include "gen_DoG.cuh" // Assuming this is the correct header file name

class GenDoGTest : public ::testing::Test {
protected:
    cv::Mat test_image;
    cv::cuda::GpuMat d_test_image;

    void SetUp() override {
        // Create a simple test image (e.g., a 256x256 image with a gradient)
        test_image = cv::Mat::zeros(256, 256, CV_8UC1);
        for (int i = 0; i < test_image.rows; ++i) {
            for (int j = 0; j < test_image.cols; ++j) {
                test_image.at<uchar>(i, j) = static_cast<uchar>((i + j) % 256);
            }
        }

        // Upload the image to GPU memory
        d_test_image.upload(test_image);
    }

    void TearDown() override {
        // Cleanup if necessary
    }
};

TEST_F(GenDoGTest, ValidInput) {
    int kband = 5;
    auto [gspace_img, ksplit_img] = gen_DoG(d_test_image, kband);

    // Check that the sizes of the output vectors are correct
    EXPECT_EQ(gspace_img.size(), kband);
    EXPECT_EQ(ksplit_img.size(), kband);

    // Download results and validate some properties
    for (int i = 0; i < kband; ++i) {
        cv::Mat g_img_host, k_img_host;
        gspace_img[i].download(g_img_host);
        ksplit_img[i].download(k_img_host);

        // Check that the size of each image matches the input image
        EXPECT_EQ(g_img_host.size(), test_image.size());
        EXPECT_EQ(k_img_host.size(), test_image.size());

        // Check that the type of each image matches the input image
        EXPECT_EQ(g_img_host.type(), test_image.type());
        EXPECT_EQ(k_img_host.type(), test_image.type());
    }

    // Additional checks could include validating actual pixel values if expected results are known
}

TEST_F(GenDoGTest, InvalidInput) {
    // Test with invalid type of input
    cv::cuda::GpuMat empty_img;
    EXPECT_THROW(gen_DoG(empty_img, 5), invalid_argument);

    // Test with kband = 0
    EXPECT_THROW(gen_DoG(d_test_image, 0), invalid_argument);
}

/* Main function - entry point for running all tests
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}*/