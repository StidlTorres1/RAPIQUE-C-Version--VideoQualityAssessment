#pragma once
#include "FilterFactory.h"

class CUDAFilterFactory : public FilterFactory {
public:
    std::unique_ptr<ImageFilter> createGaussianFilter(const cv::Mat& window) const override;
};