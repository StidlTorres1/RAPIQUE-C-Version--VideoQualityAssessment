// ImageProcessor.h
#pragma once
#include <opencv2/core.hpp>
#include <opencv2/opencv.hpp>

class ImageProcessor {
public:
    virtual cv::Mat applyFilter(const cv::Mat& img, const cv::Mat& window) = 0;
    virtual cv::Mat multiply(const cv::Mat& img1, const cv::Mat& img2) = 0;
    virtual void circularShift(const cv::Mat& src, cv::Mat& dst, cv::Point shift) = 0;
    virtual ~ImageProcessor() {}
};