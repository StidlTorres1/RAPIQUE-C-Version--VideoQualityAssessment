#include <gtest/gtest.h>
#include <iostream>
#include <vector>
#include <fstream>
#include <string>
#include <filesystem>
#include <opencv2/opencv.hpp>
#include "calc_RAPIQUE_features.h"

class CalcRAPIQUEFeaturesTest : public ::testing::Test {
protected:
    std::string test_video;
    std::string temp_yuv_path;

    void SetUp() override {
        // Paths based on the provided main function
        std::filesystem::path currentPath = std::filesystem::current_path();
        std::filesystem::path desiredPath = currentPath.parent_path();
        std::string path_separator =
#ifdef _WIN32
            "\\";
#else
            "/";
#endif
        std::string project_root = desiredPath.string();
        std::string data_path = project_root + path_separator + "dataBase" + path_separator + "KONVID_1K" + path_separator;
        test_video = data_path + "3339962845.mp4"; // Example video path
        std::string out_path_temp = project_root + path_separator + "dataBase" + path_separator + "tmp";
        temp_yuv_path = out_path_temp + path_separator + "3339962845.yuv"; // Temp YUV path

        // Ensure temp directory exists
        if (!std::filesystem::exists(out_path_temp)) {
            std::filesystem::create_directory(out_path_temp);
        }

        // Generate the YUV file from the test video using ffmpeg
        std::string cmd = "ffmpeg -loglevel error -y -i " + test_video + " -pix_fmt yuv420p -vsync 0 " + temp_yuv_path;
        int ret = system(cmd.c_str());
        ASSERT_EQ(ret, 0) << "Failed to convert test video to YUV format";
        ASSERT_TRUE(std::filesystem::exists(temp_yuv_path)) << "Failed to create YUV file";
    }

    void TearDown() override {
        // Clean up: Remove the YUV file after the test
        std::remove(temp_yuv_path.c_str());
    }
};

TEST_F(CalcRAPIQUEFeaturesTest, CalcRAPIQUEFeatures) {
    // Test parameters based on typical values from the main function code
    int width = 1920;  // Example width based on typical video resolution
    int height = 1080; // Example height based on typical video resolution
    int framerate = 30; // Example frame rate
    float minside = 512.0f; // Minimum side length as used in main
    std::string net = "resnet50";  // Network name as used in main
    std::string layer = "avg_pool";  // Layer name as used in main
    int log_level = 0; // Log level

    // Call the feature calculation function
    auto features = calc_RAPIQUE_features(temp_yuv_path, width, height, framerate, minside, net, layer, log_level);

    // Basic check that features are not empty
    ASSERT_FALSE(features.empty()) << "Failed: The features should not be empty";

    // Print the size of the first frame's feature vector for debugging
    std::cout << "First frame feature vector size: " << features[0].size() << std::endl;

    // Additional checks can be added here based on expected output properties
    // e.g., size of features, specific values, etc.

    for (const auto& frame_features : features) {
        std::cout << "Frame feature vector size: " << frame_features.size() << std::endl;
        // ASSERT_EQ(frame_features.size(), 2048) << "Each frame feature vector should be of length 2048"; // Example check

        // To debug further, print the first few values of the feature vector
        for (size_t i = 0; i < std::min(frame_features.size(), size_t(10)); ++i) {
            std::cout << frame_features[i] << " ";
        }
        std::cout << std::endl;
    }
}
/*
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}*/