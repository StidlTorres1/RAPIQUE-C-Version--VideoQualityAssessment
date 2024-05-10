/*std::vector<float> rapique_basic_extractor(const cv::Mat& img) {
    CUDAFilterFactory cudaFactory; // This assumes the use of CUDA filters specifically.

    std::vector<float> ftrs;
    ftrs.reserve(18);

    try {
        const int filtlength = 7;
        const cv::Mat gaussianKernel = cv::getGaussianKernel(filtlength, filtlength / 6.0, CV_32F);
        cv::Mat window = gaussianKernel * gaussianKernel.t();
        window /= cv::sum(window)[0];

        cv::cuda::GpuMat img_gpu(img);
        cv::cuda::GpuMat window_gpu(window);

        cv::cuda::GpuMat mu_gpu, sigma_sq_gpu, img_sq_gpu;

        // Using the created factory to get a filter
        std::unique_ptr<ImageFilter> filter = cudaFactory.createGaussianFilter(window);
        filter->apply(img_gpu, mu_gpu); // Apply the filter to the original image for mu

        cv::cuda::multiply(img_gpu, img_gpu, img_sq_gpu); // Create the squared image on GPU
        filter->apply(img_sq_gpu, sigma_sq_gpu); // Apply the filter to the squared image for sigma squared

        // Download filtered results to CPU Mats.
        cv::Mat mu, sigma_sq;
        mu_gpu.download(mu); // Download mu
        sigma_sq_gpu.download(sigma_sq); // Download sigma squared

        sigma_sq = cv::max(sigma_sq - mu.mul(mu), 0); // Variance
        cv::Mat sigma;
        cv::sqrt(sigma_sq, sigma); // Standard deviation

        cv::Mat structdis = (img - mu) / (sigma + 1);

        std::vector<float> vec_struct(structdis.begin<float>(), structdis.end<float>());
        auto [gamparam, sigparam] = est_GGD_param(vec_struct);
        ftrs.push_back(gamparam);
        ftrs.push_back(sigparam);


        std::vector<double> sigmaVec(sigma.begin<float>(), sigma.end<float>());
        std::vector<double> sigmaParam = nakafit(sigmaVec);
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
            futures.push_back(std::async(std::launch::async, [&pair]() {
                std::vector<float> pairVec(pair.begin<float>(), pair.end<float>());
                auto [alpha, leftstd, rightstd] = est_AGGD_param(pairVec);
                float meanparam = (rightstd - leftstd) * (std::tgamma(2.0 / alpha) / std::tgamma(1.0 / alpha)) * (std::sqrt(std::tgamma(1.0 / alpha)) / std::sqrt(std::tgamma(3.0 / alpha)));
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

            std::vector<float> structdis_diff_vec(structdis_diff.begin<float>(), structdis_diff.end<float>());
            auto [gamparam_diff, sigparam_diff] = est_GGD_param(structdis_diff_vec);
            ftrs.push_back(gamparam_diff);
            ftrs.push_back(sigparam_diff);
        }

        cv::Mat combined_structdis_diff = log_struct + shifted_structs[2] - shifted_structs[0] - shifted_structs[1];
        std::vector<float> combined_diff_vec(combined_structdis_diff.begin<float>(), combined_structdis_diff.end<float>());
        auto [gamparam_combined, sigparam_combined] = est_GGD_param(combined_diff_vec);
        ftrs.push_back(gamparam_combined);
        ftrs.push_back(sigparam_combined);

        static const cv::Mat win_tmp_1 = (cv::Mat_<float>(3, 3) << 0, 1, 0, -1, 0, -1, 0, 1, 0);
        static const cv::Mat win_tmp_2 = (cv::Mat_<float>(3, 3) << 1, 0, -1, 0, 0, 0, -1, 0, 1);

        cv::Mat structdis_diff_1, structdis_diff_2;
        cv::filter2D(log_struct, structdis_diff_1, CV_32F, win_tmp_1, cv::Point(-1, -1), 0, cv::BORDER_REPLICATE);
        cv::filter2D(log_struct, structdis_diff_2, CV_32F, win_tmp_2, cv::Point(-1, -1), 0, cv::BORDER_REPLICATE);

        std::vector<float> structdis_diff_1_vec(structdis_diff_1.begin<float>(), structdis_diff_1.end<float>());
        std::vector<float> structdis_diff_2_vec(structdis_diff_2.begin<float>(), structdis_diff_2.end<float>());

        auto [gamparam1, sigparam1] = est_GGD_param(structdis_diff_1_vec);
        auto [gamparam2, sigparam2] = est_GGD_param(structdis_diff_2_vec);

        ftrs.push_back(gamparam1);
        ftrs.push_back(sigparam1);
        ftrs.push_back(gamparam2);
        ftrs.push_back(sigparam2);
    }
    catch (const std::exception& e) {
        std::cerr << "An error occurred during rapique basic extractor computation: " << e.what() << '\n';
    }

    return ftrs;
}*/