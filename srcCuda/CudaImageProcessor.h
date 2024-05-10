// CudaImageProcessor.h
#pragma once
#include "ImageProcessor.h"

class CudaImageProcessor : public ImageProcessor {
public:
    cv::Mat applyFilter(const cv::Mat& img, const cv::Mat& window) override;
    cv::Mat multiply(const cv::Mat& img1, const cv::Mat& img2) override;
    void circularShift(const cv::Mat& src, cv::Mat& dst, cv::Point shift) override;
};