#include <iostream>
#include <vector>
#include <fstream>
#include <string>
#include <filesystem>
#include <opencv2/opencv.hpp>
#include <opencv2/core/ocl.hpp>
#include <chrono>
#include "Timer.h" // Include the Timer class definition
#include "Globals.h" // Include the global variables definition
#include "Logger.h" // Include the logger functions definition
#include <vector>
#include <iostream>
#include <opencv2/opencv.hpp>
#include <cuda_runtime.h>


__global__ void copyFeatsToMat(float* featsFramesData, float* featsFramesMatData, int rows, int cols) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int row = idx / cols;
    int col = idx % cols;
    if (row < rows && col < cols) {
        featsFramesMatData[row * cols + col] = featsFramesData[row * cols + col];
    }
}

__global__ void averageColumns(float* input, float* output, int rows, int cols) {
    int col = threadIdx.x + blockIdx.x * blockDim.x;
    if (col < cols) {
        float sum = 0;
        for (int row = 0; row < rows; ++row) {
            sum += input[row * cols + col];
        }
        output[col] = sum / rows;
    }
}

// Manually flatten the nested vector
std::vector<float> flatten(const std::vector<std::vector<float>>& vec) {
    std::vector<float> flat;
    for (const auto& subVec : vec) {
        flat.insert(flat.end(), subVec.begin(), subVec.end());
    }
    return flat;
}


using namespace std::chrono;

// Include libraries for file handling, image processing, and measuring execution time.

// Declare a function to calculate the RAPIQUE features from a video file.
std::vector<std::vector<float>> calc_RAPIQUE_features(const std::string& yuv_name, int width, int height,
    int framerate, float minside, const std::string& net,
    const std::string& layer, int log_level);

// Define a structure to hold video data information.
struct DataRow {
    long long flickr_id;
    float mos;
    int width;
    int height;
    std::string pixfmt;
    float framerate;
    int nb_frames;
    int bitdepth;
    int bitrate;

    // Constructor to parse a CSV line into a DataRow object.
    DataRow(const std::string& line) {
        std::istringstream iss(line);
        std::string token;
        std::getline(iss, token, ','); flickr_id = std::stoll(token);
        std::getline(iss, token, ','); mos = std::stod(token);
        std::getline(iss, token, ','); width = std::stoi(token);
        std::getline(iss, token, ','); height = std::stoi(token);
        std::getline(iss, token, ','); pixfmt = token;
        std::getline(iss, token, ','); framerate = std::stod(token);
        std::getline(iss, token, ','); nb_frames = std::stoi(token);
        std::getline(iss, token, ','); bitdepth = std::stoi(token);
        std::getline(iss, token, ','); bitrate = std::stoi(token);
    }
};

// Write the features to an XML file.
void writeXML(const std::string& filename, const std::vector<std::vector<float>>& feats_frames) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error opening the file for writing.\n";
        return;
    }

    file << "<?xml version=\"1.0\"?>" << std::endl
        << "<opencv_storage>" << std::endl
        << "<FeatFrames type_id=\"opencv-matrix\">" << std::endl
        << "<rows>" << feats_frames.size() << "</rows>" << std::endl
        << "<cols>" << feats_frames[0].size() << "</cols>" << std::endl
        << "<dt>" << "d" << "</dt>" << std::endl
        << "<data>" << std::endl;
    file << std::fixed << std::setprecision(17);
    for (const auto& row : feats_frames) {
        for (const auto& elem : row) {
            file << elem << " ";
        }
        file << std::endl;
    }
    file << "</data>" << std::endl
        << "</FeatFrames>" << std::endl
        << "</opencv_storage>" << std::endl;
    file.close();
}

// Main function to process videos and compute features.
int main_RAPIQUEE() {
    logger.startTimer("RAPIQUE-Main", "demo_compute_RAPIQUE_feats");//  demo_compute_RAPIQUE_feats starts
    Timer timer;
    // Enable GPU support if available.
    if (cv::ocl::haveOpenCL()) {
        cv::ocl::setUseOpenCL(true);
        std::cout << "OpenCL support detected. Using GPU..." << std::endl;
    }
    else {
        std::cout << "OpenCL support not detected. Using CPU..." << std::endl;
    }

    // Configure paths based on operating system.
    const std::string path_separator =
#ifdef _WIN32
        "\\";
#else
        "/";
#endif

    // Define basic parameters for the process.
    const std::string algo_name = "RAPIQUE";
    const std::string data_name = "KONVID_1K";
    const bool write_file = true;
    std::filesystem::path currentPath = std::filesystem::current_path();
    std::filesystem::path desiredPath = currentPath.parent_path();
    std::string root_path = desiredPath.string() + path_separator + "dataBase" + path_separator;
    std::string root_path_data = root_path + data_name + path_separator;
    std::string data_path = root_path_data;
    std::string filelist_csv = root_path + "mos_files" + path_separator + "KONVID_1K_1test_metadata.csv";

    // Read video file metadata.
    std::vector<DataRow> filelist;
    std::ifstream inFile(filelist_csv);
    if (inFile.is_open()) {
        std::string line;
        std::getline(inFile, line); // Skip the header line.
        while (std::getline(inFile, line)) {
            try {
                filelist.push_back(DataRow(line));
            }
            catch (const std::exception& e) {
                std::cerr << "Error processing line: " << line << ". Cause: " << e.what() << std::endl;
            }
        }
        inFile.close();
    }
    else {
        std::cerr << "Unable to open file " << filelist_csv << std::endl;
    }

    // Create directories for output if they do not exist.
    std::string out_path = root_path + "feat_files";
    std::string out_path_temp = root_path + "tmp";
    if (!std::filesystem::exists(out_path)) {
        std::filesystem::create_directory(out_path);
    }
    if (!std::filesystem::exists(out_path_temp)) {
        std::filesystem::create_directory(out_path_temp);
    }

    std::vector<std::vector<float>> feats_mat(filelist.size());
    int h = 0;
    for (const auto& entry : filelist) {
        timer.start();
        std::cout << "\n\n ----------->Computing features for " << entry.flickr_id << " sequence\n";
        std::string video_name = data_path + path_separator + std::to_string(entry.flickr_id) + ".mp4";
        std::string yuv_name = out_path_temp + path_separator + std::to_string(entry.flickr_id) + ".yuv";
        std::string cmd = "ffmpeg -loglevel error -y -i " + video_name + " -pix_fmt yuv420p -vsync 0 " + yuv_name;
        system(cmd.c_str());

        std::vector<std::vector<float>> feats_frames = calc_RAPIQUE_features(yuv_name, entry.width, entry.height,
            std::round(entry.framerate), 512.0f, "resnet50", "avg_pool", 0);

        std::vector<float> flat_feats_frames = flatten(feats_frames);
        int numElements = flat_feats_frames.size();
        float* d_featsFrames;
        float* d_featsFramesMat;

        cudaError_t allocStatus;

        // Allocate memory for d_featsFrames
        allocStatus = cudaMalloc(&d_featsFrames, numElements * sizeof(float));
        if (allocStatus != cudaSuccess) {
            std::cerr << "CUDA error: Failed to allocate d_featsFrames: " << cudaGetErrorString(allocStatus) << std::endl;
            continue; // Skip to the next iteration of the loop
        }

        // Copy host memory to device
        cudaMemcpy(d_featsFrames, flat_feats_frames.data(), numElements * sizeof(float), cudaMemcpyHostToDevice);

        // Allocate memory for d_featsFramesMat
        allocStatus = cudaMalloc(&d_featsFramesMat, numElements * sizeof(float)); // Correcting the missing allocation
        if (allocStatus != cudaSuccess) {
            std::cerr << "CUDA error: Failed to allocate d_featsFramesMat: " << cudaGetErrorString(allocStatus) << std::endl;
            cudaFree(d_featsFrames); // Free previously allocated memory before continuing
            continue; // Skip to the next iteration of the loop
        }

        dim3 blockSize(256);
        dim3 gridSize((numElements + blockSize.x - 1) / blockSize.x);

        // Now that d_featsFramesMat is properly allocated, call the kernel
        copyFeatsToMat << <gridSize, blockSize >> > (d_featsFrames, d_featsFramesMat, feats_frames.size(), feats_frames[0].size());
        cudaDeviceSynchronize();

        float* d_meanMat;
        cudaMalloc(&d_meanMat, feats_frames[0].size() * sizeof(float));
        averageColumns << <gridSize, blockSize >> > (d_featsFramesMat, d_meanMat, feats_frames.size(), feats_frames[0].size());
        cudaDeviceSynchronize();

        std::vector<float> meanMat(feats_frames[0].size());
        cudaMemcpy(meanMat.data(), d_meanMat, feats_frames[0].size() * sizeof(float), cudaMemcpyDeviceToHost);

        if (h < feats_mat.size()) {
            feats_mat[h].resize(meanMat.size());
            for (int col = 0; col < meanMat.size(); ++col) {
                feats_mat[h][col] = meanMat[col];
            }
        }

        cudaFree(d_featsFrames);
        cudaFree(d_featsFramesMat);
        cudaFree(d_meanMat);

        std::remove(yuv_name.c_str());
        if (write_file) {
            writeXML(out_path + path_separator + data_name + "_" + algo_name + "_feats.xml", feats_mat);
            std::cout << "XML file saved." << std::endl;
            std::cout << "Features processed: " << feats_frames.size() << std::endl;
            std::cout << "Features dimensions: " << feats_frames[0].size() << std::endl;
        }
        float time = timer.elapsed();
        std::cout << "The code was executed in: " << time << " seconds." << std::endl;
        h++;
    }


    logger.stopTimer("RAPIQUE-Main", "demo_compute_RAPIQUE_feats");//  demo_compute_RAPIQUE_feats end
    logger.writeXML();
    return 0;
}