#pragma once
#include "ImageReader.h"

class YUVReader : public ImageReader {
public:
    cv::Mat readImage(const std::string& filename, int width, int height, int frameNum) override;
};