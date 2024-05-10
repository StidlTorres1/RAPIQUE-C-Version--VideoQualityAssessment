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



std::vector<double> nakafit(const std::vector<double>& data);
std::pair<double, double> est_GGD_param(const std::vector<double>& vec);
std::tuple<double, double, double> est_AGGD_param(const std::vector<double>& vec);

cv::Mat createManualGaussianKernel() {
    return (cv::Mat_<float>(7, 7) <<
        0.0002, 0.0010, 0.0030, 0.0043, 0.0030, 0.0010, 0.0002,
        0.0010, 0.0062, 0.0187, 0.0270, 0.0187, 0.0062, 0.0010,
        0.0030, 0.0187, 0.0563, 0.0813, 0.0563, 0.0187, 0.0030,
        0.0043, 0.0270, 0.0813, 0.1174, 0.0813, 0.0270, 0.0043,
        0.0030, 0.0187, 0.0563, 0.0813, 0.0563, 0.0187, 0.0030,
        0.0010, 0.0062, 0.0187, 0.0270, 0.0187, 0.0062, 0.0010,
        0.0002, 0.0010, 0.0030, 0.0043, 0.0030, 0.0010, 0.0002);
}

void circularShift(const cv::Mat& src, cv::Mat& dst, cv::Point shift) {
    int shift_x = (shift.x % src.cols + src.cols) % src.cols;
    int shift_y = (shift.y % src.rows + src.rows) % src.rows;

    cv::Mat extended;
    cv::copyMakeBorder(src, extended, 0, shift_y, 0, shift_x, cv::BORDER_WRAP);
    cv::Rect roi(shift_x, shift_y, src.cols, src.rows);

    dst = extended(roi);
}

bool checkKernelEquivalence(const cv::Mat& cppKernel, const cv::Mat& expectedKernel) {
    cv::Mat diff;
    cv::absdiff(cppKernel, expectedKernel, diff);
    double minVal, maxVal;
    cv::Point minLoc, maxLoc;
    cv::minMaxLoc(diff, &minVal, &maxVal, &minLoc, &maxLoc);
    return maxVal < 1e-5;  // tolerance level for float comparisons
}

cv::cuda::GpuMat applyGaussianFilter(const cv::cuda::GpuMat& src, cv::Ptr<cv::cuda::Filter>& filter) {
    cv::cuda::GpuMat dst;
    filter->apply(src, dst);
    return dst;
}


//3128
std::vector<float> rapique_basic_extractor(const cv::Mat& img) {
    CUDAFilterFactory cudaFactory;

    std::vector<float> ftrs;
    ftrs.reserve(18);

    try {
        const int filtlength = 7;
        cv::Mat window = createManualGaussianKernel(); // Ensure this returns cv::Mat

        // Move data to GPU
        cv::cuda::GpuMat img_gpu(img);
        cv::cuda::GpuMat mu_gpu, sigma_sq_gpu, img_sq_gpu, structdis_gpu;

        cv::Ptr<cv::cuda::Filter> filter = cv::cuda::createLinearFilter(img_gpu.type(), -1, window);

        // Gaussian filtering to compute mu
        mu_gpu = applyGaussianFilter(img_gpu, filter);

        // Compute img_sq in-place and then apply Gaussian filtering to compute sigma_sq
        cv::cuda::multiply(img_gpu, img_gpu, img_sq_gpu);
        sigma_sq_gpu = applyGaussianFilter(img_sq_gpu, filter);

        // Correct calculation of sigma on GPU
        cv::cuda::GpuMat mu_squared_gpu;
        cv::cuda::multiply(mu_gpu, mu_gpu, mu_squared_gpu);  // Element-wise squaring of mu
        cv::cuda::subtract(sigma_sq_gpu, mu_squared_gpu, sigma_sq_gpu);
        cv::cuda::max(sigma_sq_gpu, cv::Scalar(0), sigma_sq_gpu);  // Ensure all values are non-negative
        cv::cuda::sqrt(sigma_sq_gpu, sigma_sq_gpu);
        mu_squared_gpu.release();

        // Structural Disimilarity (structdis) calculation on GPU
        cv::cuda::subtract(img_gpu, mu_gpu, structdis_gpu);
        cv::cuda::GpuMat sigma_plus_one_gpu;
        cv::cuda::add(sigma_sq_gpu, cv::Scalar(1), sigma_plus_one_gpu);  // Add 1 to sigma before division
        cv::cuda::divide(structdis_gpu, sigma_plus_one_gpu, structdis_gpu);
        sigma_plus_one_gpu.release();
        structdis_gpu.convertTo(structdis_gpu, CV_32F);

        // Download final results to host for statistical processing
        cv::Mat structdis, sigma;
        structdis_gpu.download(structdis);
        sigma_sq_gpu.download(sigma);
        structdis.convertTo(structdis, CV_32F);
        sigma.convertTo(sigma, CV_32F);

        //stream.waitForCompletion();

        std::vector<double> vec_struct(structdis.begin<float>(), structdis.end<float>());
        auto [gamparam, sigparam] = est_GGD_param(vec_struct);
        ftrs.push_back(gamparam);
        ftrs.push_back(sigparam);

        std::vector<float> sigmaVec(sigma.begin<float>(), sigma.end<float>());
        std::vector<double> sigmaVec_d(sigmaVec.begin(), sigmaVec.end());
        std::vector<double> sigmaParam = nakafit(sigmaVec_d);
        ftrs.insert(ftrs.end(), sigmaParam.begin(), sigmaParam.end());

        const std::vector<std::pair<int, int>> shifts = { {0, 1}, {1, 0}, {1, 1}, {-1, 1} };
        std::vector<cv::Mat> pairs(shifts.size());
        std::transform(std::execution::par, shifts.begin(), shifts.end(), pairs.begin(), [&structdis](const std::pair<int, int>& shift) {
            cv::Mat shifted_structdis;
            circularShift(structdis, shifted_structdis, cv::Point(shift.first, shift.second));
            return structdis.mul(shifted_structdis);
            });

        std::vector<std::future<std::tuple<float, float, float, float>>> futures;
        for (const auto& pair : pairs) {
            futures.push_back(std::async(std::launch::async, [pair]() -> std::tuple<float, float, float, float> {
                std::vector<double> pairVec(pair.begin<float>(), pair.end<float>());
                auto [alpha, leftstd, rightstd] = est_AGGD_param(pairVec); // Assuming est_AGGD_param correctly returns a tuple<float, float, float, float>
                float meanparam = (rightstd - leftstd) * (std::tgamma(2.0f / alpha) / std::tgamma(1.0f / alpha)) *
                    (std::sqrt(std::tgamma(1.0f / alpha)) / std::sqrt(std::tgamma(3.0f / alpha)));
                return std::make_tuple(alpha, meanparam, leftstd, rightstd);
                }));
        }

        for (auto& future : futures) {
            auto [alpha, meanparam, leftstd, rightstd] = future.get();
            ftrs.push_back(alpha);
            ftrs.push_back(meanparam);
            ftrs.push_back(leftstd);
            ftrs.push_back(rightstd);
        }

        cv::Mat log_struct;
        cv::log(cv::abs(structdis) + 0.1, log_struct);

        std::vector<cv::Mat> shifted_structs(shifts.size());
        for (size_t i = 0; i < shifts.size(); ++i) {
            circularShift(log_struct, shifted_structs[i], cv::Point(shifts[i].first, shifts[i].second));
            cv::Mat structdis_diff = log_struct - shifted_structs[i];

            std::vector<double> structdis_diff_vec(structdis_diff.begin<float>(), structdis_diff.end<float>());
            auto [gamparam_diff, sigparam_diff] = est_GGD_param(structdis_diff_vec);
            ftrs.push_back(gamparam_diff);
            ftrs.push_back(sigparam_diff);
        }

        cv::Mat combined_structdis_diff = log_struct + shifted_structs[2] - shifted_structs[0] - shifted_structs[1];
        combined_structdis_diff.convertTo(combined_structdis_diff, CV_32F);
        std::vector<double> combined_diff_vec(combined_structdis_diff.begin<float>(), combined_structdis_diff.end<float>());
        auto [gamparam_combined, sigparam_combined] = est_GGD_param(combined_diff_vec);
        ftrs.push_back(gamparam_combined);
        ftrs.push_back(sigparam_combined);

        // Additional matrix operations using custom filters
        static const cv::Mat win_tmp_1 = (cv::Mat_<float>(3, 3) << 0, 1, 0, -1, 0, -1, 0, 1, 0);
        static const cv::Mat win_tmp_2 = (cv::Mat_<float>(3, 3) << 1, 0, -1, 0, 0, 0, -1, 0, 1);

        cv::Mat structdis_diff_1, structdis_diff_2;
        cv::filter2D(log_struct, structdis_diff_1, CV_32F, win_tmp_1, cv::Point(-1, -1), 0, cv::BORDER_REPLICATE);
        cv::filter2D(log_struct, structdis_diff_2, CV_32F, win_tmp_2, cv::Point(-1, -1), 0, cv::BORDER_REPLICATE);

        std::vector<double> structdis_diff_1_vec(structdis_diff_1.begin<float>(), structdis_diff_1.end<float>());
        std::vector<double> structdis_diff_2_vec(structdis_diff_2.begin<float>(), structdis_diff_2.end<float>());

        auto [gamparam1, sigparam1] = est_GGD_param(structdis_diff_1_vec);
        auto [gamparam2, sigparam2] = est_GGD_param(structdis_diff_2_vec);

        ftrs.push_back(static_cast<float>(gamparam1));
        ftrs.push_back(static_cast<float>(sigparam1));
        ftrs.push_back(static_cast<float>(gamparam2));
        ftrs.push_back(static_cast<float>(sigparam2));

        // Release GPU resources
        img_gpu.release();
        mu_gpu.release();
        sigma_sq_gpu.release();
        img_sq_gpu.release();
        structdis_gpu.release();
    }
    catch (const std::exception& e) {
        std::cerr << "Error in rapique basic extractor computation: " << e.what() << '\n';
    }

    return ftrs;
}


