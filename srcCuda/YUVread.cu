#include <iostream>
#include <fstream>
#include <opencv2/opencv.hpp>

cv::Mat YUVread(const std::string& filename, int width, int height, int frameNum) {
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

    cv::Mat Y(frameDimensions, CV_8UC1, buffer.data());
    cv::Mat U(height / 2, width / 2, CV_8UC1, buffer.data() + frameSize);
    cv::Mat V(height / 2, width / 2, CV_8UC1, buffer.data() + frameSize + uvFrameSize);

    cv::resize(U, U, frameDimensions, 0, 0, cv::INTER_CUBIC);
    cv::resize(V, V, frameDimensions, 0, 0, cv::INTER_CUBIC);

    cv::Mat YUV;
    cv::merge(std::vector<cv::Mat>{Y, U, V}, YUV);

    return YUV;
}



//Documentation
// 1.	#include <iostream>: This line includes the iostream library, which is used for input and output in C++.
// 2.	#include <fstream>: This line includes the fstream library, enabling the program to read from and write to files.
// 3.	#include <opencv2/opencv.hpp>: This includes the OpenCV library, a popular computer vision library used for image processing.
// 4.	cv::Mat YUVread(const std::string &filename, int width, int height, int frameNum) {: This line defines a function YUVread that returns a cv::Mat (an OpenCV matrix object). The function takes a filename (as a string), the width and height of the image, and the frame number as arguments.
// 5.	const int frameSize = width * height;: This calculates the size of a single frame by multiplying its width and height.
// 6.	const int uvFrameSize = frameSize / 4;: This calculates the size of the UV components (chrominance components) of the frame. In YUV format, the U and V components typically have a quarter of the resolution of the Y (luminance) component.
// 7.	const cv::Size frameDimensions(width, height);: This creates a cv::Size object to represent the dimensions of the frame.
// 8.	std::ifstream yuvFile(filename, std::ios::binary);: Opens the file specified by filename in binary mode for reading.
// 9.	if (!yuvFile) { std::cerr << "Cannot open file!\n"; return {}; }: Checks if the file is open. If not, it outputs an error message and returns an empty cv::Mat object.
// 10.	yuvFile.seekg(static_cast<long long>(frameSize) * 1.5 * frameNum);: This line moves the file pointer to the start of the requested frame. The frame size is multiplied by 1.5 (since YUV format typically has 1.5 bytes per pixel) and then by the frame number to get to the correct position.
// 11.	std::vector<uchar> buffer(frameSize + 2 * uvFrameSize);: Declares a buffer of type std::vector<uchar> with a size sufficient to hold a YUV frame.
// 12.	yuvFile.read(reinterpret_cast<char*>(buffer.data()), buffer.size());: Reads the frame data into the buffer.
// 13.	if (yuvFile.gcount() != static_cast<std::streamsize>(buffer.size())) { std::cerr << "Error reading the YUV components\n"; return {}; }: Checks if the read operation was successful. If not, outputs an error message and returns an empty cv::Mat object.
// 14.	cv::Mat Y(frameDimensions, CV_8UC1, buffer.data());: Creates a cv::Mat object for the Y component using the buffer data.
// 15.	cv::Mat U(height / 2, width / 2, CV_8UC1, buffer.data() + frameSize);: Creates a cv::Mat object for the U component.
// 16.	cv::Mat V(height / 2, width / 2, CV_8UC1, buffer.data() + frameSize + uvFrameSize);: Similarly, creates a cv::Mat for the V component.
// 17.	cv::resize(U, U, frameDimensions, 0, 0, cv::INTER_CUBIC);: Resizes the U component to match the frame dimensions using cubic interpolation.
// 18.	cv::resize(V, V, frameDimensions, 0, 0, cv::INTER_CUBIC);: Does the same for the V component.
// 19.	cv::Mat YUV;: Declares a cv::Mat object to hold the merged YUV data.
// 20.	cv::merge(std::vector<cv::Mat>{Y, U, V}, YUV);: Merges the Y, U, and V components into a single cv::Mat.
// 21.	return YUV;: Returns the merged YUV image.
// This function is designed to read a specific frame from a YUV video file and return it as a color image using the OpenCV library
