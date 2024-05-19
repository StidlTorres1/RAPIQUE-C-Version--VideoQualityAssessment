#ifndef CALC_RAPIQUE_RAPIQUE_FEATURES_H
#define CALC_RAPIQUE_RAPIQUE_FEATURES_H

#include <vector>
#include <string>
#include <cmath> 
#include <fstream>
#include <opencv2/opencv.hpp>
#include <opencv2/core/ocl.hpp>
#include <cstdio>
#include <algorithm>
#include <execution>
#include <mutex>
#include <torch/script.h> 
#include <iostream>
#include <memory>
#include <iomanip>

#include "ImageReaderFactory.h"
#include "Logger.h"
#include "Globals.h"

#include <opencv2/core/core.hpp>
#include <opencv2/cudaarithm.hpp>
#include <opencv2/cudafilters.hpp>
#include <opencv2/cudaimgproc.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/cudawarping.hpp>
#include <opencv2/cudaimgproc.hpp> 

using namespace std;

extern std::mutex mtx;

torch::jit::Module loadModel(const std::string& modelPath);

std::vector<float> loadWfun();

std::vector<float> rapique_basic_extractor(const cv::Mat& src);

void process_channel(int ch, int kscale, const std::vector<cv::Mat>& dpt_filt_frames, float ratio, std::vector<std::vector<float>>& feats_tmp_wpt_global);

std::vector<float> RAPIQUE_spatial_features(const cv::Mat& RGB);

std::vector<vector<float>> calc_RAPIQUE_features(const std::string& yuv_name, int width, int height, int framerate, float minside, const string& net, const string& layer, int log_level);

#endif // CALC_RAPIQUE_RAPIQUE_FEATURES_H