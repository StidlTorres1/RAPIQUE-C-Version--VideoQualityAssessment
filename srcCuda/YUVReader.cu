#include "YUVReader.h"
#include <fstream>
#include <iostream>
#include <vector>
#include <cuda_runtime.h>  // CUDA Runtime
#include <opencv2/opencv.hpp>  // OpenCV for image processing

// CUDA kernel for resizing images
__global__ void resize_kernel(unsigned char* src, unsigned char* dst, int srcWidth, int srcHeight, int dstWidth, int dstHeight) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < dstWidth && y < dstHeight) {
        float scaleX = (float)srcWidth / dstWidth;
        float scaleY = (float)srcHeight / dstHeight;
        int srcX = (int)(x * scaleX);
        int srcY = (int)(y * scaleY);

        dst[y * dstWidth + x] = src[srcY * srcWidth + srcX];
    }
}

cv::Mat YUVReader::readImage(const std::string& filename, int width, int height, int frameNum) {
    cv::Mat YUV;

    // Declare pointers at the beginning of the function to ensure visibility
    unsigned char* d_Y = nullptr, * d_U = nullptr, * d_V = nullptr;
    unsigned char* d_resizedU = nullptr, * d_resizedV = nullptr;

    try {
        const int frameSize = width * height;
        const int uvFrameSize = frameSize / 4;
        const cv::Size frameDimensions(width, height);

        std::ifstream yuvFile(filename, std::ios::binary);
        if (!yuvFile) {
            std::cerr << "Cannot open file!\n";
            return {};
        }

        yuvFile.seekg(static_cast<long long>(frameSize) * 1.5 * frameNum);

        std::vector<uchar> buffer(frameSize + 2 * uvFrameSize);
        yuvFile.read(reinterpret_cast<char*>(buffer.data()), buffer.size());
        if (yuvFile.gcount() != static_cast<std::streamsize>(buffer.size())) {
            std::cerr << "Error reading the YUV components\n";
            return {};
        }

        cudaMalloc(&d_Y, frameSize);
        cudaMalloc(&d_U, uvFrameSize);
        cudaMalloc(&d_V, uvFrameSize);
        cudaMalloc(&d_resizedU, frameSize);
        cudaMalloc(&d_resizedV, frameSize);

        cudaMemcpy(d_Y, buffer.data(), frameSize, cudaMemcpyHostToDevice);
        cudaMemcpy(d_U, buffer.data() + frameSize, uvFrameSize, cudaMemcpyHostToDevice);
        cudaMemcpy(d_V, buffer.data() + frameSize + uvFrameSize, uvFrameSize, cudaMemcpyHostToDevice);

        dim3 block(16, 16);
        dim3 grid((width + block.x - 1) / block.x, (height + block.y - 1) / block.y);

        resize_kernel << <grid, block >> > (d_U, d_resizedU, width / 2, height / 2, width, height);
        resize_kernel << <grid, block >> > (d_V, d_resizedV, width / 2, height / 2, width, height);
        cudaDeviceSynchronize();

        std::vector<cv::Mat> channels(3);
        channels[0] = cv::Mat(frameDimensions, CV_8UC1, buffer.data());  // Y
        channels[1] = cv::Mat(frameDimensions, CV_8UC1);
        channels[2] = cv::Mat(frameDimensions, CV_8UC1);

        cudaMemcpy(channels[1].data, d_resizedU, frameSize, cudaMemcpyDeviceToHost);
        cudaMemcpy(channels[2].data, d_resizedV, frameSize, cudaMemcpyDeviceToHost);

        cv::merge(channels, YUV);

    }
    catch (const std::exception& e) {
        std::cerr << "An error occurred reading YUV: " << e.what() << '\n';
    }

    // Clean up CUDA resources in all cases
    cudaFree(d_Y);
    cudaFree(d_U);
    cudaFree(d_V);
    cudaFree(d_resizedU);
    cudaFree(d_resizedV);

    return YUV;
}
