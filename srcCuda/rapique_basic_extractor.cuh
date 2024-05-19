#ifndef	RAPIQUE_BASIC_EXTRACTOR
#define RAPIQUE_BASIC_EXTRACTOR
#include <vector>
#include <numeric>
#include <cmath>
#include <iostream>
#include <opencv2/opencv.hpp>
#include <opencv2/core/ocl.hpp>
#include <opencv2/cudaarithm.hpp>
#include <opencv2/cudafilters.hpp>
#include <execution>
#include <future>

#include "FilterFactory.h"
#include "CUDAFilterFactory.h"

using namespace std;
cv::Mat createManualGaussianKernel();
void circularShift(const cv::Mat& src, cv::Mat& dst, cv::Point shift);
bool checkKernelEquivalence(const cv::Mat& cppKernel, const cv::Mat& expectedKernel);
cv::cuda::GpuMat applyGaussianFilter(const cv::cuda::GpuMat& src, cv::Ptr<cv::cuda::Filter>& filter);
std::vector<float> rapique_basic_extractor(const cv::Mat& img);


#endif