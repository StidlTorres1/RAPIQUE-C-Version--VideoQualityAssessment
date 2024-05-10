#include "CUDAFilterFactory.h"
#include "CUDAImageFilter.h"

std::unique_ptr<ImageFilter> CUDAFilterFactory::createGaussianFilter(const cv::Mat& window) const {
    return std::make_unique<CUDAImageFilter>(window);
}