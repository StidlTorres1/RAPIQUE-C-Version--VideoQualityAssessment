#include <vector>
#include <cmath>
#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/cudaarithm.hpp>
#include <opencv2/cudafilters.hpp>
#include <opencv2/cudaimgproc.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/cudawarping.hpp>
#include <opencv2/cudaimgproc.hpp>
#include <omp.h>
#include "Logger.h"
#include "Globals.h"
using namespace std;

#include "CudaOps.h"

// Declaration of utility functions
pair<vector<cv::cuda::GpuMat>, vector<cv::cuda::GpuMat>> gen_DoG(const cv::cuda::GpuMat& img, int kband);
vector<float> rapique_basic_extractor(const cv::Mat& src);
cv::cuda::GpuMat convertRGBToLABCUDA(const cv::cuda::GpuMat& I);

vector<float> RAPIQUE_spatial_features(const cv::Mat& RGB) {
    // Check for empty image and return immediately if true
    if (RGB.empty()) {
        std::cerr << "Received empty input image in RAPIQUE_spatial_features." << std::endl;
        return {};
    }

    logger.startTimer(video_name_global, "RAPIQUE_spatial_features");
    vector<float> feats;
    feats.reserve(680); // Assuming 680 features to be extracted

    try {
        // Validate input image is indeed an RGB image
        if (RGB.channels() != 3) {
            throw invalid_argument("The input should be an RGB image");
        }

        auto cudaOps = std::make_shared<CudaOps>();

        cv::cuda::Stream stream;

        const int kscale = 2;
        const int kband = 4;

        cv::cuda::GpuMat d_RGB(RGB), d_Y;
        cudaOps->cvtColor(d_RGB, d_Y, cv::COLOR_BGR2GRAY);
        d_Y.convertTo(d_Y, CV_32F, 1, 0, stream);

        // Sobel filter operations on the GPU for edge detection
        cv::cuda::GpuMat d_GM_X, d_GM_Y;
        auto sobelFilterX = cudaOps->createSobelFilter(CV_32F, CV_32F, 1, 0, 3);
        auto sobelFilterY = cudaOps->createSobelFilter(CV_32F, CV_32F, 0, 1, 3);
        sobelFilterX->apply(d_Y, d_GM_X);
        sobelFilterY->apply(d_Y, d_GM_Y);

        // Compute magnitude of gradients
        cv::cuda::GpuMat d_GM;
        cudaOps->magnitude(d_GM_X, d_GM_Y, d_GM);
        d_GM_X.release();
        d_GM_Y.release();

        cv::Ptr<cv::cuda::Filter> gaussianFilter = cudaOps->createGaussianFilter(CV_32F, -1, cv::Size(9, 9), 1.5);
        cv::cuda::GpuMat d_LOG;
        gaussianFilter->apply(d_Y, d_LOG, stream);

        stream.waitForCompletion();

        cv::cuda::GpuMat d_Y_float;
        d_Y.convertTo(d_Y_float, CV_32F, 1, 0, stream);
        auto [d_gspace_img, d_ksplit_img] = gen_DoG(d_Y_float, kband);

        cv::cuda::GpuMat d_LAB = convertRGBToLABCUDA(d_RGB);
        d_RGB.release();

        cv::cuda::GpuMat d_channels[3];
        cv::cuda::split(d_LAB, d_channels, stream);
        d_LAB.release();

        cv::cuda::GpuMat d_O1, d_O2;
        cv::cuda::addWeighted(d_channels[0], 0.30, d_channels[1], 0.04, 0, d_O1, -1, stream);
        cv::cuda::addWeighted(d_O1, 1.0, d_channels[2], -0.35, 0, d_O1, -1, stream);

        cv::cuda::addWeighted(d_channels[0], 0.34, d_channels[1], -0.60, 0, d_O2, -1, stream);
        cv::cuda::addWeighted(d_O2, 1.0, d_channels[2], 0.17, 0, d_O2, -1, stream);

        auto computeMagnitude = [](const cv::Mat& src) -> cv::Mat {
            cv::cuda::GpuMat d_src(src), d_Ix, d_Iy;
            cv::Ptr<cv::cuda::Filter> filterX = cv::cuda::createSobelFilter(src.type(), -1, 1, 0, 3);
            cv::Ptr<cv::cuda::Filter> filterY = cv::cuda::createSobelFilter(src.type(), -1, 0, 1, 3);
            filterX->apply(d_src, d_Ix);
            filterY->apply(d_src, d_Iy);
            d_Ix.convertTo(d_Ix, CV_32F);
            d_Iy.convertTo(d_Iy, CV_32F);
            cv::cuda::GpuMat d_magnitude;
            cv::cuda::magnitude(d_Ix, d_Iy, d_magnitude);
            cv::Mat magnitude;
            d_magnitude.download(magnitude);
            return magnitude;
            };

        cv::Mat O1, O2, Y, GM, LOG;
        vector<cv::Mat> channels(3);

        d_O1.download(O1);
        d_O2.download(O2);

        for (int i = 0; i < 3; ++i) {
            d_channels[i].download(channels[i]);
        }

        d_Y.download(Y);
        d_GM.download(GM);
        d_LOG.download(LOG);

        d_O1.release();
        d_O2.release();
        d_GM.release();
        d_LOG.release();
        d_Y.release();

        cv::Mat GMO1 = computeMagnitude(O1);
        cv::Mat GMO2 = computeMagnitude(O2);

        vector<cv::Mat> logChannels(3);
#pragma omp parallel for
        for (int i = 0; i < 3; ++i) {
            channels[i].convertTo(channels[i], CV_32F);
            cv::log(channels[i] + 0.1, logChannels[i]);
        }

        cv::Mat BY = (logChannels[0] - cv::mean(logChannels[0])[0] + logChannels[1] - cv::mean(logChannels[1])[0] - 2 * (logChannels[2] - cv::mean(logChannels[2])[0])) / sqrt(6);
        cv::Mat RG = (logChannels[0] - cv::mean(logChannels[0])[0] - (logChannels[1] - cv::mean(logChannels[1])[0])) / sqrt(2);

        cv::Mat GMBY = computeMagnitude(BY);
        cv::Mat GMRG = computeMagnitude(RG);

        cv::Mat GMA = computeMagnitude(channels[1]);
        cv::Mat GMB = computeMagnitude(channels[2]);

        vector<cv::Mat> ksplit_img(d_ksplit_img.size());

        for (size_t i = 0; i < d_ksplit_img.size(); ++i) {
            d_ksplit_img[i].download(ksplit_img[i]);
        }

        vector<cv::Mat> compositeMat = { Y, GM, LOG };
        if (!ksplit_img.empty()) {
            compositeMat.push_back(ksplit_img[0]);
        }
        compositeMat.insert(compositeMat.end(), { O1, O2, GMO1, GMO2, BY, RG, GMBY, GMRG, channels[1], channels[2], GMA, GMB });

        vector<cv::Mat> scaledMats;
        scaledMats.reserve(compositeMat.size() * kscale);

#pragma omp parallel
        {
            vector<cv::Mat> localScaledMats;
            localScaledMats.reserve(compositeMat.size() * kscale);

#pragma omp for nowait
            for (size_t i = 0; i < compositeMat.size(); ++i) {
                const auto& mat = compositeMat[i];
                for (int scale = 1; scale <= kscale; ++scale) {
                    if (i >= 4 && scale == 1) continue;
                    cv::cuda::GpuMat d_mat(mat), d_y_scale;
                    double scale_factor = pow(2, -(scale - 1));
                    int new_cols = cvRound(mat.cols * scale_factor);
                    int new_rows = cvRound(mat.rows * scale_factor);
                    cudaOps->resize(d_mat, d_y_scale, cv::Size(new_cols, new_rows), 0, 0, cv::INTER_CUBIC);

                    cv::Mat y_scale;
                    d_y_scale.download(y_scale);
                    localScaledMats.push_back(move(y_scale));
                }
            }

#pragma omp critical
            scaledMats.insert(scaledMats.end(), localScaledMats.begin(), localScaledMats.end());
        }

#pragma omp parallel
        {
            vector<float> localFeats;
            localFeats.reserve(680);

#pragma omp for nowait
            for (size_t idx = 0; idx < scaledMats.size(); ++idx) {
                vector<float> chFeats = rapique_basic_extractor(scaledMats[idx]);
                localFeats.insert(localFeats.end(), chFeats.begin(), chFeats.end());
            }

#pragma omp critical
            feats.insert(feats.end(), localFeats.begin(), localFeats.end());
        }
        logger.stopTimer(video_name_global, "RAPIQUE_spatial_features");
        d_Y.release();
        d_GM_X.release();
        d_GM_Y.release();
        d_GM.release();
        d_LOG.release();
        return feats;
    }
    catch (const std::exception& e) {
        std::cerr << "An error occurred during rapique spatial features computation: " << e.what() << '\n';
    }
    return feats;
}

cv::cuda::GpuMat convertRGBToLABCUDA(const cv::cuda::GpuMat& d_I) {
    cv::cuda::GpuMat d_LAB;
    cv::cuda::cvtColor(d_I, d_LAB, cv::COLOR_BGR2Lab, 0);
    cv::cuda::GpuMat d_LAB_float;
    d_LAB.convertTo(d_LAB_float, CV_32F, 1.0, 0.0);
    return d_LAB_float;
}
