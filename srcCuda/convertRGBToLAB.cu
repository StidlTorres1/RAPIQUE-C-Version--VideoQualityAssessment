#include <opencv2/opencv.hpp>
#include <opencv2/core/ocl.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include "Logger.h"
#include "Globals.h"

#include <opencv2/opencv.hpp>
#include <opencv2/core/cuda.hpp>
#include <opencv2/cudaimgproc.hpp>
#include <opencv2/cudaarithm.hpp>
#include <opencv2/cudafilters.hpp>

cv::Mat convertRGBToLAB(const cv::Mat& inputImage) {
    if (inputImage.empty()) {
        return cv::Mat(); // Ensure the input image is not empty
    }

    // Create a GPU matrix from the input image
    cv::cuda::GpuMat d_inputImage(inputImage);
    cv::cuda::GpuMat d_paddedImage;

    // Apply symmetric padding similar to MATLAB's 'symmetric' option
    int borderSize = 1; // Kernel size is 3, thus border of 1
    cv::cuda::copyMakeBorder(d_inputImage, d_paddedImage, borderSize, borderSize, borderSize, borderSize, cv::BORDER_REFLECT101);
    d_inputImage.release();
    // Apply Gaussian Blur using CUDA
    cv::Ptr<cv::cuda::Filter> gaussianFilter = cv::cuda::createGaussianFilter(d_paddedImage.type(), -1, cv::Size(3, 3), 0.75);
    cv::cuda::GpuMat d_blurredImage;
    gaussianFilter->apply(d_paddedImage, d_blurredImage);
    d_paddedImage.release();

    // Crop the image to remove the effect of padding
    cv::cuda::GpuMat d_croppedImage = d_blurredImage(cv::Rect(borderSize, borderSize, inputImage.cols, inputImage.rows));
    d_blurredImage.release();

    // Convert from BGR to Lab color space using CUDA
    cv::cuda::GpuMat d_labImage;
    cv::cuda::cvtColor(d_croppedImage, d_labImage, cv::COLOR_BGR2Lab);
    d_labImage.release();

    // Convert the LAB image to floating-point format using CUDA
    cv::cuda::GpuMat d_floatLabImage;
    d_labImage.convertTo(d_floatLabImage, CV_32F);
    d_labImage.release();

    // Download the processed image from GPU to host memory
    cv::Mat labImage;
    d_floatLabImage.download(labImage);

    return labImage;
}