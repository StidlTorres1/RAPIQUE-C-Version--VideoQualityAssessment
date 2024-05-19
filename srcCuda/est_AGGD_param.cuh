#ifndef EST_AGGD_PARAM_CUH
#define EST_AGGD_PARAM_CUH

#include <vector>
#include <cmath>
#include <algorithm>
#include <numeric>
#include <limits>
#include <execution>
#include <future>
#include <iostream>
#include "Logger.h"
#include "Globals.h"

std::pair<float, float> calculateStdDev(const std::vector<double>& vec);
std::vector<double> generateGam();
std::tuple<double, double, double> est_AGGD_param(const std::vector<double>& vec);
#endif