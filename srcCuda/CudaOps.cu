#include "CudaOps.h"
#include <opencv2/cudaimgproc.hpp>
#include <opencv2/cudafilters.hpp>
#include <opencv2/cudawarping.hpp>

/**
 * Performs color space conversion using GPU.
 *
 * @param src The input image as a cv::cuda::GpuMat.
 * @param dst The output image as a cv::cuda::GpuMat, in the target color space.
 * @param code Integer specifying the type of conversion (e.g., cv::COLOR_BGR2GRAY).
 */
void CudaOps::cvtColor(const cv::cuda::GpuMat& src, cv::cuda::GpuMat& dst, int code) const {
    cv::cuda::cvtColor(src, dst, code);
}

/**
 * Converts the bit-depth of input image using GPU.
 *
 * @param src The input image as a cv::cuda::GpuMat.
 * @param dst The output image as a cv::cuda::GpuMat, with the converted bit-depth.
 * @param rtype Desired type in the form of `CV_[The number of bits per item][Signed or Unsigned][Type Prefix]C[The channel number]`.
 */
void CudaOps::convertTo(const cv::cuda::GpuMat& src, cv::cuda::GpuMat& dst, int rtype) const {
    src.convertTo(dst, rtype);
}

/**
 * Creates a Sobel filter operator using GPU.
 *
 * @param srcType The source image type.
 * @param ddepth The desired depth of the destination image.
 * @param dx Order of the derivative x.
 * @param dy Order of the derivative y.
 * @param ksize Size of the extended Sobel kernel; must be 1, 3, 5, or 7.
 * @return A smart pointer to the created cv::cuda::Filter object.
 */
cv::Ptr<cv::cuda::Filter> CudaOps::createSobelFilter(int srcType, int ddepth, int dx, int dy, int ksize) const {
    return cv::cuda::createSobelFilter(srcType, ddepth, dx, dy, ksize);
}

/**
 * Creates a Gaussian smoothing filter using GPU.
 *
 * @param srcType The source image type.
 * @param ddepth The desired depth of the destination image.
 * @param ksize Size of the Gaussian kernel.
 * @param sigma Standard deviation of the Gaussian kernel.
 * @return A smart pointer to the created cv::cuda::Filter object.
 */
cv::Ptr<cv::cuda::Filter> CudaOps::createGaussianFilter(int srcType, int ddepth, const cv::Size& ksize, double sigma) const {
    return cv::cuda::createGaussianFilter(srcType, ddepth, ksize, sigma);
}

/**
 * Computes the magnitude of the gradient for each pixel using GPU.
 *
 * @param x The GpuMat of x-gradient values.
 * @param y The GpuMat of y-gradient values.
 * @param magnitude The output GpuMat where the magnitudes will be stored.
 */
void CudaOps::magnitude(const cv::cuda::GpuMat& x, const cv::cuda::GpuMat& y, cv::cuda::GpuMat& magnitude) const {
    cv::cuda::magnitude(x, y, magnitude);
}

/**
 * Resizes an image using GPU.
 *
 * @param src The source image as a cv::cuda::GpuMat.
 * @param dst The output (resized) image as a cv::cuda::GpuMat.
 * @param dsize The desired size of the output image.
 * @param fx Scale factor along the horizontal axis (ignored if dsize is not empty).
 * @param fy Scale factor along the vertical axis (ignored if dsize is not empty).
 * @param interpolation Interpolation method.
 */
void CudaOps::resize(const cv::cuda::GpuMat& src, cv::cuda::GpuMat& dst, const cv::Size& dsize, double fx, double fy, int interpolation) const {
    cv::cuda::resize(src, dst, dsize, fx, fy, interpolation);
}

