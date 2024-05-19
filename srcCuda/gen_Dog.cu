#include <vector>
#include <cmath>
#include <opencv2/opencv.hpp>
#include <opencv2/cudaarithm.hpp>
#include <opencv2/cudafilters.hpp>
#include "Logger.h"
#include "Globals.h"

using namespace std;

pair<vector<cv::cuda::GpuMat>, vector<cv::cuda::GpuMat>> gen_DoG(const cv::cuda::GpuMat& d_img, int kband) {
    if (d_img.empty()) {
        throw invalid_argument("Input image is empty.");
    }
    if (kband <= 0) {
        throw invalid_argument("kband must be positive.");
    }

    logger.startTimer(video_name_global, "gen_DoG");
    constexpr double kval = 1.6;
    vector<cv::cuda::GpuMat> gspace_img(kband);
    vector<cv::cuda::GpuMat> ksplit_img(kband);
    vector<double> sigmas(kband);
    vector<int> wsizes(kband);

    gspace_img[0] = d_img.clone(); // Store the original image for the output

    try {
        // Pre-calculate sigmas and window sizes
        for (int band = 1; band < kband; ++band) {
            sigmas[band] = pow(kval, band - 2);
            int ws = static_cast<int>(ceil(2 * (3 * sigmas[band] + 1)));
            wsizes[band] = ws + (ws % 2 == 0 ? 1 : 0);
        }

        // Parallel Gaussian Blur using CUDA
        for (int band = 1; band < kband; ++band) {
            cv::cuda::GpuMat d_blurred;
            auto filter = cv::cuda::createGaussianFilter(d_img.type(), -1, cv::Size(wsizes[band], wsizes[band]), sigmas[band], sigmas[band], cv::BORDER_REPLICATE);
            filter->apply(d_img, d_blurred);
            gspace_img[band] = d_blurred;
        }

        // Parallel Subtraction using CUDA
        for (int band = 0; band < kband - 1; ++band) {
            cv::cuda::GpuMat d_result;
            cv::cuda::subtract(gspace_img[band], gspace_img[band + 1], d_result, cv::noArray(), -1);
            ksplit_img[band] = d_result;
        }
        ksplit_img[kband - 1] = gspace_img[kband - 1].clone();

        logger.stopTimer(video_name_global, "gen_DoG");
        return { gspace_img, ksplit_img };
    }
    catch (const std::exception& e) {
        std::cerr << "An error occurred during DoG computation: " << e.what() << '\n';
        throw;
    }
}