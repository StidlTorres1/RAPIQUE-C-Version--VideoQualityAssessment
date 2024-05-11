#include <iostream>
#include <vector>
#include <fstream>
#include <string>
#include <filesystem>
#include <opencv2/opencv.hpp>
#include <opencv2/core/ocl.hpp>
#include <chrono>
#include "Timer.h"
#include "Globals.h"
#include "Logger.h"
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

std::vector<float> flatten(const std::vector<std::vector<float>>& vec) {
    std::vector<float> flat;
    for (const auto& subVec : vec) {
        flat.insert(flat.end(), subVec.begin(), subVec.end());
    }
    return flat;
}

using namespace std::chrono;

std::vector<std::vector<float>> calc_RAPIQUE_features(const std::string& yuv_name, int width, int height,
    int framerate, float minside, const std::string& net,
    const std::string& layer, int log_level);

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

int main_RAPIQUEE() {
    logger.startTimer("RAPIQUE-Main", "demo_compute_RAPIQUE_feats");
    Timer timer;
    if (cv::ocl::haveOpenCL()) {
        cv::ocl::setUseOpenCL(true);
        std::cout << "OpenCL support detected. Using GPU..." << std::endl;
    }
    else {
        std::cout << "OpenCL support not detected. Using CPU..." << std::endl;
    }

    std::cout << "Current Working Directory: " << std::filesystem::current_path() << std::endl;


    const std::string path_separator = "\\";
    const std::string dataBase_path = "dataBase";
    const std::string featureFrames_output_path = "output";

    std::string filelist_csv = "mos_file.csv";

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

    if (!std::filesystem::exists(featureFrames_output_path)) {
        std::filesystem::create_directory(featureFrames_output_path);
    }

    std::vector<std::vector<float>> feats_mat(filelist.size());

    // Using a loop index to safely access and modify feats_mat
    for (size_t index = 0; index < filelist.size(); ++index) {
        const auto& entry = filelist[index];
        timer.start();
        std::cout << "\n\n ----------->Computing features for " << entry.flickr_id << " sequence\n";
        std::string video_name = dataBase_path + path_separator + std::to_string(entry.flickr_id) + ".mp4";
        std::string yuv_name = featureFrames_output_path + path_separator + std::to_string(entry.flickr_id) + ".yuv";
        std::string cmd = "ffmpeg -loglevel error -y -i " + video_name + " -pix_fmt yuv420p -vsync 0 " + yuv_name;
        system(cmd.c_str());

        std::vector<std::vector<float>> feats_frames = calc_RAPIQUE_features(yuv_name, entry.width, entry.height,
            std::round(entry.framerate), 512.0f, "resnet50", "avg_pool", 0);
        std::vector<float> flat_feats_frames = flatten(feats_frames);
        int numElements = flat_feats_frames.size();
        float* d_featsFrames;
        float* d_featsFramesMat;
        cudaError_t allocStatus = cudaMalloc(&d_featsFrames, numElements * sizeof(float));
        if (allocStatus != cudaSuccess) {
            std::cerr << "CUDA error: Failed to allocate d_featsFrames: " << cudaGetErrorString(allocStatus) << std::endl;
            continue;
        }
        cudaMemcpy(d_featsFrames, flat_feats_frames.data(), numElements * sizeof(float), cudaMemcpyHostToDevice);
        allocStatus = cudaMalloc(&d_featsFramesMat, numElements * sizeof(float));
        if (allocStatus != cudaSuccess) {
            std::cerr << "CUDA error: Failed to allocate d_featsFramesMat: " << cudaGetErrorString(allocStatus) << std::endl;
            cudaFree(d_featsFrames);
            continue;
        }

        dim3 blockSize(256);
        dim3 gridSize((numElements + blockSize.x - 1) / blockSize.x);
        copyFeatsToMat << <gridSize, blockSize >> > (d_featsFrames, d_featsFramesMat, feats_frames.size(), feats_frames[0].size());
        cudaDeviceSynchronize();

        float* d_meanMat;
        cudaMalloc(&d_meanMat, feats_frames[0].size() * sizeof(float));
        averageColumns << <gridSize, blockSize >> > (d_featsFramesMat, d_meanMat, feats_frames.size(), feats_frames[0].size());
        cudaDeviceSynchronize();

        std::vector<float> meanMat(feats_frames[0].size());
        cudaMemcpy(meanMat.data(), d_meanMat, feats_frames[0].size() * sizeof(float), cudaMemcpyDeviceToHost);
        feats_mat[index] = meanMat;

        cudaFree(d_featsFrames);
        cudaFree(d_featsFramesMat);
        cudaFree(d_meanMat);
        std::remove(yuv_name.c_str());

            writeXML(featureFrames_output_path + path_separator + "RAPIQUE_feats.xml", feats_mat);
            std::cout << "XML file saved." << std::endl;
        
        float time = timer.elapsed();
        std::cout << "The code was executed in: " << time << " seconds." << std::endl;
    }

    logger.stopTimer("RAPIQUE-Main", "demo_compute_RAPIQUE_feats");
    logger.writeXML();
    return 0;
}
