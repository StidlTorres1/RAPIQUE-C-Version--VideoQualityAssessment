#pragma once
#include "ImageFilter.h"
#include <memory>
#include <opencv2/opencv.hpp>

class FilterFactory {
public:
    virtual std::unique_ptr<ImageFilter> createGaussianFilter(const cv::Mat& window) const = 0;
    virtual ~FilterFactory() = default;
};