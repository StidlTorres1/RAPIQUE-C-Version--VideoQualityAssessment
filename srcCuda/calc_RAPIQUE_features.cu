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
std::mutex mtx;

torch::jit::Module loadModel(const std::string& modelPath) {
	torch::jit::Module module;
	torch::Device device(torch::kCUDA);
	try {
		std::cout << "Loading model\n";
		module = torch::jit::load(modelPath);
		std::cout << "Model loaded\n";
	}
	catch (const c10::Error& e) {
		std::cerr << "error loading the model\n";
		exit(-1); 
	}
	return module;
}

std::vector<float> loadWfun() {
	return std::vector<float>{
		1, 1, 1, 1, -1, -1, -1, -1,
			1, 1, -1, -1, 1, 1, -1, -1,
			1, 1, -1, -1, -1, -1, 1, 1,
			1, -1, 1, -1, 1, -1, 1, -1,
			1, -1, 1, -1, -1, 1, -1, 1,
			1, -1, -1, 1, 1, -1, -1, 1,
			
			1, -1, -1, 1, -1, 1, 1, -1
	};
}

vector<float> rapique_basic_extractor(const cv::Mat& src);
void process_channel(int ch, int kscale, const std::vector<cv::Mat>& dpt_filt_frames, float ratio, std::vector<std::vector<float>>& feats_tmp_wpt_global) {
	std::vector<std::vector<float>> feats_tmp_wpt_local;

	cv::Mat feat_map;
	if (ratio < 1) {
		cv::resize(dpt_filt_frames[ch], feat_map, cv::Size(), ratio, ratio, cv::INTER_AREA);
	}
	else {
		feat_map = dpt_filt_frames[ch];
	}

	for (int scale = 1; scale <= kscale; ++scale) {
		cv::Mat y_scale;
		if (scale > 1) {
			float factor = std::pow(2.0, -(scale - 1));
			cv::resize(feat_map, y_scale, cv::Size(), factor, factor, cv::INTER_AREA);
		}
		else {
			y_scale = feat_map;
		}

		auto features = rapique_basic_extractor(y_scale);
		feats_tmp_wpt_local.push_back(features);
	}

	std::lock_guard<std::mutex> lock(mtx);
	feats_tmp_wpt_global.insert(feats_tmp_wpt_global.end(), feats_tmp_wpt_local.begin(), feats_tmp_wpt_local.end());
}
vector<float> RAPIQUE_spatial_features(const cv::Mat& RGB);
vector<vector<float>> calc_RAPIQUE_features(const std::string& yuv_name, int width, int height,
    int framerate, float minside, const string& net, const string& layer, int log_level) {
    logger.startTimer(video_name_global, "calc_RAPIQUE_features"); // entry is name of the video file
    vector<vector<float>> feats_frames;

    try{
        bool modelLoaded = false;
        torch::jit::Module module;
        string modelPath = "../pytorch/traced_resnet50_avg_pool.pt";

        // Replaced direct YUV file handling with ImageReader abstract class
        auto imageReader = ImageReaderFactory::createImageReader("YUV");
        if (!imageReader) {
            cerr << "Error creating ImageReader instance.\n";
            return feats_frames;
        }

        // Use ImageReader to get the number of frames instead of manual file check
        ifstream test_file(yuv_name, ios::binary | ios::ate);
        if (!test_file.is_open()) {
            cerr << "Test YUV file not found.\n";
            return feats_frames;
        }
        streamsize file_length = test_file.tellg();
        test_file.close(); // Close the file as it's no longer needed directly

        int nb_frames = static_cast<int>(floor(file_length / (width * height * 1.5)));
        int half_framerate = framerate / 2;
        int third_framerate = framerate / 3;

        feats_frames.reserve(nb_frames * 2);

        vector<tuple<cv::Mat, cv::Mat, cv::Mat, int>> frame_triplets;
        frame_triplets.reserve(nb_frames);
        for (int fr = half_framerate; fr < nb_frames - 2; fr += framerate) {
            int calculatedFrame = max(1, fr - third_framerate);
            int frameIndex = min(nb_frames - 2, fr + third_framerate);

            frame_triplets.emplace_back(imageReader->readImage(yuv_name, width, height, fr),
                imageReader->readImage(yuv_name, width, height, calculatedFrame),
                imageReader->readImage(yuv_name, width, height, frameIndex), fr);
        }

        mutex mtx;
        for_each(std::execution::par, frame_triplets.begin(), frame_triplets.end(),
            [&]( tuple<cv::Mat, cv::Mat, cv::Mat, int>& frames) {
                 auto& [this_YUV_frame, prev_YUV_frame, next_YUV_frame, fr] = frames;

                // Check for empty frames is retained from your original logic
                if (this_YUV_frame.empty() || prev_YUV_frame.empty() || next_YUV_frame.empty()) {
                    cerr << "Error: One or more YUV frames are empty.\n";
                    return;
                }

                cv::Mat this_rgb, prev_rgb, next_rgb;
                cv::cvtColor(this_YUV_frame, this_rgb, cv::COLOR_YUV2BGR);
                cv::cvtColor(prev_YUV_frame, prev_rgb, cv::COLOR_YUV2BGR);
                cv::cvtColor(next_YUV_frame, next_rgb, cv::COLOR_YUV2BGR);

                this_YUV_frame.release();
                prev_YUV_frame.release();
                next_YUV_frame.release();

                // Resizing logic retains your original approach to adjusting frame size
                float sside = min(this_rgb.rows, this_rgb.cols);
                float ratio = minside / sside;
                if (ratio < 1) {
                    cv::resize(prev_rgb, prev_rgb, cv::Size(), ratio, ratio, cv::INTER_CUBIC);
                    cv::resize(next_rgb, next_rgb, cv::Size(), ratio, ratio, cv::INTER_CUBIC);
                }

                cv::cuda::Stream stream;

                vector<float> feats_per_frame;
                vector<float> prev_feats_spt = RAPIQUE_spatial_features(prev_rgb);
                vector<float> next_feats_spt = RAPIQUE_spatial_features(next_rgb);

                auto n_features = prev_feats_spt.size();
                vector<float> feats_spt_mean(n_features);
                vector<float> feats_spt_diff(n_features);

                transform(std::execution::par, prev_feats_spt.begin(), prev_feats_spt.end(), next_feats_spt.begin(),
                    feats_spt_mean.begin(), [](float a, float b) { return (a + b) / 2.0; });

                transform(std::execution::par, prev_feats_spt.begin(), prev_feats_spt.end(), next_feats_spt.begin(),
                    feats_spt_diff.begin(), [](float a, float b) { return abs(a - b); });

                lock_guard<mutex> guard(mtx);
                feats_per_frame.insert(feats_per_frame.end(), feats_spt_mean.begin(), feats_spt_mean.end());
                feats_per_frame.insert(feats_per_frame.end(), feats_spt_diff.begin(), feats_spt_diff.end());
                logger.startTimer(video_name_global, "calc_RAPIQUE_features/deep_learning"); // calc_RAPIQUE_features/deep_learning
                if (!modelLoaded) {
                    module = loadModel(modelPath);
                    modelLoaded = true;
                }

                cv::cuda::GpuMat d_image;
                d_image.upload(this_rgb);  // Upload to GPU memory

                // Resize image
                cv::cuda::resize(d_image, d_image, cv::Size(224, 224));

                // Convert color
                cv::cuda::cvtColor(d_image, d_image, cv::COLOR_BGR2RGB);

                // Convert to float and scale
                d_image.convertTo(d_image, CV_32F, 1.0 / 255);

                // Download from GPU to CPU
                cv::Mat image;
                d_image.download(image);  // Download to CPU memory
                d_image.release();

                // Continue with tensor operations on CPU
                auto img_tensor = torch::from_blob(image.data, { 1, 224, 224, 3 }, torch::kF32);
                img_tensor = img_tensor.permute({ 0, 3, 1, 2 });

                torch::NoGradGuard no_grad;
                auto output = module.forward({ img_tensor }).toTensor();

                output = output.squeeze();
                auto flattened_output = output.mean({ 1, 2 });
                auto feats = flattened_output.accessor<float, 1>();

                for (int i = 0; i < feats.size(0); ++i) {
                    feats_per_frame.push_back(static_cast<float>(feats[i]));
                }
                logger.stopTimer(video_name_global, "calc_RAPIQUE_features/deep_learning");// calc_RAPIQUE_features/deep_learning end
                logger.startTimer(video_name_global, "calc_RAPIQUE_features/temporal NSS");// calc_RAPIQUE_features/temporal NSS init
                std::vector<float> wfun = loadWfun();
                const int numRows = 7;

                int depth = wfun.size() / numRows;
                std::vector<cv::Mat> frames_wpt(depth, cv::Mat::zeros(prev_rgb.rows, prev_rgb.cols, CV_32FC1));

                int fr_idx_start = std::max(1, fr - static_cast<int>(std::floor(depth / 2.0)));
                int fr_idx_end = std::min(nb_frames - 3, fr_idx_start + depth - 1);

                int fr_wpt_cnt = 0;
                for (int fr_wpt = fr_idx_start; fr_wpt <= fr_idx_end; ++fr_wpt, ++fr_wpt_cnt) {
                    cv::Mat YUV_tmp = imageReader->readImage(yuv_name, width, height, fr_wpt);
                    cv::Mat processedFrame;
                    if (ratio < 1) {
                        cv::resize(YUV_tmp, processedFrame, cv::Size(), ratio, ratio);
                    }
                    else {
                        processedFrame = YUV_tmp;
                    }

                    if (fr_wpt_cnt < frames_wpt.size()) {
                        frames_wpt[fr_wpt_cnt] = processedFrame;
                    }
                }

                std::vector<std::vector<float>> wfunM = {
                    {1, 1, 1, 1, -1, -1, -1, -1},
                    {1, 1, -1, -1, 1, 1, -1, -1},
                    {1, 1, -1, -1, -1, -1, 1, 1},
                    {1, -1, 1, -1, 1, -1, 1, -1},
                    {1, -1, 1, -1, -1, 1, -1, 1},
                    {1, -1, -1, 1, 1, -1, -1, 1},
                    {1, -1, -1, 1, -1, 1, 1, -1}
                };
                std::vector<cv::Mat> processed_frames_wpt(frames_wpt.size());
                std::vector<cv::Mat> dpt_filt_frames(wfunM.size());

                for (size_t idx = 0; idx < frames_wpt.size(); ++idx) {
                    if (frames_wpt[idx].channels() > 1) {
                        cv::cvtColor(frames_wpt[idx], processed_frames_wpt[idx], cv::COLOR_BGR2GRAY);
                        processed_frames_wpt[idx].convertTo(processed_frames_wpt[idx], CV_32FC1);
                    }
                    else {
                        frames_wpt[idx].convertTo(processed_frames_wpt[idx], CV_32FC1);
                    }
                }

                cv::parallel_for_(cv::Range(0, wfunM.size()), [&](const cv::Range& range) {
                    for (int freq = range.start; freq < range.end; ++freq) {
                        cv::Mat sum_frame = cv::Mat::zeros(prev_rgb.rows, prev_rgb.cols, CV_32FC1);

                        for (size_t idx = 0; idx < processed_frames_wpt.size(); ++idx) {
                            sum_frame += processed_frames_wpt[idx] * wfun[freq];
                        }

                        dpt_filt_frames[freq] = sum_frame;
                    }
                    });

                int kscale = 2;
                vector<vector<float>> feats_tmp_wpt_global;

                cv::parallel_for_(cv::Range(0, dpt_filt_frames.size()), [&](const cv::Range& range) {
                    for (int ch = range.start; ch < range.end; ++ch) {
                        process_channel(ch, kscale, dpt_filt_frames, ratio, feats_tmp_wpt_global);
                    }
                    });

                vector<float> merged_feats;
                for (const auto& tmp_feats : feats_tmp_wpt_global) {
                    merged_feats.insert(merged_feats.end(), tmp_feats.begin(), tmp_feats.end());
                }

                feats_per_frame.insert(feats_per_frame.end(), merged_feats.begin(), merged_feats.end());
                feats_frames.push_back(feats_per_frame);

                stream.waitForCompletion();

                // Explicitly release GPU mats after processing
                this_rgb.release();
                prev_rgb.release();
                next_rgb.release();


            });
            logger.stopTimer(video_name_global, "calc_RAPIQUE_features/temporal NSS"); // calc_RAPIQUE_features/temporal NSS end

            logger.stopTimer(video_name_global, "calc_RAPIQUE_features");
            return feats_frames;
    }
    catch (const std::exception& e) {
        std::cerr << "An error occurred during feature calculation: " << e.what() << '\n';
        // Potentially rethrow or handle more specific exceptions here
        logger.stopTimer(video_name_global, "calc_RAPIQUE_features");
        throw;  // Rethrow the exception if you need to propagate it
    }
}
//Documentation
// Extracting and processing features from YUV video frames for video quality assessment. It uses OpenCV for image processing, along with other standard libraries for file and stream operations. Line by line:
// 1-8. Include statements:
// •	These lines include necessary headers for vector operations, string manipulation, mathematical functions, file streaming, OpenCV functionalities, OpenCL interface for GPU optimizations, C standard I/O, algorithm functions, execution policies for parallel algorithms, and mutex for thread safety.
// 9-11. Function declarations:
// •	Declares three functions YUVread, RAPIQUE_spatial_features, and calc_RAPIQUE_features that are defined elsewhere or later in the code.
// 12-76. Function calc_RAPIQUE_features:
// •	This function calculates RAPIQUE (Rapid and Accurate Image Quality Evaluator) features from a given YUV file.
// 13-17. File handling and initial checks:
// •	Opens a YUV file and checks if it's open. If not, it outputs an error message and returns an empty feature vector.
// 18-22. Frame number calculation:
// •	Calculates the number of frames in the YUV file based on its size and the dimensions of each frame.
// 23-27. Frame rate processing:
// •	Computes half_framerate and third_framerate for later use in determining which frames to process.
// 28-37. Frame triplet preparation:
// •	Reserves space for frame triplets and populates them by reading specific frames from the YUV file. It uses the YUVread function and adjusts frame indices based on the frame rate.
// 38.	Mutex declaration:
// •	Declares a mutex for thread safety during parallel processing.
// 39-75. Parallel processing of frames:
// •	Processes the frame triplets in parallel using for_each with execution::par policy.
// •	Converts YUV frames to RGB.
// •	Resizes the frames if necessary based on the minimum side length (minside) and aspect ratio.
// •	Extracts spatial features from previous and next frames using RAPIQUE_spatial_features.
// •	Calculates the mean and difference of features between the previous and next frames.
// •	Uses a mutex to safely add these features to the overall feature vector feats_frames.
// 77-83. XML file output:
// •	Writes the features to an XML file named "feat_frames.xml".
// •	Outputs a success message upon saving the file.
// 84.	Return statement:
// •	Returns the calculated features.
// This function is a comprehensive implementation for feature extraction from video frames, tailored for video quality assessment. It leverages parallel processing to efficiently handle multiple frames and computes spatial features for pairs of frames, which are likely used to assess temporal changes and overall video quality. The use of mutexes ensures thread safety during parallel execution. The features are then saved in an XML format for further use or analysis.
