// CUDAImageFilter.h
#include <opencv2/core/cuda.hpp>
#include "ImageFilter.h"
#include <opencv2/cudafilters.hpp>

class CUDAImageFilter : public ImageFilter {
    cv::Ptr<cv::cuda::Filter> filter; // Use cv::Ptr for OpenCV objects with automatic memory management.

public:
    CUDAImageFilter(const cv::Mat& window);
    void apply(cv::cuda::GpuMat& src, cv::cuda::GpuMat& dst) const override;
};