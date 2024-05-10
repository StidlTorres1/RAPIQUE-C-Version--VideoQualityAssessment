#pragma once
#include <opencv2/opencv.hpp>
#include <string>

class ImageReader {
public:
    virtual cv::Mat readImage(const std::string& filename, int width, int height, int frameNum) = 0;
    virtual ~ImageReader() {}
};