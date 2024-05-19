#ifndef EST_GGD_PARAM_CUH
#define EST_GGD_PARAM_CUH
#include <vector>
#include <cmath>
#include <numeric>
#include <algorithm>
#include <execution>
#include "Logger.h"
#include "Globals.h"
using namespace std;

std::pair<double, double> est_GGD_param(const std::vector<double>& vec);

#endif
