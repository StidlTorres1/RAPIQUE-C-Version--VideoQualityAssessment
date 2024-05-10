#include <vector>
#include <cmath>
#include <opencv2/opencv.hpp>
#include <opencv2/core/ocl.hpp>
#include <future>
#include "Logger.h"
#include "Globals.h"
using namespace std;
using namespace cv;

// CUDA error check macro
#define cudaCheckError() { \
    cudaError_t e=cudaGetLastError(); \
    if(e!=cudaSuccess) { \
        printf("Cuda failure %s:%d: '%s'\n",__FILE__,__LINE__,cudaGetErrorString(e)); \
        exit(EXIT_FAILURE); \
    }}

// CUDA Kernel for calculating Gaussian derivatives
__global__ void computeGauDerKernel(double* gauDerX, double* gauDerY,
    int halfLength, double inverseSigmaSquared,
    int size) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    if (i < size && j < size) {
        double iPos = i - halfLength;
        double jPos = j - halfLength;
        double iSquared = iPos * iPos;
        double jSquared = jPos * jPos;
        double commonFactor = exp(-(iSquared + jSquared) * inverseSigmaSquared);
        gauDerX[j * size + i] = iPos * commonFactor;
        gauDerY[j * size + i] = jPos * commonFactor;
    }
}

pair<cv::Mat, cv::Mat> gauDerivative(double sigma) {
    logger.startTimer(video_name_global, "gauDerivative");
    const int halfLength = static_cast<int>(ceil(3 * sigma));
    const int size = 2 * halfLength + 1;
    const double sigmaSquared = 2 * sigma * sigma;
    const double inverseSigmaSquared = 1 / sigmaSquared;
    // Allocate host matrices
    cv::Mat gauDerX(size, size, CV_64F);
    cv::Mat gauDerY(size, size, CV_64F);  // Allocate device memory
    double* d_gauDerX;
    double* d_gauDerY;
    cudaMalloc(&d_gauDerX, size * size * sizeof(double));
    cudaMalloc(&d_gauDerY, size * size * sizeof(double));
    // Define grid and block dimensions
    dim3 blockDim(16, 16);
    dim3 gridDim((size + blockDim.x - 1) / blockDim.x,
        (size + blockDim.y - 1) / blockDim.y);
    // Launch kernel
    computeGauDerKernel << <gridDim, blockDim >> > (d_gauDerX, d_gauDerY, halfLength,
        inverseSigmaSquared, size);
    cudaCheckError(); // Check for kernel launch errors
    // Copy result back to host
    cudaMemcpy(gauDerX.data, d_gauDerX, size * size * sizeof(double),
        cudaMemcpyDeviceToHost);
    cudaMemcpy(gauDerY.data, d_gauDerY, size * size * sizeof(double),
        cudaMemcpyDeviceToHost);
    cudaCheckError(); // Check for copy errors
    // Free device memory
    cudaFree(d_gauDerX);
    cudaFree(d_gauDerY);

    logger.stopTimer(video_name_global, "gauDerivative");
    return { gauDerX, gauDerY };
}
