#include "CudaImageProcessor.h"
#include <opencv2/core/cuda.hpp>
#include <opencv2/cudaarithm.hpp>
#include <opencv2/cudafilters.hpp>

cv::Mat CudaImageProcessor::applyFilter(const cv::Mat& img, const cv::Mat& window) {
    cv::cuda::GpuMat img_gpu(img);
    cv::cuda::GpuMat result_gpu;

    // Ensure image is in a compatible format for filter application
    cv::cuda::GpuMat img_gpu_float;
    img_gpu.convertTo(img_gpu_float, CV_32F);

    // Create and apply the filter
    auto filter = cv::cuda::createLinearFilter(img_gpu_float.type(), img_gpu_float.type(), window, cv::Point(-1, -1), 0, cv::BORDER_DEFAULT);
    filter->apply(img_gpu_float, result_gpu);

    cv::Mat result;
    result_gpu.download(result);

    // Ensure the result has the same dimensions as the input image, providing a sanity check
    assert(result.rows == img.rows && result.cols == img.cols);

    // Debug print
    std::cout << "Filter type: " << window.type() << ", Size: " << window.size() << "\n";
    std::cout << "Result type: " << result.type() << ", Size: " << result.size() << "\n";
    std::cout << "Input type: " << img.type() << ", Size: " << img.size() << "\n";

    return result;
}

cv::Mat CudaImageProcessor::multiply(const cv::Mat& img1, const cv::Mat& img2) {
    cv::cuda::GpuMat img1_gpu(img1), img2_gpu(img2), result_gpu;
    cv::cuda::multiply(img1_gpu, img2_gpu, result_gpu);

    cv::Mat result;
    result_gpu.download(result);
    return result;
}

void CudaImageProcessor::circularShift(const cv::Mat& src, cv::Mat& dst, cv::Point shift) {
    int shift_x = (shift.x % src.cols + src.cols) % src.cols;
    int shift_y = (shift.y % src.rows + src.rows) % src.rows;

    cv::Mat extended;
    cv::copyMakeBorder(src, extended, 0, shift_y, 0, shift_x, cv::BORDER_WRAP);
    cv::Rect roi(shift_x, shift_y, src.cols, src.rows);

    dst = extended(roi);
}