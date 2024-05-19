#ifndef	RAPIQUE_SPATIAL_FEATURES_CUH
#define RAPIQUE_SPATIAL_FEATURES_CUH
#include <vector>
#include <cmath>
#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/cudaarithm.hpp>
#include <opencv2/cudafilters.hpp>
#include <opencv2/cudaimgproc.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/cudawarping.hpp>
#include <opencv2/cudaimgproc.hpp> // Include for cuda::cvtColor functionality
#include <omp.h>
#include "Logger.h"
#include "Globals.h"
using namespace std;


vector<float> RAPIQUE_spatial_features(const cv::Mat& RGB);
cv::cuda::GpuMat convertRGBToLABCUDA(const cv::cuda::GpuMat& d_I);
#endif