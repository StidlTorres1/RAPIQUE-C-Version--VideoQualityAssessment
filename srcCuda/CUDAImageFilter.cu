// CUDAImageFilter.cpp
#include "CUDAImageFilter.h"
#include <opencv2/cudafilters.hpp>

CUDAImageFilter::CUDAImageFilter(const cv::Mat& window) {
    filter = cv::cuda::createLinearFilter(CV_32F, -1, window); // This returns cv::Ptr<cv::cuda::Filter>.
}

void CUDAImageFilter::apply(cv::cuda::GpuMat& src, cv::cuda::GpuMat& dst) const {
    filter->apply(src, dst); // cv::Ptr allows direct use like this, managing memory automatically.
}