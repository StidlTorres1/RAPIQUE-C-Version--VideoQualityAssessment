#include "YUVReader.h"
#include <gtest/gtest.h>
#include <opencv2/opencv.hpp>
#include <fstream>
#include <iostream>

void generateYUV420File(const std::string& filename, int width, int height, int frameCount) {
    std::ofstream yuvFile(filename, std::ios::binary);
    if (!yuvFile) {
        std::cerr << "Cannot create file!\n";
        return;
    }

    std::vector<unsigned char> Y(width * height, 128); // Set all Y to 128
    std::vector<unsigned char> U(width * height / 4, 64); // Set all U to 64
    std::vector<unsigned char> V(width * height / 4, 64); // Set all V to 64

    for (int i = 0; i < frameCount; ++i) {
        yuvFile.write(reinterpret_cast<const char*>(Y.data()), Y.size());
        yuvFile.write(reinterpret_cast<const char*>(U.data()), U.size());
        yuvFile.write(reinterpret_cast<const char*>(V.data()), V.size());
    }
}

class YUVReaderTest : public ::testing::Test {
protected:
    void SetUp() override {
        filename = "test.yuv";
        width = 4;
        height = 4;
        frameCount = 2;
        generateYUV420File(filename, width, height, frameCount);
    }

    void TearDown() override {
        remove(filename.c_str());
    }

    std::string filename;
    int width;
    int height;
    int frameCount;
};

TEST_F(YUVReaderTest, ReadImage_ValidFrame) {
    YUVReader reader;
    cv::Mat image = reader.readImage(filename, width, height, 0);

    EXPECT_FALSE(image.empty());
    EXPECT_EQ(image.cols, width);
    EXPECT_EQ(image.rows, height);
    EXPECT_EQ(image.type(), CV_8UC3); // YUV should have 3 channels
}

TEST_F(YUVReaderTest, ReadImage_FrameOutOfBounds) {
    YUVReader reader;
    cv::Mat image = reader.readImage(filename, width, height, frameCount);

    EXPECT_TRUE(image.empty());
}

TEST_F(YUVReaderTest, ReadImage_FileNotFound) {
    YUVReader reader;
    cv::Mat image = reader.readImage("nonexistent_file.yuv", width, height, 0);

    EXPECT_TRUE(image.empty());
}
/*
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}*/