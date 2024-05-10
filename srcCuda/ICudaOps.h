#ifndef ICUDA_OPERATION_FACTORY_H
#define ICUDA_OPERATION_FACTORY_H

#include <opencv2/core/core.hpp>
#include <opencv2/cudaarithm.hpp>
#include <opencv2/cudafilters.hpp>
#include <opencv2/cudaimgproc.hpp>
#include <opencv2/cudawarping.hpp>

/**
 * @brief Interface to encapsulate CUDA operations for image processing.
 *
 * This interface abstracts common CUDA-accelerated image processing operations,
 * allowing for easier swapping of implementation details and improving testability.
 */
class ICudaOps {
public:
    virtual ~ICudaOps() = default;

    /**
     * @brief Perform color conversion on a GPU matrix.
     *
     * @param src Source GpuMat in one color space.
     * @param dst Destination GpuMat in the target color space.
     * @param code Integer specifying the type of conversion (e.g., cv::COLOR_BGR2GRAY).
     */
    virtual void cvtColor(const cv::cuda::GpuMat& src, cv::cuda::GpuMat& dst, int code) const = 0;

    /**
     * @brief Convert the type of a GPU matrix.
     *
     * @param src Source GpuMat.
     * @param dst Destination GpuMat with the converted type.
     * @param rtype Desired type in the form of `CV_[The number of bits per item][Signed or Unsigned][Type Prefix]C[The channel number]`.
     */
    virtual void convertTo(const cv::cuda::GpuMat& src, cv::cuda::GpuMat& dst, int rtype) const = 0;

    /**
     * @brief Create a Sobel filter for GPU matrix.
     *
     * @param srcType The source image type.
     * @param ddepth The depth of the destination image.
     * @param dx Order of the derivative x.
     * @param dy Order of the derivative y.
     * @param ksize Size of the extended Sobel kernel; it must be 1, 3, 5, or 7.
     * @return A pointer to the created Sobel filter.
     */
    virtual cv::Ptr<cv::cuda::Filter> createSobelFilter(int srcType, int ddepth, int dx, int dy, int ksize) const = 0;

    /**
     * @brief Create a Gaussian filter for GPU matrix.
     *
     * @param srcType The source image type.
     * @param ddepth The depth of the destination image.
     * @param ksize Size of the Gaussian kernel.
     * @param sigma Standard deviation of the Gaussian kernel.
     * @return A pointer to the created Gaussian filter.
     */
    virtual cv::Ptr<cv::cuda::Filter> createGaussianFilter(int srcType, int ddepth, const cv::Size& ksize, double sigma) const = 0;

    /**
     * @brief Compute the magnitude of 2D vectors for a GPU matrix.
     *
     * @param x GpuMat representing the x components of the 2D vectors.
     * @param y GpuMat representing the y components of the 2D vectors.
     * @param magnitude GpuMat where the computed magnitudes are stored.
     */
    virtual void magnitude(const cv::cuda::GpuMat& x, const cv::cuda::GpuMat& y, cv::cuda::GpuMat& magnitude) const = 0;

    /**
     * @brief Resize a GPU matrix to the specified size.
     *
     * @param src Source GpuMat.
     * @param dst Destination GpuMat with the resized image.
     * @param dsize Desired size of the output image.
     * @param fx Scale factor along the horizontal axis.
     * @param fy Scale factor along the vertical axis.
     * @param interpolation Interpolation method.
     */
    virtual void resize(const cv::cuda::GpuMat& src, cv::cuda::GpuMat& dst, const cv::Size& dsize, double fx = 0, double fy = 0, int interpolation = cv::INTER_LINEAR) const = 0;
};

#endif // ICUDA_OPERATION_FACTORY_H