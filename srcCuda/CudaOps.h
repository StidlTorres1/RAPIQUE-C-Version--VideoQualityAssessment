#ifndef CUDAOPS_H
#define CUDAOPS_H

#include "ICudaOps.h"

/**
 * Concrete class implementing ICudaOps interface.
 * Provides functionality for executing various image processing operations
 * utilizing the GPU acceleration capabilities provided by OpenCV's CUDA module.
 */
class CudaOps : public ICudaOps {
public:
    /**
     * Perform color space conversion on a GPU matrix.
     *
     * @param src Source GpuMat in one color space.
     * @param dst Destination GpuMat in the target color space.
     * @param code Integer specifying the type of conversion (e.g., cv::COLOR_BGR2GRAY).
     */
    void cvtColor(const cv::cuda::GpuMat& src, cv::cuda::GpuMat& dst, int code) const override;

    /**
     * Convert the type of a GPU matrix.
     *
     * @param src Source GpuMat.
     * @param dst Destination GpuMat with the converted type.
     * @param rtype Desired type in the form of `CV_[The number of bits per item][Signed or Unsigned][Type Prefix]C[The channel number]`.
     */
    void convertTo(const cv::cuda::GpuMat& src, cv::cuda::GpuMat& dst, int rtype) const override;

    /**
     * Create a Sobel filter for GPU matrix.
     *
     * @param srcType The source image type.
     * @param ddepth The depth of the destination image.
     * @param dx Order of the derivative x.
     * @param dy Order of the derivative y.
     * @param ksize Size of the extended Sobel kernel; it must be 1, 3, 5, or 7.
     * @return A pointer to the created Sobel filter.
     */
    cv::Ptr<cv::cuda::Filter> createSobelFilter(int srcType, int ddepth, int dx, int dy, int ksize) const override;

    /**
     * Create a Gaussian filter for GPU matrix.
     *
     * @param srcType The source image type.
     * @param ddepth The depth of the destination image.
     * @param ksize Size of the Gaussian kernel.
     * @param sigma Standard deviation of the Gaussian kernel.
     * @return A pointer to the created Gaussian filter.
     */
    cv::Ptr<cv::cuda::Filter> createGaussianFilter(int srcType, int ddepth, const cv::Size& ksize, double sigma) const override;

    /**
     * Compute the magnitude of 2D vectors for a GPU matrix.
     *
     * @param x GpuMat representing the x components of the 2D vectors.
     * @param y GpuMat representing the y components of the 2D vectors.
     * @param magnitude GpuMat where the computed magnitudes are stored.
     */
    void magnitude(const cv::cuda::GpuMat& x, const cv::cuda::GpuMat& y, cv::cuda::GpuMat& magnitude) const override;

    /**
     * Resize a GPU matrix to the specified size.
     *
     * @param src Source GpuMat.
     * @param dst Destination GpuMat with the resized image.
     * @param dsize Desired size of the output image.
     * @param fx Scale factor along the horizontal axis.
     * @param fy Scale factor along the vertical axis.
     * @param interpolation Interpolation method.
     */
    void resize(const cv::cuda::GpuMat& src, cv::cuda::GpuMat& dst, const cv::Size& dsize, double fx, double fy, int interpolation) const override;
};

#endif // CUDAOPS_H