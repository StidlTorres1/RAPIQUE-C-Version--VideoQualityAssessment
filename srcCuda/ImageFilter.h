#pragma once
#include <opencv2/core/cuda.hpp>

class ImageFilter {
public:
    virtual void apply(cv::cuda::GpuMat& src, cv::cuda::GpuMat& dst) const = 0;
    virtual ~ImageFilter() = default;
};