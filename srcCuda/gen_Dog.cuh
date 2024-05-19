#ifndef GEN_DOG_CUH
#define GEN_DOG_CUH
#include <vector>
#include <cmath>
#include <opencv2/opencv.hpp>
#include <opencv2/cudaarithm.hpp>
#include <opencv2/cudafilters.hpp>
#include "Logger.h"
#include "Globals.h"
using namespace std;
pair<vector<cv::cuda::GpuMat>, vector<cv::cuda::GpuMat>> gen_DoG(const cv::cuda::GpuMat& d_img, int kband);
#endif